extends Node

## Encounter Manager
## Determines when a wild creature encounter occurs during overworld travel.

var encounter_chance: float = 0.08
var safe_steps: int = 3
var steps_since_encounter: int = 0

var creatures: Array[String] = [
	"Amberfox",
	"Aqufin",
	"Terron",
	"Zephyrin"
]

func on_step_completed() -> void:
	steps_since_encounter += 1
	if not is_encounter_zone():
		return
	if steps_since_encounter < safe_steps:
		return
	if check_encounter():
		trigger_encounter()

func is_encounter_zone() -> bool:
	return true

func check_encounter() -> bool:
	return randf() < encounter_chance

func pick_creature() -> String:
	return creatures.pick_random()

func trigger_encounter() -> void:
	steps_since_encounter = 0
	var selected : String = pick_creature()
	print("Encounter triggered! Wild ", selected, " appeared!")
	if has_node("/root/GameState"):
		get_node("/root/GameState").encounter_creature = selected
		var root = get_tree().current_scene
		if root and root.has_node("Player"):
			get_node("/root/GameState").player_return_position = root.get_node("Player").global_position
	get_tree().change_scene_to_file("res://scenes/battle/Battle.tscn")
