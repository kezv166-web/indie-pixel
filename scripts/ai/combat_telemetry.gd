class_name CombatTelemetry
extends RefCounted

## CombatTelemetry
## Tracks player combat actions, habits, and ratios across battles.
## Produces the 12-dimensional normalized behavior vector for DQN inference.

var total_battles: int = 0
var total_turns: int = 0
var player_actions: int = 0

var flame_blast_count: int = 0
var catch_attempt_count: int = 0
var run_count: int = 0

var damage_dealt_total: int = 0
var consecutive_fire_streak: int = 0
var max_consecutive_fire: int = 0

var current_player_hp: int = 50
var player_max_hp: int = 50

var element_counts: Dictionary = {
	"Fire": 0,
	"Water": 0,
	"Earth": 0,
	"Air": 0
}

func record_battle_start() -> void:
	total_battles += 1

func record_battle_end(_victory: bool) -> void:
	# End-of-battle maintenance if needed
	pass

func record_turn() -> void:
	total_turns += 1

func record_move(move_name: String, damage: int) -> void:
	player_actions += 1
	damage_dealt_total += damage
	if "flame" in move_name.to_lower() or "fire" in move_name.to_lower():
		flame_blast_count += 1
		consecutive_fire_streak += 1
		if consecutive_fire_streak > max_consecutive_fire:
			max_consecutive_fire = consecutive_fire_streak
	else:
		consecutive_fire_streak = 0

func record_catch(_target_name: String, _success: bool) -> void:
	player_actions += 1
	catch_attempt_count += 1
	consecutive_fire_streak = 0

func record_run() -> void:
	run_count += 1
	consecutive_fire_streak = 0

func record_hp(hp: int, max_hp: int) -> void:
	current_player_hp = hp
	player_max_hp = max(1, max_hp)

func record_creature_encounter_or_catch(creature_name: String) -> void:
	var c_low = creature_name.to_lower()
	if "amberfox" in c_low or "fire" in c_low:
		element_counts["Fire"] += 1
	elif "aqufin" in c_low or "water" in c_low:
		element_counts["Water"] += 1
	elif "terron" in c_low or "earth" in c_low:
		element_counts["Earth"] += 1
	elif "zephyrin" in c_low or "air" in c_low:
		element_counts["Air"] += 1

## Generates the 12-dimensional vector expected by DQN:
## [0]: flame_blast_freq
## [1]: catch_attempt_freq
## [2]: run_freq
## [3]: avg_turn_count
## [4]: health_preservation
## [5]: fire_creature_pref
## [6]: water_creature_pref
## [7]: earth_creature_pref
## [8]: air_creature_pref
## [9]: damage_dealt_avg
## [10]: consecutive_fire_attacks
## [11]: encounter_history_length
func get_behavior_vector() -> Array:
	var total_acts: float = max(1.0, float(player_actions))
	var total_bats: float = max(1.0, float(total_battles))
	var total_elems: float = max(1.0, float(element_counts["Fire"] + element_counts["Water"] + element_counts["Earth"] + element_counts["Air"]))

	var flame_freq: float = clamp(float(flame_blast_count) / total_acts, 0.0, 1.0)
	var catch_freq: float = clamp(float(catch_attempt_count) / total_acts, 0.0, 1.0)
	var run_freq: float = clamp(float(run_count) / total_bats, 0.0, 1.0)
	var avg_turns: float = clamp((float(total_turns) / total_bats) / 10.0, 0.0, 1.0)
	var hp_ratio: float = clamp(float(current_player_hp) / float(player_max_hp), 0.0, 1.0)

	var fire_pref: float = clamp(float(element_counts["Fire"]) / total_elems, 0.0, 1.0)
	var water_pref: float = clamp(float(element_counts["Water"]) / total_elems, 0.0, 1.0)
	var earth_pref: float = clamp(float(element_counts["Earth"]) / total_elems, 0.0, 1.0)
	var air_pref: float = clamp(float(element_counts["Air"]) / total_elems, 0.0, 1.0)

	var avg_dmg: float = clamp((float(damage_dealt_total) / max(1.0, float(flame_blast_count))) / 20.0, 0.0, 1.0)
	var fire_streak: float = clamp(float(consecutive_fire_streak) / 5.0, 0.0, 1.0)
	var enc_hist: float = clamp(total_bats / 20.0, 0.0, 1.0)

	# Brand new player starts with clean neutral baseline
	if player_actions == 0 and total_battles == 0:
		hp_ratio = 1.0

	return [
		flame_freq,
		catch_freq,
		run_freq,
		avg_turns,
		hp_ratio,
		fire_pref,
		water_pref,
		earth_pref,
		air_pref,
		avg_dmg,
		fire_streak,
		enc_hist
	]

func get_dominant_style_label() -> String:
	var acts = max(1, player_actions)
	var flame_ratio = float(flame_blast_count) / float(acts)
	var catch_ratio = float(catch_attempt_count) / float(acts)

	if flame_ratio >= 0.5 or consecutive_fire_streak >= 2:
		return "Fire-dominant"
	elif catch_ratio >= 0.4:
		return "Catch-reliant"
	elif float(run_count) / max(1.0, float(total_battles)) >= 0.4:
		return "Evasive"
	elif element_counts["Water"] > element_counts["Fire"]:
		return "Water-focused"
	elif element_counts["Earth"] > element_counts["Fire"]:
		return "Earth-focused"
	return "Tactical"
