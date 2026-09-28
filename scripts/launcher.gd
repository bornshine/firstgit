extends Node2D
##
## Launcher：右下角发射器（蓄力 + 鼠标瞄准模型）。
##
## 交互：
## - 按下鼠标左键 → 若 can_fire() 则开始蓄力计时（不发射）
## - 按住 → 力度随时间线性增长：impulse = lerp(min, max, t / charge_time)，3s 封顶
##   （蓄力期间瞄准方向实时跟随鼠标，以松开瞬间为准）
## - 松开 → 发射 1 颗球
##
## 瞄准规则（2026-09-27）：
## - 发射方向 = 发射器 → 鼠标位置
## - 射角限制：以正上方为中心 ±aim_angle_limit_deg（默认 80°），
##   鼠标超出范围时方向钳制到边界（防止朝地面/墙壁浪费球）
## - 快速点击（按住 < jitter_free_threshold，0.2s）→ 沿瞄准方向 ±angle_jitter_deg 随机抖动
## - 蓄力（按住 ≥ 阈值）→ 完全精准朝鼠标方向，无抖动
##
## 球的视觉/碰撞形状来自 BallTemplate（duplicate）；spawn/冲量物理逻辑不变。
## 数值运行时以 data/balance_config.json 为准（RoundManager 启动注入，不变量 #2）。
##

# -------------------- 信号 --------------------

## 每次成功发射一颗球时发出（连接到 RoundManager._on_ball_launched）。
signal ball_launched

## 蓄力进度变化（ratio ∈ [0,1]，0 表示蓄力结束/取消，HUD 隐藏蓄力条）。
signal charge_updated(ratio: float)

# -------------------- @export 参数 --------------------

## 蓄满所需时间（秒）。
@export var charge_time: float = 3.0
## 最小发射冲量（快速点击）。
@export var min_impulse: float = 600.0
## 最大发射冲量（蓄满）。
@export var max_impulse: float = 1600.0
## 快速点击时的随机角度抖动（度，相对瞄准方向）。
@export var angle_jitter_deg: float = 5.0
## 按住超过该时长（秒）后，发射方向无抖动（精准模式）。
@export var jitter_free_threshold: float = 0.2
## 射角限制（度）：以正上方为中心的最大偏角。
@export var aim_angle_limit_deg: float = 80.0
## 球模板的 NodePath（在 Inspector 里把 BallTemplate 拖到这里）。
@export var ball_template: NodePath
## 回合管理器 NodePath（用于发射门禁；场景中已预填）。
@export var round_manager_path: NodePath


# -------------------- 私有状态 --------------------

var _charging: bool = false
var _charge_t: float = 0.0


# -------------------- 生命周期 --------------------

func _physics_process(delta: float) -> void:
	if not _charging:
		return
	_charge_t = minf(_charge_t + delta, charge_time)
	charge_updated.emit(get_charge_ratio())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_begin_charge()
			else:
				_release_fire()


# -------------------- 对外查询 --------------------

## 当前蓄力比例（0~1）。
func get_charge_ratio() -> float:
	if charge_time <= 0.0:
		return 1.0
	return clampf(_charge_t / charge_time, 0.0, 1.0)


## 是否正在蓄力。
func is_charging() -> bool:
	return _charging


## 当前瞄准方向（发射器 → 鼠标，钳制在正上方 ±aim_angle_limit_deg 内）。
func get_aim_direction() -> Vector2:
	var to_mouse: Vector2 = get_global_mouse_position() - global_position
	# 鼠标正好压在发射器上：默认朝上
	if to_mouse.length_squared() < 1.0:
		return Vector2.UP
	# 相对正上方的偏角，wrap 到 (-PI, PI]
	var offset: float = wrapf(to_mouse.angle() - Vector2.UP.angle(), -PI, PI)
	var limit: float = deg_to_rad(aim_angle_limit_deg)
	offset = clampf(offset, -limit, limit)
	return Vector2.UP.rotated(offset)


# -------------------- 私有方法 --------------------

## 按下左键：门禁通过则开始蓄力。
func _begin_charge() -> void:
	var manager := get_node_or_null(round_manager_path) as RoundManager
	if manager != null and not manager.can_fire():
		return
	_charging = true
	_charge_t = 0.0
	charge_updated.emit(0.0)


## 松开左键：发射（门禁复查，防止按住期间回合状态变化）。
func _release_fire() -> void:
	if not _charging:
		return
	_charging = false
	var ratio: float = get_charge_ratio()
	var hold_time: float = _charge_t
	_charge_t = 0.0
	charge_updated.emit(0.0)  # 通知 HUD 隐藏蓄力条

	# 松开瞬间再查一次门禁（按住期间可能已结算 / 库存被锁）
	var manager := get_node_or_null(round_manager_path) as RoundManager
	if manager != null and not manager.can_fire():
		return

	_spawn_ball(ratio, hold_time)


## 复制 BallTemplate，初始化并施加冲量（物理逻辑不变，方向改为鼠标瞄准）。
func _spawn_ball(ratio: float, hold_time: float) -> void:
	if ball_template.is_empty():
		push_warning("Launcher: ball_template 未设置，请在 Inspector 里拖入 BallTemplate")
		return
	var tmpl: Node = get_node_or_null(ball_template)
	if tmpl == null or tmpl is not RigidBody2D:
		push_warning("Launcher: ball_template 节点不存在或不是 RigidBody2D")
		return

	var impulse: float = lerpf(min_impulse, max_impulse, ratio)

	var ball: RigidBody2D = (tmpl as RigidBody2D).duplicate() as RigidBody2D
	# 模板是 hidden + freeze，spawn 时开启
	ball.visible = true
	ball.freeze = false
	# 标签组（底部检测区销毁球 + RoundManager 判定"场上是否有球"都用这个组）
	ball.add_to_group(&"balls")
	# 挂到发射器的父节点（通常是 Main）下，避免跟随发射器变换
	get_parent().add_child(ball)
	# 入树后再设全局坐标（保证 global_position 生效）
	ball.global_position = global_position

	# 发射方向：瞄准方向（发射器 → 鼠标，已钳制射角）
	# 快速点击带 ±angle_jitter_deg 抖动；按住超过阈值则精准（无抖动）
	var dir: Vector2 = get_aim_direction()
	if hold_time < jitter_free_threshold and angle_jitter_deg > 0.0:
		dir = dir.rotated(deg_to_rad(randf_range(-angle_jitter_deg, angle_jitter_deg)))
	ball.apply_central_impulse(dir * impulse)

	# 通知回合管理器扣库存
	ball_launched.emit()
