class_name Pocket
extends Area2D
##
## 底部检测区脚本：普通区与奖励袋洞共用。
##
## is_pocket = true  → 奖励袋洞：球进入 → 立即销毁 + 发出 ball_entered_pocket（RoundManager 加库存）
## is_pocket = false → 普通底部区：球进入 → 仅立即销毁（不扣球、不加球）
##
## Area2D 不参与物理反弹，只做检测；球在进入瞬间被 queue_free()。
## 视觉：_ready() 时为每个矩形 CollisionShape2D 生成半透明 Polygon2D 白盒标记，
## 颜色由 zone_color 控制（袋洞绿色、普通区灰色）。
##

## 球进入奖励袋洞时发出（普通区不发）。
signal ball_entered_pocket

## 是否为奖励袋洞（false = 普通底部区）。
@export var is_pocket: bool = false
## 白盒视觉颜色。
@export var zone_color: Color = Color(0.8, 0.8, 0.8, 0.15)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_build_visuals()


## 球进入检测区：销毁球；袋洞额外发信号。
func _on_body_entered(body: Node) -> void:
	if body is not RigidBody2D:
		return
	var ball := body as RigidBody2D
	# 冻结的球（如 BallTemplate 模板）不处理
	if ball.freeze:
		return
	ball.queue_free()
	if is_pocket:
		ball_entered_pocket.emit()


## 为每个矩形碰撞形状生成一个半透明矩形视觉（白盒标记）。
func _build_visuals() -> void:
	for child in get_children():
		if child is CollisionShape2D and (child as CollisionShape2D).shape is RectangleShape2D:
			var shape: RectangleShape2D = (child as CollisionShape2D).shape
			var half: Vector2 = shape.size * 0.5
			var poly := Polygon2D.new()
			poly.name = "Visual"
			poly.polygon = PackedVector2Array([
				Vector2(-half.x, -half.y),
				Vector2(half.x, -half.y),
				Vector2(half.x, half.y),
				Vector2(-half.x, half.y),
			])
			poly.color = zone_color
			# 挂在 CollisionShape2D 下，自动跟随其偏移
			child.add_child(poly)
