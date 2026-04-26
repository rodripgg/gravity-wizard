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
@export var spell_range: float = 600.0
@export var spell_cooldown: float = 0.25
@export var spell_projectile_scene: PackedScene
@export var spell_cast_animation_time: float = 0.28
@export var aim_flip_threshold: float = 0.15
@export var spell_release_delay: float = 0.15

@export_category("Death")
@export var death_restart_delay: float = 0.9

var can_cast_spell: bool = true
var is_casting_spell: bool = false

var is_dead: bool = false

var gravity_dir: Vector2 = Vector2.DOWN
var facing_dir: int = 1
var aim_dir: Vector2 = Vector2.RIGHT


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return
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
	update_facing_from_aim()

	if gamepad_vector.length() > gamepad_aim_deadzone:
		aim_dir = gamepad_vector.normalized()
	else:
		aim_dir = (get_global_mouse_position() - spell_origin.global_position).normalized()

	if aim_dir.length() <= 0.01:
		aim_dir = Vector2.RIGHT * facing_dir

	spell_pivot.rotation = aim_dir.angle()


func update_animation() -> void:
	if is_dead:
		return
	if is_casting_spell:
		return
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

	if spell_projectile_scene == null:
		push_warning("No se asignó spell_projectile_scene en el Player.")
		return

	can_cast_spell = false
	play_cast_animation()
	await get_tree().create_timer(spell_release_delay).timeout
	var from: Vector2 = spell_origin.global_position
	var to: Vector2 = from + aim_dir * spell_range

	var hit_position: Vector2 = to
	var hit_object: Object = null

	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state

	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = [self]
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var result: Dictionary = space_state.intersect_ray(query)

	if not result.is_empty():
		hit_position = result["position"]
		hit_object = result["collider"] as Object

	spawn_gravity_spell_projectile(from, hit_position, hit_object)

	await get_tree().create_timer(spell_cooldown).timeout
	can_cast_spell = true

func spawn_gravity_spell_projectile(
	from: Vector2,
	to: Vector2,
	hit_object: Object
) -> void:
	var projectile: Node2D = spell_projectile_scene.instantiate() as Node2D

	get_tree().current_scene.add_child(projectile)

	if projectile.has_method("setup"):
		projectile.call("setup", from, to, hit_object)

func play_cast_animation() -> void:
	if animated_sprite.sprite_frames == null:
		return

	if not animated_sprite.sprite_frames.has_animation("cast"):
		return

	is_casting_spell = true
	animated_sprite.play("cast")

	await get_tree().create_timer(spell_cast_animation_time).timeout

	is_casting_spell = false

func update_facing_from_aim() -> void:
	if aim_dir.x > aim_flip_threshold:
		facing_dir = 1
		visuals.scale.x = 1
	elif aim_dir.x < -aim_flip_threshold:
		facing_dir = -1
		visuals.scale.x = -1

func die() -> void:
	if is_dead:
		return
	is_dead = true
	can_cast_spell = false
	velocity = Vector2.ZERO
	play_death_animation()
	await get_tree().create_timer(death_restart_delay).timeout
	get_tree().reload_current_scene()

func play_death_animation() -> void:
	if animated_sprite.sprite_frames == null:
		return
	if animated_sprite.sprite_frames.has_animation("death"):
		animated_sprite.play("death")
