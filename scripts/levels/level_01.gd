extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D

@onready var top_left: Marker2D = $CameraBounds/TopLeft
@onready var bottom_right: Marker2D = $CameraBounds/BottomRight


func _ready() -> void:
	apply_camera_limits()


func apply_camera_limits() -> void:
	camera.limit_left = int(top_left.global_position.x)
	camera.limit_top = int(top_left.global_position.y)
	camera.limit_right = int(bottom_right.global_position.x)
	camera.limit_bottom = int(bottom_right.global_position.y)

	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	
	camera.reset_smoothing()
