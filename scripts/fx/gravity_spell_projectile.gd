extends Node2D

@export var speed: float = 720.0
@export var radius: float = 5.0
@export var trail_length: float = 18.0
@export var initial_visibility_delay: float = 0.03

var target_position: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.RIGHT
var target_object: Object = null
var has_arrived: bool = false

func _ready() -> void:
	visible = false
	show_after_delay()

func show_after_delay() -> void:
	await get_tree().create_timer(initial_visibility_delay).timeout
	if is_inside_tree():
		visible = true

func setup(start_position: Vector2, end_position: Vector2, hit_object: Object = null) -> void:
	global_position = start_position
	target_position = end_position
	target_object = hit_object

	direction = target_position - global_position

	if direction.length() <= 0.01:
		direction = Vector2.RIGHT
	else:
		direction = direction.normalized()

	rotation = direction.angle()


func _process(delta: float) -> void:
	if has_arrived:
		return

	var distance_to_target: float = global_position.distance_to(target_position)
	var step: float = speed * delta

	if distance_to_target <= step:
		global_position = target_position
		impact()
		return

	global_position += direction * step
	queue_redraw()


func _draw() -> void:
	draw_line(
		Vector2(-trail_length, 0.0),
		Vector2.ZERO,
		Color(0.7, 0.35, 1.0, 0.7),
		3.0
	)

	draw_circle(
		Vector2.ZERO,
		radius,
		Color(0.9, 0.75, 1.0, 1.0)
	)


func impact() -> void:
	has_arrived = true

	if target_object != null:
		if is_instance_valid(target_object) and target_object.has_method("apply_gravity_spell"):
			target_object.call("apply_gravity_spell")

	queue_free()
