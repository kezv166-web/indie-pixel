extends Node2D

## Virbhadra City Overworld Controller
## Populates and manages the overworld map layers from SETILES.tres.

@onready var map_reference: Sprite2D = $MapReference
@onready var ground_layer: TileMapLayer = $Ground
@onready var water_layer: TileMapLayer = $Water
@onready var roads_layer: TileMapLayer = $Roads
@onready var cliffs_layer: TileMapLayer = $Cliffs
@onready var bridges_layer: TileMapLayer = $Bridges
@onready var buildings_container: Node2D = $Buildings
@onready var trees_container: Node2D = $Trees
@onready var props_container: Node2D = $Props
@onready var overhead_layer: TileMapLayer = $Overhead
@onready var player: CharacterBody2D = $Player

# Map Pixel Dimensions (1672 x 941 pixels from new_map.png)
const MAP_PIXEL_WIDTH: int = 1672
const MAP_PIXEL_HEIGHT: int = 941

# Reference map opacity cycling (F1 key)
var _ref_alpha_index: int = 0
const _REF_ALPHAS: Array[float] = [1.0, 0.35, 0.0]

# Tile Atlas Coordinates from SETILES.png
const TILE_GRASS_1: Vector2i = Vector2i(2, 0)
const TILE_GRASS_2: Vector2i = Vector2i(4, 0)
const TILE_ROAD: Vector2i = Vector2i(16, 16)
const TILE_WATER: Vector2i = Vector2i(48, 20)
const TILE_CLIFF: Vector2i = Vector2i(24, 0)
const TILE_BRIDGE: Vector2i = Vector2i(12, 56)

func _ready() -> void:
	print("Initializing Virbhadra City Overworld (GBA Layered Tilemap Architecture)...")
	_setup_camera_limits()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			_cycle_map_reference_opacity()

func _cycle_map_reference_opacity() -> void:
	if map_reference:
		_ref_alpha_index = (_ref_alpha_index + 1) % _REF_ALPHAS.size()
		var alpha: float = _REF_ALPHAS[_ref_alpha_index]
		map_reference.modulate.a = alpha
		map_reference.visible = (alpha > 0.0)
		print("Reference map opacity set to: ", int(alpha * 100.0), "% (Press F1 to cycle)")

func _setup_camera_limits() -> void:
	if player and player.has_node("Camera2D"):
		var camera: Camera2D = player.get_node("Camera2D")
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = MAP_PIXEL_WIDTH
		camera.limit_bottom = MAP_PIXEL_HEIGHT
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 5.0
