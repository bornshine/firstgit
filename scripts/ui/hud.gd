class_name HUD
extends CanvasLayer
##
## HUD：常驻信息（时间 / 库存 / 目标）+ 结算按钮 + 过关闪烁 + 失败面板。
##
## 数据来源：订阅 RoundManager 的 time_changed / stock_changed / state_changed
## （信号连接定义在 Main.tscn）；初始数值在 _ready() 里主动拉取一次。
##
## 按钮：结算 / 重试 → 发出 settle_requested / retry_requested，
## 由 Main.tscn 连接到 RoundManager。
##

# -------------------- 信号 --------------------

signal settle_requested
signal retry_requested

# -------------------- @export 参数 --------------------

## RoundManager 节点路径（场景中已预填）。
@export var round_manager_path: NodePath
## Launcher 节点路径（蓄力条跟随发射器位置；场景中已预填）。
@export var launcher_path: NodePath

# -------------------- 节点引用 --------------------

@onready var time_label: Label = $Root/TopBar/TimeLabel
@onready var stock_label: Label = $Root/TopBar/StockLabel
@onready var target_label: Label = $Root/TopBar/TargetLabel
@onready var pass_flash: Label = $Root/PassFlash
@onready var fail_panel: PanelContainer = $Root/FailPanel
@onready var sub_label: Label = $Root/FailPanel/VBox/SubLabel
@onready var charge_bar: Control = $Root/ChargeBar
@onready var charge_fill: ColorRect = $Root/ChargeBar/Fill

var _round_manager: RoundManager
var _launcher: Node2D


# -------------------- 生命周期 --------------------

func _ready() -> void:
	_round_manager = get_node_or_null(round_manager_path) as RoundManager
	_launcher = get_node_or_null(launcher_path) as Node2D
	charge_bar.visible = false
	if _round_manager == null:
		push_warning("HUD: round_manager_path 未设置或节点不存在")
		return
	# 初始数值主动拉取（信号只在变化时发出）
	target_label.text = "目标 %d" % _round_manager.target_stock
	_on_time_changed(_round_manager.get_time_left())
	_on_stock_changed(_round_manager.get_stock())
	_apply_state(_round_manager.get_state())


# -------------------- 信号回调（由 Main.tscn 连接） --------------------

func _on_time_changed(time_left: float) -> void:
	if _round_manager == null:
		return  # _ready 之前收到的信号直接忽略
	time_label.text = "剩余时间 %ds" % ceili(maxf(time_left, 0.0))


func _on_stock_changed(stock: int) -> void:
	if _round_manager == null:
		return
	stock_label.text = "库存 %d" % stock


func _on_state_changed(new_state: int) -> void:
	if _round_manager == null:
		return
	_apply_state(new_state)


## 蓄力进度刷新（Launcher.charge_updated → 本方法；ratio=0 表示蓄力结束/取消）。
func _on_charge_updated(ratio: float) -> void:
	if ratio <= 0.0:
		charge_bar.visible = false
		return
	# 跟随发射器位置（CanvasLayer 默认变换下，世界坐标 ≈ 屏幕坐标）
	if _launcher != null:
		charge_bar.position = _launcher.global_position + Vector2(-100, -70)
	charge_bar.visible = true
	# 填充宽度按比例（ChargeBar 总宽 200）
	var width: float = 200.0 * ratio
	charge_fill.size.x = width
	charge_fill.color = Color(0.3, 1, 0.4) if ratio >= 1.0 else Color(1, 1, 1)


# -------------------- 按钮回调（HUD.tscn 内部连接） --------------------

func _on_settle_button_pressed() -> void:
	settle_requested.emit()


func _on_retry_button_pressed() -> void:
	retry_requested.emit()


# -------------------- 私有方法 --------------------

## 根据回合状态切换 HUD 显示。
func _apply_state(new_state: int) -> void:
	match new_state:
		RoundManager.RoundState.PLAYING:
			pass_flash.visible = false
			fail_panel.visible = false
		RoundManager.RoundState.ENTERING_NEXT:
			fail_panel.visible = false
			_show_pass_flash()
		RoundManager.RoundState.SETTLING:
			pass_flash.visible = false
			sub_label.text = "库存 %d / 目标 %d" % [
				_round_manager.get_stock(),
				_round_manager.target_stock
			]
			fail_panel.visible = true


## 过关闪烁：显示 1.5 秒后自动隐藏。
func _show_pass_flash() -> void:
	pass_flash.visible = true
	await get_tree().create_timer(1.5).timeout
	pass_flash.visible = false
