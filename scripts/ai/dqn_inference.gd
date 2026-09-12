class_name DQNInference
extends RefCounted

## DQNInference
## Pure GDScript zero-dependency forward pass for trained DQN policy network.
## Loads weights from assets/ai/dqn_model_weights.json.

var is_loaded: bool = false
var layers: Array = []
var action_names: Dictionary = {}

const WEIGHTS_PATHS: Array[String] = [
	"res://assets/ai/dqn_model_weights.json",
	"res://scripts/ai/dqn_model_weights.json"
]

const ACTION_MAP: Dictionary = {
	0: {
		"element": "Fire",
		"creature": "Amberfox",
		"title": "Soldier (Fire)",
		"rank": "Ignis Guard Lv. 12",
		"strategy": "Aggressive Fire Rush",
		"desc": "Soldier equipped with Amberfox Flame Burst"
	},
	1: {
		"element": "Water",
		"creature": "AquFin",
		"title": "Soldier (Water)",
		"rank": "Tide Sentry Lv. 12",
		"strategy": "Water Counter Surge",
		"desc": "Soldier equipped with AquFin Tidal Wave"
	},
	2: {
		"element": "Earth",
		"creature": "Terron",
		"title": "Soldier (Earth)",
		"rank": "Terra Guard Lv. 12",
		"strategy": "Earth Tank Defense",
		"desc": "Soldier equipped with Terron Rock Crash"
	},
	3: {
		"element": "Air",
		"creature": "Zephyrin",
		"title": "Soldier (Air)",
		"rank": "Aero Scout Lv. 12",
		"strategy": "Air Whirlwind Evasion",
		"desc": "Soldier equipped with Zephyrin Cyclone"
	},
	4: {
		"element": "Water",
		"creature": "AquFin",
		"title": "Soldier (Water Dampener)",
		"rank": "Tide Sentry Lv. 12",
		"strategy": "Defensive Dampen",
		"desc": "Soldier equipped with AquFin Dampener"
	},
	5: {
		"element": "Air",
		"creature": "Zephyrin",
		"title": "Soldier (Air Skirmisher)",
		"rank": "Aero Scout Lv. 12",
		"strategy": "Ranged Punish",
		"desc": "Soldier equipped with Zephyrin Gale"
	}
}

func _init() -> void:
	load_weights()

func load_weights() -> bool:
	for path in WEIGHTS_PATHS:
		if FileAccess.file_exists(path):
			var file = FileAccess.open(path, FileAccess.READ)
			if file:
				var json_text = file.get_as_text()
				file.close()
				var test_json = JSON.new()
				var error = test_json.parse(json_text)
				if error == OK:
					var data = test_json.data
					if data is Dictionary and data.has("layers"):
						layers = data["layers"]
						action_names = data.get("action_names", {})
						is_loaded = true
						print("[DQNInference] Successfully loaded %d layers from %s" % [layers.size(), path])
						return true
	
	# Fallback: project settings globalize path
	for path in WEIGHTS_PATHS:
		var abs_p = ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(abs_p):
			var file = FileAccess.open(abs_p, FileAccess.READ)
			if file:
				var json_text = file.get_as_text()
				file.close()
				var test_json = JSON.new()
				var error = test_json.parse(json_text)
				if error == OK:
					var data = test_json.data
					if data is Dictionary and data.has("layers"):
						layers = data["layers"]
						action_names = data.get("action_names", {})
						is_loaded = true
						print("[DQNInference] Successfully loaded layers from globalized %s" % abs_p)
						return true

	push_warning("[DQNInference] Could not load weights from JSON. Using fallback heuristic.")
	is_loaded = false
	return false

## Forward pass through dense layers with ReLU activation
func forward(input_vec: Array) -> Array:
	if not is_loaded or layers.is_empty():
		return _fallback_forward(input_vec)

	var current: Array = []
	for v in input_vec:
		current.append(float(v))

	for l_idx in range(layers.size()):
		var layer_dict = layers[l_idx]
		var weights: Array = layer_dict.get("weights", [])
		var bias: Array = layer_dict.get("bias", [])
		var num_out: int = weights.size()
		var next_vec: Array = []
		next_vec.resize(num_out)

		for j in range(num_out):
			var row: Array = weights[j]
			var sum_val: float = float(bias[j])
			var in_len = min(row.size(), current.size())
			for k in range(in_len):
				sum_val += float(row[k]) * float(current[k])
			
			# ReLU activation on all hidden layers
			if l_idx < layers.size() - 1:
				if sum_val < 0.0:
					sum_val = 0.0
			
			next_vec[j] = sum_val

		current = next_vec

	return current

## Returns the index of the highest Q-value action
func predict(input_vec: Array) -> int:
	var q_values = forward(input_vec)
	if q_values.is_empty():
		return 1 # Default to Water Counter against Fire
	
	var best_idx: int = 0
	var best_val: float = float(q_values[0])
	for i in range(1, q_values.size()):
		if float(q_values[i]) > best_val:
			best_val = float(q_values[i])
			best_idx = i

	return best_idx

## Returns complete counter metadata for an action
func get_counter_info(action_idx: int, dominant_style: String = "") -> Dictionary:
	var info: Dictionary = ACTION_MAP.get(action_idx, ACTION_MAP[1]).duplicate()
	info["action"] = action_idx
	
	var reason = dominant_style
	if reason == "":
		reason = "Dominant behavior pattern"
	
	info["banner_text"] = "[NEXUS TACTICAL ADAPTATION: Player %s -> Soldier channels %s Power!]" % [
		reason,
		info["element"]
	]
	return info

## Convenience evaluation from behavior vector
func evaluate_player_adaptation(behavior_vec: Array, dominant_style: String = "") -> Dictionary:
	var act = predict(behavior_vec)
	return get_counter_info(act, dominant_style)

## Fallback heuristic forward pass if JSON weights file was absent
func _fallback_forward(input_vec: Array) -> Array:
	var q: Array = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	if input_vec.size() < 12:
		q[1] = 10.0
		return q

	var flame_freq = float(input_vec[0])
	var catch_freq = float(input_vec[1])
	var water_pref = float(input_vec[6])
	var earth_pref = float(input_vec[7])
	var consec_fire = float(input_vec[10])

	if flame_freq > 0.5 or consec_fire > 0.3:
		q[1] = 15.0 # Water Counter
		q[4] = 12.0 # Dampen
	elif catch_freq > 0.5:
		q[0] = 14.0 # Fire Rush
		q[5] = 13.0 # Punish
	elif water_pref > 0.5:
		q[2] = 15.0 # Earth Tank
	elif earth_pref > 0.5:
		q[3] = 15.0 # Air Evasion
	else:
		q[1] = 10.0 # Balanced
	return q
