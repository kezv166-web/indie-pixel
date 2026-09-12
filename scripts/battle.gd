extends Node2D

## Battle Scene Controller
## Spawns the encountered creature at a random enemy spawn marker.
## Provides an escape option to return to the overworld.

@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var enemy_spawns: Array[Marker2D] = [
	$EnemySpawn1,
	$EnemySpawn2,
	$EnemySpawn3,
	$EnemySpawn4
]
@onready var creature_sprite: Sprite2D = $CreatureSprite
@onready var info_label: Label = $CanvasLayer/InfoLabel

const CREATURE_TEXTURES: Dictionary = {
	"Amberfox": "res://assets/characters/creatures/Amberfox.png",
	"Aqufin": "res://assets/characters/creatures/Aqufin.png",
	"Terron": "res://assets/characters/creatures/Terron.png",
	"Zephyrin": "res://assets/characters/creatures/Zephyrin.png"
}

func _ready() -> void:
	var creature_name: String = ""
	if has_node("/root/GameState"):
		creature_name = get_node("/root/GameState").encounter_creature

	if creature_name == "" or not CREATURE_TEXTURES.has(creature_name):
		creature_name = "LoadedCreature" if creature_name != "" else "Amberfox"

	spawn_creature(creature_name)

	if info_label:
		info_label.text = "A wild " + creature_name + " appeared!\n[Space/Enter/Esc] to Run"

func spawn_creature(creature_name: String) -> void:
	var chosen_spawn: Marker2D = enemy_spawns.pick_random()
	var texture_path: String = CREATURE_TEXTURES.get(creature_name, "")

	if ResourceLoader.exists(texture_path):
		var tex = load(texture_path)
		creature_sprite.texture = tex
		creature_sprite.global_position = chosen_spawn.global_position

		var tex_h: float = tex.get_height()
		if tex_h > 0:
			var target_scale: float = 72.0 / tex_h
			creature_sprite.scale = Vector2(target_scale, target_scale)

		print("Spawned ", creature_name, " at marker ", chosen_spawn.name, " at ", chosen_spawn.global_position)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			return_to_world()

func _on_run_button_pressed() -> void:
	return_to_world()

func return_to_world() -> void:
	print("Escaped battle, returning to overworld...")
	get_tree().change_scene_to_file("res://scenes/world.tscn")
