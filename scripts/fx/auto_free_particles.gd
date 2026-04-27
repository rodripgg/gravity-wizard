extends Node2D

@export var lifetime: float = 0.45

@onready var particles: GPUParticles2D = $GPUParticles2D


func play_at(world_position: Vector2, direction: Vector2) -> void:
	global_position = world_position
	rotation = direction.angle()

	z_index = 100
	particles.z_index = 100

	particles.emitting = false
	particles.restart()
	particles.emitting = true

	await get_tree().create_timer(lifetime).timeout
	queue_free()
