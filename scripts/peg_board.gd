extends Node2D
##
## PegBoard：上半部图钉阵。
##
## 2026-09-27 变更（图钉物理化）：
## - 图钉从 Area2D + 手动反弹 改为 StaticBody2D（真物理阻挡）。
##   球撞钉由物理引擎原生解算反弹，绝无穿钉可能；
##   图钉弹性由 PhysicsMaterial.bounce（默认 0.65）控制。
## - 原手动反弹逻辑（body_entered + 速度改写）整体移除。
## - 未来"特殊图钉"（加分/爆炸/复制球）再单独叠加 Area2D 检测，
##   不影响普通图钉的物理阻挡。
##
## 图钉在 _ready() 中按行列自动生成（6 行 × 11 列）。
## 图钉碰撞半径 = peg_radius（默认 12）
## 图钉 Sprite 视觉半径 ≈ peg_sprite_radius（默认 18）
##

# -------------------- @export 参数 --------------------

@export var top_y: float = 300.0
@export var bottom_y: float = 700.0
@export var rows: int = 6
@export var cols: int = 11
## 图钉碰撞体半径。
@export var peg_radius: float = 12.0
## 图钉弹性（PhysicsMaterial.bounce）。
@export var peg_bounce: float = 0.65
## 图钉 Sprite 视觉半径（像素，Sprite 是一张 64x64 的圆点图，缩放到该直径）。
@export var peg_sprite_radius: float = 18.0
## 图钉颜色（白色半透明）。
@export var peg_color: Color = Color(1, 1, 1, 0.85)
## 是否使用运行时生成。关闭后可手动在编辑器里添加图钉子节点。
@export var auto_generate: bool = true


const PEG_TEXTURE_SIZE: int = 64


func _ready() -> void:
	if auto_generate:
		await _generate_pegs()


## 在指定区域生成图钉阵。
func _generate_pegs() -> void:
	# 清掉已有的图钉（避免重复运行时堆积）
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame

	if rows < 1 or cols < 1:
		push_warning("PegBoard: rows / cols 必须 >= 1")
		return

	# 横向铺满 60~1860，纵向铺满 top_y ~ bottom_y
	var left_margin: float = 60.0
	var right_margin: float = 1860.0
	var row_step: float = (bottom_y - top_y) / float(rows - 1) if rows > 1 else 0.0
	var col_step: float = (right_margin - left_margin) / float(cols - 1) if cols > 1 else 0.0

	for r in range(rows):
		for c in range(cols):
			var peg: StaticBody2D = _make_peg(r, c)
			peg.position = Vector2(
				left_margin + col_step * c,
				top_y + row_step * r
			)
			add_child(peg)


## 创建单个图钉（StaticBody2D：真物理阻挡）。
func _make_peg(row: int, col: int) -> StaticBody2D:
	var peg := StaticBody2D.new()
	peg.name = "Peg_%d_%d" % [row, col]
	# 图钉物理材质：弹性可调（数值运行时由 balance_config.json 注入）
	var peg_material := PhysicsMaterial.new()
	peg_material.bounce = peg_bounce
	peg.physics_material_override = peg_material

	var shape := CircleShape2D.new()
	shape.radius = peg_radius
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.name = "CollisionShape2D"
	peg.add_child(cs)

	var sprite := Sprite2D.new()
	sprite.texture = _build_dot_texture()
	var scale_f: float = (peg_sprite_radius * 2.0) / PEG_TEXTURE_SIZE
	sprite.scale = Vector2(scale_f, scale_f)
	sprite.modulate = peg_color
	sprite.name = "Sprite2D"
	peg.add_child(sprite)

	return peg


## 生成一张白色带柔边的圆形纹理（64x64），用作图钉视觉。
func _build_dot_texture() -> ImageTexture:
	var img := Image.create(PEG_TEXTURE_SIZE, PEG_TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	var center := Vector2(PEG_TEXTURE_SIZE / 2.0, PEG_TEXTURE_SIZE / 2.0)
	var radius := PEG_TEXTURE_SIZE / 2.0
	for y in range(PEG_TEXTURE_SIZE):
		for x in range(PEG_TEXTURE_SIZE):
			var d: float = Vector2(x, y).distance_to(center)
			var alpha: float = clampf(1.0 - (d - radius + 2.0) / 2.0, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(img)
