extends SceneTree

var ball: RigidBody2D
var elapsed := 0.0
var lowest_y := -1.0e20
var highest_after_bounce := 1.0e20
var fell := false
var bounced := false
var rows: Array = []
var next_sample := 0.0


func _init() -> void:
	var packed: PackedScene = load("res://scenes/Mai.tscn")
	var scene: Node2D = packed.instantiate()
	ball = scene.get_node("Ball")
	root.add_child(scene)
	print("START_Y=", ball.global_position.y)
	print("BALL_BOUNCE=", ball.physics_material_override.bounce)
	print("BALL_FRICTION=", ball.physics_material_override.friction)
	var platform: StaticBody2D = scene.get_node("Platform")
	print("PLATFORM_FRICTION=", platform.physics_material_override.friction)
	print("PLATFORM_SIZE=", platform.get_node("CollisionShape2D").shape.size)


func _physics_process(delta: float) -> bool:
	elapsed += delta
	var y: float = ball.global_position.y
	var vy: float = ball.linear_velocity.y

	if vy > 1.0:
		fell = true
	if fell and vy < -1.0:
		bounced = true

	if y > lowest_y:
		lowest_y = y
	if bounced and y < highest_after_bounce:
		highest_after_bounce = y

	if elapsed >= next_sample:
		next_sample += 0.2
		rows.append("t=%.2f  y=%.1f  vy=%.1f" % [elapsed, y, vy])

	if elapsed >= 3.0:
		print("FELL=", fell, "  BOUNCED=", bounced)
		print("LOWEST_Y=%.1f" % lowest_y)
		print("HIGHEST_AFTER_BOUNCE=%.1f" % highest_after_bounce)
		for r in rows:
			print(r)
		quit(0)
		return true
	return false
