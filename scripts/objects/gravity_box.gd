extends CharacterBody2D

@export_category("Gravity")
@export var gravity_force: float = 900.0
@export var max_fall_speed: float = 600.0
@export var starts_floating: bool = false

@export_category("Push")
@export var push_speed: float = 90.0
@export var push_acceleration: float = 900.0
@export var friction: float = 1200.0

@onready var visuals: Node2D = $Visuals

var gravity_dir: Vector2 = Vector2.DOWN
var gravity_enabled: bool = true
var push_input: float = 0.0


func _ready() -> void:
	gravity_enabled = not starts_floating
	
	if starts_floating:
		velocity = Vector2.ZERO


func _physics_process(delta: float) -> void:
	up_direction = -gravity_dir

	if gravity_enabled:
		handle_push(delta)
		handle_gravity(delta)
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	push_input = 0.0


func handle_push(delta: float) -> void:
	if push_input != 0.0:
		velocity.x = move_toward(
			velocity.x,
			push_input * push_speed,
			push_acceleration * delta
		)
	else:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			friction * delta
		)


func handle_gravity(delta: float) -> void:
	velocity += gravity_dir * gravity_force * delta
	velocity = limit_velocity_by_gravity(velocity)


func limit_velocity_by_gravity(current_velocity: Vector2) -> Vector2:
	var vertical_speed: float = current_velocity.dot(gravity_dir)

	if vertical_speed > max_fall_speed:
		current_velocity -= gravity_dir * (vertical_speed - max_fall_speed)

	return current_velocity


func push_from_player(direction: float) -> void:
	if not gravity_enabled:
		return

	if direction == 0.0:
		return

	push_input = sign(direction)


func apply_gravity_spell() -> void:
	if not gravity_enabled:
		activate_gravity()
		return

	invert_gravity()


func activate_gravity() -> void:
	gravity_enabled = true
	gravity_dir = Vector2.DOWN
	velocity = Vector2.ZERO
	up_direction = -gravity_dir


func invert_gravity() -> void:
	gravity_dir *= -1.0
	velocity.y = 0.0
	up_direction = -gravity_dir


func is_box_button_weight() -> bool:
	return true
