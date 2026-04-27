extends StaticBody2D

@export var starts_active: bool = false
@export var animation_time: float = 0.25

@onready var bridge_tilemap: TileMapLayer = $VisualPivot/TileMapLayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var is_active: bool = false
var visual_progress: float = 0.0
var bridge_tween: Tween

var bridge_cells: Array[Dictionary] = []
var bridge_columns: Array[int] = []


func _ready() -> void:
	cache_bridge_tiles()

	is_active = starts_active

	if starts_active:
		set_collision_enabled(true)
		apply_visual_progress(1.0)
	else:
		set_collision_enabled(false)
		apply_visual_progress(0.0)


func set_active(value: bool) -> void:
	if value == is_active:
		return

	is_active = value

	if bridge_tween != null:
		bridge_tween.kill()

	if is_active:
		set_collision_enabled(true)

	var target_progress: float = 1.0 if is_active else 0.0

	bridge_tween = create_tween()
	bridge_tween.tween_method(
		apply_visual_progress,
		visual_progress,
		target_progress,
		animation_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if not is_active:
		bridge_tween.finished.connect(_on_hide_animation_finished)


func cache_bridge_tiles() -> void:
	bridge_cells.clear()
	bridge_columns.clear()

	var used_cells: Array[Vector2i] = bridge_tilemap.get_used_cells()

	for coords: Vector2i in used_cells:
		var source_id: int = bridge_tilemap.get_cell_source_id(coords)
		var atlas_coords: Vector2i = bridge_tilemap.get_cell_atlas_coords(coords)
		var alternative_tile: int = bridge_tilemap.get_cell_alternative_tile(coords)

		bridge_cells.append({
			"coords": coords,
			"source_id": source_id,
			"atlas_coords": atlas_coords,
			"alternative_tile": alternative_tile
		})

		if not bridge_columns.has(coords.x):
			bridge_columns.append(coords.x)

	bridge_columns.sort()


func apply_visual_progress(progress: float) -> void:
	visual_progress = clamp(progress, 0.0, 1.0)

	bridge_tilemap.clear()

	if bridge_cells.is_empty() or bridge_columns.is_empty():
		return

	if visual_progress <= 0.0:
		return

	var columns_to_show: int = int(ceil(float(bridge_columns.size()) * visual_progress))
	columns_to_show = clamp(columns_to_show, 0, bridge_columns.size())

	if columns_to_show <= 0:
		return

	var max_visible_column: int = bridge_columns[columns_to_show - 1]

	for cell_data: Dictionary in bridge_cells:
		var coords: Vector2i = cell_data["coords"]

		if coords.x <= max_visible_column:
			bridge_tilemap.set_cell(
				coords,
				cell_data["source_id"],
				cell_data["atlas_coords"],
				cell_data["alternative_tile"]
			)


func set_collision_enabled(value: bool) -> void:
	if collision_shape == null:
		return

	collision_shape.set_deferred("disabled", not value)


func _on_hide_animation_finished() -> void:
	if not is_active:
		set_collision_enabled(false)
