extends Node

## GameState Singleton (AutoLoad)
## Keeps track of encounter info, soldier battle state, player return position,
## caught creatures inventory, combat telemetry, and DQN tactical enemy adaptation.

var encounter_creature: String = ""
var player_return_position: Vector2 = Vector2.ZERO
var last_battled_soldier: String = ""
var defeated_soldiers: Array[String] = []
var soldier_battle_active: bool = false
var soldier_assigned_element: String = "" # "Fire", "Water", "Earth", "Air"

var caught_creatures: Array[Dictionary] = []
var inventory: Dictionary = {
	"tubes": 5,
	"caught_creatures": []
}

var telemetry: CombatTelemetry = null
var dqn_ai: DQNInference = null

func _ready() -> void:
	if telemetry == null:
		var tel_script = load("res://scripts/ai/combat_telemetry.gd")
		if tel_script:
			telemetry = tel_script.new()
		else:
			telemetry = CombatTelemetry.new()
	if dqn_ai == null:
		var dqn_script = load("res://scripts/ai/dqn_inference.gd")
		if dqn_script:
			dqn_ai = dqn_script.new()
		else:
			dqn_ai = DQNInference.new()
	print("[GameState] Telemetry and DQN Adaptive AI initialized.")

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
	if telemetry:
		telemetry.record_creature_encounter_or_catch(creature_name)
	print("[GameState] Caught creature added: ", entry)

func get_caught_creatures() -> Array[Dictionary]:
	return caught_creatures

func has_caught_creature(c_name: String) -> bool:
	for c in caught_creatures:
		if c.get("name", "").to_lower() == c_name.to_lower():
			return true
	return false

## Returns dynamic DQN tactical adaptation based on real-time player telemetry
func get_next_adaptation() -> Dictionary:
	if not telemetry or not dqn_ai:
		return {
			"element": "Water",
			"creature": "AquFin",
			"title": "Soldier (Water)",
			"banner_text": "[NEXUS TACTICAL ADAPTATION: Soldier equipped with Water Power!]"
		}
	var vec = telemetry.get_behavior_vector()
	var style = telemetry.get_dominant_style_label()
	return dqn_ai.evaluate_player_adaptation(vec, style)
