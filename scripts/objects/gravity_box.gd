extends CharacterBody2D

@export var gravity_force: float = 900.0
@export var max_fall_speed: float = 600.0

@onready var visuals: Node2D = $Visuals

var gravity_dir: Vector2 = Vector2.DOWN


func _physics_process(delta: float) -> void:
	up_direction = -gravity_dir

	velocity += gravity_dir * gravity_force * delta
	velocity = limit_velocity_by_gravity(velocity)

	move_and_slide()


func limit_velocity_by_gravity(current_velocity: Vector2) -> Vector2:
	var vertical_speed := current_velocity.dot(gravity_dir)

	if vertical_speed > max_fall_speed:
		current_velocity -= gravity_dir * (vertical_speed - max_fall_speed)

	return current_velocity


func apply_gravity_spell() -> void:
	invert_gravity()


func invert_gravity() -> void:
	gravity_dir *= -1.0
	visuals.scale.y *= -1.0
	velocity = Vector2.ZERO
	up_direction = -gravity_dir
