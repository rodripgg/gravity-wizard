extends Area2D

@export var target_bridge: NodePath
@export var pressed_offset_y: float = 3.0
@export var press_animation_time: float = 0.08

@onready var sprite: Sprite2D = $Sprite2D

var pressed_bodies: Array[Node] = []
var is_pressed: bool = false
var original_sprite_position: Vector2
var button_tween: Tween


func _ready() -> void:
	monitoring = true
	monitorable = true

	original_sprite_position = sprite.position

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	await get_tree().physics_frame
	check_initial_overlaps()


func _on_body_entered(body: Node) -> void:
	if not can_press_button(body):
		return

	if not pressed_bodies.has(body):
		pressed_bodies.append(body)

	update_button_state()


func _on_body_exited(body: Node) -> void:
	if pressed_bodies.has(body):
		pressed_bodies.erase(body)

	update_button_state()


func check_initial_overlaps() -> void:
	var bodies: Array[Node2D] = get_overlapping_bodies()

	for body in bodies:
		if can_press_button(body) and not pressed_bodies.has(body):
			pressed_bodies.append(body)

	update_button_state()


func can_press_button(body: Node) -> bool:
	if body.has_method("can_press_pressure_button"):
		return true

	if body.has_method("is_box_button_weight"):
		return true

	return false


func update_button_state() -> void:
	var new_pressed_state: bool = pressed_bodies.size() > 0

	if new_pressed_state == is_pressed:
		return

	is_pressed = new_pressed_state

	animate_button()
	notify_target_bridge()


func animate_button() -> void:
	if button_tween != null:
		button_tween.kill()

	var target_position: Vector2 = original_sprite_position

	if is_pressed:
		target_position.y += pressed_offset_y

	button_tween = create_tween()
	button_tween.tween_property(
		sprite,
		"position",
		target_position,
		press_animation_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func notify_target_bridge() -> void:
	var bridge: Node = get_node_or_null(target_bridge)

	if bridge == null:
		push_warning("PressureButton no tiene target_bridge asignado o la ruta es inválida.")
		return

	if bridge.has_method("set_active"):
		bridge.call("set_active", is_pressed)
	else:
		push_warning("El target_bridge no tiene el método set_active().")
