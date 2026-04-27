extends Area2D

@export_file("*.tscn") var next_level_path: String = ""
@export var finish_delay: float = 0.35

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var collected: bool = false


func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if collected:
		return

	if not body.is_in_group("player"):
		return

	complete_level()


func complete_level() -> void:
	collected = true
	collision_shape.set_deferred("disabled", true)

	play_collect_effect()

	await get_tree().create_timer(finish_delay).timeout

	if next_level_path.is_empty():
		print("Nivel completado.")
		return

	get_tree().change_scene_to_file(next_level_path)


func play_collect_effect() -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		sprite,
		"scale",
		Vector2(1.5, 1.5),
		finish_delay
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		sprite,
		"modulate:a",
		0.0,
		finish_delay
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
