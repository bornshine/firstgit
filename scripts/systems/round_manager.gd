class_name RoundManager
extends Node2D
##
## RoundManager：一局的状态机（Main 子节点，暂不做 Autoload）。
##
## 状态：
##   PLAYING       倒计时走表，可发射（库存 > 0）
##   ENTERING_NEXT 库存 ≥ 目标 → 清场 + HUD 闪"过关！" → 1.5s 后自动进入下一局
##   SETTLING      倒计时归零 / 手动点结算 / 库存 0 且场上无球 → 失败面板，等玩家点重试
##
## 规则要点：
## - 每次发射库存 -1（Launcher 发 ball_launched）
## - 球进奖励袋洞库存 +3（Pocket 发 ball_entered_pocket），同帧多球为 3×N 累加
## - 球落普通区不扣不加，仅销毁
## - 库存 ≥ 60 在 PLAYING 期间随时直接进入下一局
## - SETTLING 瞬间锁定库存：场上剩余球继续被底部区销毁，但不再计分
## - 数值全部从 data/balance_config.json 读取（不变量：数值集中在配置文件）
##

# -------------------- 信号 --------------------

signal state_changed(new_state: int)
signal stock_changed(new_stock: int)
signal time_changed(time_left: float)

enum RoundState { PLAYING, ENTERING_NEXT, SETTLING }

# -------------------- @export 参数 --------------------

## 数值配置文件路径。
@export var config_path: String = "res://data/balance_config.json"
## 发射器节点路径（_ready 时把 json 中的发射数值注入过去）。
@export var launcher_path: NodePath
## 图钉阵节点路径（_ready 时把 json 中的图钉数值注入过去）。
@export var pegboard_path: NodePath

# ---- 数值（_ready 从 balance_config.json 读取覆盖；以下为配置缺失时的兜底值） ----

var round_duration: float = 90.0
var initial_stock: int = 50
var target_stock: int = 60
var pocket_reward: int = 3

# -------------------- 私有状态 --------------------

var _state: int = RoundState.PLAYING
var _stock: int = 0
var _time_left: float = 0.0
var _launcher_cfg: Dictionary = {}
var _peg_cfg: Dictionary = {}


# -------------------- 生命周期 --------------------

func _ready() -> void:
	_load_config()
	_apply_launcher_config()
	_apply_pegboard_config()
	_stock = initial_stock
	_time_left = round_duration


func _physics_process(delta: float) -> void:
	if _state != RoundState.PLAYING:
		return
	_time_left = maxf(_time_left - delta, 0.0)
	time_changed.emit(_time_left)
	if _time_left <= 0.0:
		_settle()
		return
	# 库存为 0 且场上无球（含静止球）→ 自动结算
	if _stock <= 0 and get_tree().get_nodes_in_group(&"balls").is_empty():
		_settle()


# -------------------- 对外查询 --------------------

func get_state() -> int:
	return _state


func get_stock() -> int:
	return _stock


func get_time_left() -> float:
	return _time_left


## 发射门禁：仅 PLAYING 且库存 > 0 才允许发射。
func can_fire() -> bool:
	return _state == RoundState.PLAYING and _stock > 0


# -------------------- 信号入口（由 Main.tscn 连接） --------------------

## 每次成功发射：库存 -1。
func _on_ball_launched() -> void:
	if _state != RoundState.PLAYING:
		return
	_stock -= 1
	stock_changed.emit(_stock)


## 球进奖励袋洞：库存 +3；达到目标 → 直接进入下一局。
func _on_ball_entered_pocket() -> void:
	if _state != RoundState.PLAYING:
		return  # 结算后进袋不再计分（库存已锁定）
	_stock += pocket_reward
	stock_changed.emit(_stock)
	if _stock >= target_stock:
		_enter_next()


## 玩家点"结算"按钮。
func _on_settle_requested() -> void:
	if _state != RoundState.PLAYING:
		return
	_settle()


## 玩家点"重试"按钮。
func _on_retry_requested() -> void:
	if _state != RoundState.SETTLING:
		return
	_reset_round()


# -------------------- 状态转移 --------------------

## 结算：若此刻库存已达目标，走过关通道；否则进失败面板。
func _settle() -> void:
	if _stock >= target_stock:
		_enter_next()
	else:
		_set_state(RoundState.SETTLING)


## 进入下一局：清场 + 等 1.5s（HUD 闪"过关！"）后自动重置。
func _enter_next() -> void:
	_set_state(RoundState.ENTERING_NEXT)
	_clear_balls()
	await get_tree().create_timer(1.5).timeout
	if _state == RoundState.ENTERING_NEXT:
		_reset_round()


## 重置一局：清场、库存回到初始值、倒计时回满。
func _reset_round() -> void:
	_clear_balls()
	_stock = initial_stock
	_time_left = round_duration
	stock_changed.emit(_stock)
	time_changed.emit(_time_left)
	_set_state(RoundState.PLAYING)


func _set_state(new_state: int) -> void:
	if _state == new_state:
		return
	_state = new_state
	state_changed.emit(_state)


## 清空场上所有球（组内节点统一 queue_free）。
func _clear_balls() -> void:
	for ball in get_tree().get_nodes_in_group(&"balls"):
		ball.queue_free()


# -------------------- 配置读取 --------------------

## 从 balance_config.json 读取数值（文件缺失时使用内置兜底值并警告）。
func _load_config() -> void:
	if not FileAccess.file_exists(config_path):
		push_warning("RoundManager: 找不到配置 %s，使用内置默认值" % config_path)
		return
	var file := FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		push_warning("RoundManager: 无法打开配置 %s" % config_path)
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("RoundManager: 配置格式错误（非 JSON 对象）：%s" % config_path)
		return
	var cfg: Dictionary = data
	if cfg.has("round"):
		var round_cfg: Dictionary = cfg["round"]
		round_duration = float(round_cfg.get("duration_seconds", round_duration))
		initial_stock = int(round_cfg.get("initial_stock", initial_stock))
		target_stock = int(round_cfg.get("target_stock", target_stock))
	if cfg.has("pocket"):
		pocket_reward = int(cfg["pocket"].get("ball_reward", pocket_reward))
	if cfg.has("peg"):
		_peg_cfg = cfg["peg"]
	if cfg.has("launcher"):
		_launcher_cfg = cfg["launcher"]


## 把 json 中的发射器数值注入 Launcher（数值以配置文件为准）。
func _apply_launcher_config() -> void:
	if _launcher_cfg.is_empty():
		return
	var launcher := get_node_or_null(launcher_path)
	if launcher == null:
		push_warning("RoundManager: launcher_path 未设置，跳过发射器数值注入")
		return
	launcher.set("charge_time",
		float(_launcher_cfg.get("charge_time", launcher.get("charge_time"))))
	launcher.set("min_impulse",
		float(_launcher_cfg.get("min_impulse", launcher.get("min_impulse"))))
	launcher.set("max_impulse",
		float(_launcher_cfg.get("max_impulse", launcher.get("max_impulse"))))
	launcher.set("angle_jitter_deg",
		float(_launcher_cfg.get("angle_jitter_deg", launcher.get("angle_jitter_deg"))))
	launcher.set("jitter_free_threshold",
		float(_launcher_cfg.get("jitter_free_threshold", launcher.get("jitter_free_threshold"))))
	launcher.set("aim_angle_limit_deg",
		float(_launcher_cfg.get("aim_angle_limit_deg", launcher.get("aim_angle_limit_deg"))))


## 把 json 中的图钉数值注入 PegBoard（数值以配置文件为准）。
func _apply_pegboard_config() -> void:
	if _peg_cfg.is_empty():
		return
	var pegboard := get_node_or_null(pegboard_path)
	if pegboard == null:
		push_warning("RoundManager: pegboard_path 未设置，跳过图钉数值注入")
		return
	pegboard.set("peg_bounce",
		float(_peg_cfg.get("bounce", pegboard.get("peg_bounce"))))
