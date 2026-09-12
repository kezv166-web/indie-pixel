extends Node

## GameState Singleton (AutoLoad)
## Keeps track of encounter info and player overworld return position.

var encounter_creature: String = ""
var player_return_position: Vector2 = Vector2.ZERO

var caught_creatures: Array[Dictionary] = []
var inventory: Dictionary = {
	"tubes": 5,
	"caught_creatures": []
}

func add_caught_creature(creature_name: String, tube_type: String, hp: int = 0, max_hp: int = 42, level: int = 12) -> void:
	var entry: Dictionary = {
		"name": creature_name,
		"tube": tube_type,
		"hp": hp,
		"max_hp": max_hp,
		"level": level,
		"catch_time": Time.get_unix_time_from_system()
	}
	caught_creatures.append(entry)
	if not inventory.has("caught_creatures"):
		inventory["caught_creatures"] = []
	inventory["caught_creatures"].append(entry)
	print("[GameState] Caught creature added: ", entry)

func get_caught_creatures() -> Array[Dictionary]:
	return caught_creatures

func has_caught_creature(c_name: String) -> bool:
	for c in caught_creatures:
		if c.get("name", "").to_lower() == c_name.to_lower():
			return true
	return false
