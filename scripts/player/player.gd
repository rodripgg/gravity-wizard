extends CharacterBody2D

@export_category("Movement")
@export var move_speed: float = 170.0
@export var acceleration: float = 1400.0
@export var friction: float = 1800.0
@export var jump_velocity: float = 360.0
@export var gravity_force: float = 950.0

@export_category("Aiming")
@export var gamepad_aim_deadzone: float = 0.25

@onready var visuals: Node2D = $Visuals
@onready var animated_sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var spell_pivot: Node2D = $SpellPivot
@onready var spell_origin: Marker2D = $SpellPivot/SpellOrigin
@onready var aim_line: Line2D = $SpellPivot/AimLine

@export_category("Spell")
@export var spell_range: float = 280.0
@export var spell_cooldown: float = 0.25
var can_cast_spell: bool = true

var gravity_dir: Vector2 = Vector2.DOWN
var facing_dir: int = 1
var aim_dir: Vector2 = Vector2.RIGHT


func _physics_process(delta: float) -> void:
	handle_movement(delta)
	handle_aiming()
	update_animation()
	move_and_slide()
	handle_spell()


func handle_movement(delta: float) -> void:
	var input_dir := Input.get_axis("move_left", "move_right")

	if input_dir != 0.0:
		velocity.x = move_toward(
			velocity.x,
			input_dir * move_speed,
			acceleration * delta
		)

		facing_dir = sign(input_dir)
		visuals.scale.x = facing_dir
	else:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			friction * delta
		)

	velocity += gravity_dir * gravity_force * delta

	up_direction = -gravity_dir

	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity = -gravity_dir * jump_velocity * 1.2 + Vector2(velocity.x, 0.0)

func handle_aiming() -> void:
	var gamepad_vector := Input.get_vector(
		"aim_left",
		"aim_right",
		"aim_up",
		"aim_down"
	)

	if gamepad_vector.length() > gamepad_aim_deadzone:
		aim_dir = gamepad_vector.normalized()
	else:
		aim_dir = (get_global_mouse_position() - spell_origin.global_position).normalized()

	if aim_dir.length() <= 0.01:
		aim_dir = Vector2.RIGHT * facing_dir

	spell_pivot.rotation = aim_dir.angle()


func update_animation() -> void:
	if not animated_sprite.sprite_frames:
		return

	if not is_on_floor():
		if velocity.dot(gravity_dir) > 0.0:
			play_animation("fall")
		else:
			play_animation("jump")
		return

	if abs(velocity.x) > 10.0:
		play_animation("move")
	else:
		play_animation("idle")


func play_animation(animation_name: String) -> void:
	if animated_sprite.animation == animation_name:
		return

	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)


func invert_gravity() -> void:
	gravity_dir *= -1.0
	visuals.scale.y *= -1.0
	up_direction = -gravity_dir


func apply_gravity_spell() -> void:
	invert_gravity()


func get_spell_origin_position() -> Vector2:
	return spell_origin.global_position


func get_aim_direction() -> Vector2:
	return aim_dir

func handle_spell() -> void:
	if Input.is_action_just_pressed("shoot"):
		cast_gravity_spell()

func cast_gravity_spell() -> void:
	if not can_cast_spell:
		return

	can_cast_spell = false

	var from: Vector2 = spell_origin.global_position
	var to: Vector2 = from + aim_dir * spell_range

	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state

	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = [self]
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var result: Dictionary = space_state.intersect_ray(query)

	if not result.is_empty():
		var hit_position: Vector2 = result["position"]
		var collider: Object = result["collider"] as Object

		draw_spell_debug(from, hit_position)

		if collider != null and collider.has_method("apply_gravity_spell"):
			collider.call("apply_gravity_spell")
	else:
		draw_spell_debug(from, to)

	await get_tree().create_timer(spell_cooldown).timeout
	can_cast_spell = true

func draw_spell_debug(from: Vector2, to: Vector2) -> void:
	var local_from := spell_pivot.to_local(from)
	var local_to := spell_pivot.to_local(to)

	aim_line.clear_points()
	aim_line.add_point(local_from)
	aim_line.add_point(local_to)
	aim_line.visible = true

	await get_tree().create_timer(0.08).timeout
	aim_line.visible = false
