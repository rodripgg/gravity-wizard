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

@export_category("Aim")
@export var gamepad_reticle_distance: float = 120.0
@export var hide_system_cursor: bool = true
@onready var aim_reticle: Sprite2D = $AimReticle
var is_using_gamepad_aim: bool = false

@export_category("Spell")
@export var spell_range: float = 600.0
@export var spell_cooldown: float = 0.25
@export var spell_projectile_scene: PackedScene
@export var spell_cast_animation_time: float = 0.28
@export var aim_flip_threshold: float = 0.15
@export var spell_release_delay: float = 0.15
@export var spell_cast_particles_scene: PackedScene

@export_category("Gravity Flip")
@export var gravity_flip_safe_offset: float = 2.0
@export var gravity_flip_rotation_time: float = 0.10
var gravity_flip_tween: Tween

@export_category("Death")
@export var death_restart_delay: float = 3.0
@export var death_bounce_horizontal_force: float = 160.0
@export var death_bounce_vertical_force: float = 320.0
@export var death_gravity_force: float = 900.0
@export var death_flash_time: float = 0.07

@export_category("Mana")
@export var max_mana: float = 100.0
@export var current_mana: float = 100.0
@export var spell_mana_cost: float = 15.0
@export var self_gravity_mana_cost: float = 25.0
@export var mana_regen_per_second: float = 0.0
@onready var mana_bar: ProgressBar = $HUD/ManaPanel/ManaBar

var can_cast_spell: bool = true
var is_casting_spell: bool = false

var is_dead: bool = false

var gravity_dir: Vector2 = Vector2.DOWN
var facing_dir: int = 1
var aim_dir: Vector2 = Vector2.RIGHT

var move_input_dir: float = 0.0

func _ready() -> void:
	aim_reticle.top_level = true
	if hide_system_cursor:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	current_mana = clamp(current_mana, 0.0, max_mana)
	update_mana_bar()
	mana_bar.visible = true
	update_visual_orientation(false)

func _physics_process(delta: float) -> void:
	if is_dead:
		handle_death_physics(delta)
		return
	handle_mana_regeneration(delta)
	handle_aiming()
	handle_spell()
	handle_movement(delta)
	update_animation()
	move_and_slide()
	handle_push_collisions()


func handle_movement(delta: float) -> void:
	move_input_dir = Input.get_axis("move_left", "move_right")
	var input_dir: float = move_input_dir
	if input_dir != 0.0:
		velocity.x = move_toward(
			velocity.x,
			input_dir * move_speed,
			acceleration * delta
		)
		facing_dir = int(sign(input_dir))
		update_visual_orientation()
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
	var gamepad_vector: Vector2 = Input.get_vector(
		"aim_left",
		"aim_right",
		"aim_up",
		"aim_down"
	)

	is_using_gamepad_aim = gamepad_vector.length() > gamepad_aim_deadzone
	if is_using_gamepad_aim:
		aim_dir = gamepad_vector.normalized()
	else:
		aim_dir = (get_global_mouse_position() - spell_origin.global_position).normalized()
	if aim_dir.length() <= 0.01:
		aim_dir = Vector2.RIGHT * facing_dir
	spell_pivot.rotation = aim_dir.angle()
	update_facing_from_aim()
	update_aim_reticle()

func update_aim_reticle() -> void:
	if aim_reticle == null:
		return
	if is_using_gamepad_aim:
		aim_reticle.global_position = spell_origin.global_position + aim_dir * gamepad_reticle_distance
	else:
		aim_reticle.global_position = get_global_mouse_position()
	aim_reticle.rotation = aim_dir.angle()

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
	up_direction = -gravity_dir
	# Elimina velocidad vertical anterior para evitar saltos raros al invertir.
	velocity = velocity.slide(gravity_dir)
	# Pequeño desplazamiento para no quedar pegado a la superficie anterior.
	global_position += gravity_dir * gravity_flip_safe_offset
	update_visual_orientation(true)


func apply_gravity_spell() -> void:
	invert_gravity()


func get_spell_origin_position() -> Vector2:
	return spell_origin.global_position


func get_aim_direction() -> Vector2:
	return aim_dir

func handle_spell() -> void:
	if Input.is_action_just_pressed("shoot"):
		cast_gravity_spell()
	if Input.is_action_just_pressed("flip_self_gravity"):
		cast_self_gravity_spell()

func cast_gravity_spell() -> void:
	if not can_cast_spell:
		return

	if spell_projectile_scene == null:
		push_warning("No se asignó spell_projectile_scene en el Player.")
		return

	if not consume_mana(spell_mana_cost):
		return

	can_cast_spell = false
	play_cast_animation()

	await get_tree().create_timer(spell_release_delay).timeout

	if is_dead:
		return

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

	spawn_spell_cast_particles(from, aim_dir)
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
		update_visual_orientation()
	elif aim_dir.x < -aim_flip_threshold:
		facing_dir = -1
		update_visual_orientation()

func die(source_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	is_dead = true
	can_cast_spell = false
	is_casting_spell = false
	var away_sign: float = sign(global_position.x - source_position.x)
	if away_sign == 0.0:
		away_sign = -float(facing_dir)
	velocity = Vector2(
		away_sign * death_bounce_horizontal_force,
		0.0
	)
	velocity += -gravity_dir * death_bounce_vertical_force
	play_death_animation()
	flash_damage_white()
	await get_tree().create_timer(death_restart_delay).timeout
	get_tree().reload_current_scene()

func play_death_animation() -> void:
	if animated_sprite.sprite_frames == null:
		return
	if animated_sprite.sprite_frames.has_animation("death"):
		animated_sprite.play("death")

func handle_death_physics(delta: float) -> void:
	up_direction = -gravity_dir
	velocity += gravity_dir * death_gravity_force * delta
	move_and_slide()

func flash_damage_white() -> void:
	if animated_sprite == null:
		return
	var original_modulate: Color = animated_sprite.modulate
	animated_sprite.modulate = Color(4.0, 4.0, 4.0, 1.0)
	await get_tree().create_timer(death_flash_time).timeout
	if is_instance_valid(animated_sprite):
		animated_sprite.modulate = original_modulate

func handle_push_collisions() -> void:
	if abs(move_input_dir) < 0.1:
		return
	for i in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider() as Object
		if collider == null:
			continue
		if not collider.has_method("push_from_player"):
			continue
		var normal: Vector2 = collision.get_normal()
		if abs(normal.x) < 0.5:
			continue
		collider.call("push_from_player", move_input_dir)

func can_press_pressure_button() -> bool:
	return true

func spawn_spell_cast_particles(position: Vector2, direction: Vector2) -> void:
	if spell_cast_particles_scene == null:
		return
	var particles_instance: Node2D = spell_cast_particles_scene.instantiate() as Node2D
	get_tree().current_scene.add_child(particles_instance)
	if particles_instance.has_method("play_at"):
		particles_instance.call("play_at", position, direction)
	else:
		particles_instance.global_position = position
		particles_instance.rotation = direction.angle()

# mana
func handle_mana_regeneration(delta: float) -> void:
	if mana_regen_per_second <= 0.0:
		return
	if current_mana >= max_mana:
		return
	set_mana(current_mana + mana_regen_per_second * delta)


func has_mana(cost: float) -> bool:
	return current_mana >= cost


func consume_mana(cost: float) -> bool:
	if not has_mana(cost):
		return false

	set_mana(current_mana - cost)
	return true


func set_mana(value: float) -> void:
	current_mana = clamp(value, 0.0, max_mana)
	update_mana_bar()


func update_mana_bar() -> void:
	if mana_bar == null:
		return
	mana_bar.max_value = max_mana
	mana_bar.value = current_mana

func cast_self_gravity_spell() -> void:
	if is_dead:
		return
	if not consume_mana(self_gravity_mana_cost):
		return
	invert_gravity()
	spawn_spell_cast_particles(global_position, -gravity_dir)

func update_visual_orientation(animated: bool = false) -> void:
	var is_gravity_up: bool = gravity_dir == Vector2.UP

	var target_rotation: float = PI if is_gravity_up else 0.0

	# Al rotar 180°, se invierte también el eje X visual.
	# Esto compensa la dirección para que el mago siga mirando correctamente.
	var target_scale_x: float = float(facing_dir)

	if is_gravity_up:
		target_scale_x *= -1.0

	visuals.scale.y = 1.0
	visuals.scale.x = target_scale_x

	if gravity_flip_tween != null:
		gravity_flip_tween.kill()

	if animated and gravity_flip_rotation_time > 0.0:
		gravity_flip_tween = create_tween()
		gravity_flip_tween.tween_property(
			visuals,
			"rotation",
			target_rotation,
			gravity_flip_rotation_time
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		visuals.rotation = target_rotation
