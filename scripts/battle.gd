extends Node2D

## Battle Scene Controller
## Handles authentic GBA-style turn-based combat, creature animations, health bars,
## direct Soldier platform combat with 4 elemental powers, clean catch deflection,
## telemetry tracking, and DQN tactical enemy adaptation.

@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var enemy_spawns: Array[Marker2D] = [
	$EnemySpawn1,
	$EnemySpawn2,
	$EnemySpawn3,
	$EnemySpawn4
]
@onready var creature_sprite: Sprite2D = $CreatureSprite
@onready var soldier_sprite: AnimatedSprite2D = $SoldierSprite if has_node("SoldierSprite") else null
@onready var player_sprite: AnimatedSprite2D = $PlayerSprite
@onready var attack_effect: AnimatedSprite2D = $AttackEffect
@onready var enemy_attack_effect: AnimatedSprite2D = $EnemyAttackEffect if has_node("EnemyAttackEffect") else $AttackEffect

@onready var enemy_name_label: Label = $CanvasLayer/EnemyStatusBox/VBox/TopRow/EnemyNameLabel
@onready var enemy_lv_label: Label = $CanvasLayer/EnemyStatusBox/VBox/TopRow/EnemyLvLabel if has_node("CanvasLayer/EnemyStatusBox/VBox/TopRow/EnemyLvLabel") else null
@onready var enemy_health_bar: Control = $CanvasLayer/EnemyStatusBox/VBox/EnemyHealthBar
@onready var enemy_hp_text: Label = $CanvasLayer/EnemyStatusBox/VBox/EnemyHPText

@onready var player_name_label: Label = $CanvasLayer/PlayerStatusBox/VBox/TopRow/PlayerNameLabel
@onready var player_health_bar: Control = $CanvasLayer/PlayerStatusBox/VBox/PlayerHealthBar
@onready var player_hp_text: Label = $CanvasLayer/PlayerStatusBox/VBox/PlayerHPText

@onready var dialogue_label: Label = $CanvasLayer/DialogueLabel
@onready var action_menu: Control = $CanvasLayer/ActionMenu
@onready var fight_button: Button = $CanvasLayer/ActionMenu/VBox/FightButton
@onready var catch_button: Button = $CanvasLayer/ActionMenu/VBox/CatchButton if has_node("CanvasLayer/ActionMenu/VBox/CatchButton") else null
@onready var run_button: Button = $CanvasLayer/ActionMenu/VBox/RunButton
@onready var moves_menu: Control = $CanvasLayer/MovesMenu
@onready var move1_button: Button = $CanvasLayer/MovesMenu/HBox/MoveGrid/Move1
@onready var cancel_button: Button = $CanvasLayer/MovesMenu/HBox/CancelButton

@onready var adaptation_banner: PanelContainer = $CanvasLayer/AdaptationBanner if has_node("CanvasLayer/AdaptationBanner") else null
@onready var banner_label: Label = $CanvasLayer/AdaptationBanner/BannerLabel if has_node("CanvasLayer/AdaptationBanner/BannerLabel") else null

@onready var catch_tube: Sprite2D = $CatchTube if has_node("CatchTube") else null
@onready var catch_sparkles: CPUParticles2D = $CatchSparkles if has_node("CatchSparkles") else null

const SOLDIER_ELEMENTAL_PROFILES: Dictionary = {
	"Fire": {
		"element": "Fire",
		"creature": "Amberfox",
		"title": "Soldier (Fire)",
		"rank": "Ignis Guard Lv. 12",
		"attack_move": "Flame Burst",
		"damage": 12,
		"resistance": "Fire",
		"weakness": "Water"
	},
	"Water": {
		"element": "Water",
		"creature": "AquFin",
		"title": "Soldier (Water)",
		"rank": "Tide Sentry Lv. 12",
		"attack_move": "Tidal Wave",
		"damage": 10,
		"resistance": "Fire",
		"weakness": "Earth"
	},
	"Earth": {
		"element": "Earth",
		"creature": "Terron",
		"title": "Soldier (Earth)",
		"rank": "Terra Guard Lv. 12",
		"attack_move": "Rock Crash",
		"damage": 11,
		"resistance": "Water",
		"weakness": "Air"
	},
	"Air": {
		"element": "Air",
		"creature": "Zephyrin",
		"title": "Soldier (Air)",
		"rank": "Aero Scout Lv. 12",
		"attack_move": "Cyclone Whirlwind",
		"damage": 10,
		"resistance": "Earth",
		"weakness": "Fire"
	}
}

const ENEMY_ATTACK_DATA: Dictionary = {
	"Amberfox": {
		"frames_path": "res://assets/effects/amberfox_attack_frames.tres",
		"dir_path": "res://assets/effects/amberfox_attack",
		"frame_count": 5,
		"fps": 10.0,
		"anim": "amberfox_attack",
		"scale": Vector2(0.45, 0.45),
		"offset": Vector2(0, -10),
		"flip_h": true,
		"duration": 0.55
	},
	"Aqufin": {
		"frames_path": "res://assets/effects/aqufin_attack_frames.tres",
		"dir_path": "res://assets/effects/aqufin_attack",
		"frame_count": 8,
		"fps": 11.0,
		"anim": "aqufin_attack",
		"scale": Vector2(0.42, 0.42),
		"offset": Vector2(0, -4),
		"flip_h": true,
		"duration": 0.78
	},
	"AquFin": {
		"frames_path": "res://assets/effects/aqufin_attack_frames.tres",
		"dir_path": "res://assets/effects/aqufin_attack",
		"frame_count": 8,
		"fps": 11.0,
		"anim": "aqufin_attack",
		"scale": Vector2(0.42, 0.42),
		"offset": Vector2(0, -4),
		"flip_h": true,
		"duration": 0.78
	},
	"Terron": {
		"frames_path": "res://assets/effects/terron_attack_frames.tres",
		"dir_path": "res://assets/effects/terron_attack",
		"frame_count": 7,
		"fps": 10.0,
		"anim": "terron_attack",
		"scale": Vector2(0.35, 0.35),
		"offset": Vector2(0, -18),
		"flip_h": false,
		"duration": 0.75
	},
	"Zephyrin": {
		"frames_path": "res://assets/effects/zephyrin_attack_frames.tres",
		"dir_path": "res://assets/effects/zephyrin_attack",
		"frame_count": 7,
		"fps": 11.0,
		"anim": "zephyrin_attack",
		"scale": Vector2(0.45, 0.45),
		"offset": Vector2(0, -12),
		"flip_h": false,
		"duration": 0.68
	}
}

const CREATURE_TEXTURES: Dictionary = {
	"Amberfox": "res://assets/characters/creatures/Amberfox.png",
	"Aqufin": "res://assets/characters/creatures/Aqufin.png",
	"AquFin": "res://assets/characters/creatures/Aqufin.png",
	"Terron": "res://assets/characters/creatures/Terron.png",
	"Zephyrin": "res://assets/characters/creatures/Zephyrin.png"
}

const TUBE_TEXTURES: Dictionary = {
	"empty": "res://assets/tubes/tube_empty.png",
	"clear": "res://assets/tubes/tube_empty.png",
	"Amberfox": "res://assets/tubes/tube_fire.png",
	"Aqufin": "res://assets/tubes/tube_water.png",
	"AquFin": "res://assets/tubes/tube_water.png",
	"Terron": "res://assets/tubes/tube_earth.png",
	"Zephyrin": "res://assets/tubes/tube_air.png",
	"Fire": "res://assets/tubes/tube_fire.png",
	"Water": "res://assets/tubes/tube_water.png",
	"Earth": "res://assets/tubes/tube_earth.png",
	"Air": "res://assets/tubes/tube_air.png"
}

const CREATURE_ELEMENT_NAME: Dictionary = {
	"Amberfox": "Fire",
	"Aqufin": "Water",
	"AquFin": "Water",
	"Terron": "Earth",
	"Zephyrin": "Air"
}

var _cached_player_frames: SpriteFrames = null
var _cached_enemy_frames: Dictionary = {}
var _cached_tube_textures: Dictionary = {}

var creature_orig_scale: Vector2 = Vector2(1, 1)
var creature_orig_pos: Vector2 = Vector2(246, 105)

var soldier_orig_pos: Vector2 = Vector2(246, 105)
var soldier_orig_scale: Vector2 = Vector2(0.42, 0.42)

var is_soldier_battle: bool = false
var soldier_element: String = "Earth"
var soldier_creature_power: String = "Terron"
var current_soldier_profile: Dictionary = {}

var enemy_name: String = "Aqufin"
var enemy_hp: int = 42
var enemy_max_hp: int = 42

var player_hp: int = 50
var player_max_hp: int = 50

var flame_blast_pp: int = 3
var flame_blast_max_pp: int = 3

enum BattleState { MENU, MOVES, BUSY, FINISHED }
var current_state: BattleState = BattleState.MENU

func _ready() -> void:
	_ensure_catch_nodes()
	_ensure_soldier_sprite()

	var gs = get_node_or_null("/root/GameState")
	if gs:
		if "soldier_battle_active" in gs and gs.soldier_battle_active:
			is_soldier_battle = true
			gs.soldier_battle_active = false
		if gs.encounter_creature != "":
			enemy_name = gs.encounter_creature
		if gs.telemetry:
			gs.telemetry.record_battle_start()
			gs.telemetry.record_hp(player_hp, player_max_hp)

	if is_soldier_battle:
		_setup_soldier_battle_opponent(gs)
	else:
		_setup_wild_creature_opponent()

	if enemy_health_bar:
		enemy_health_bar.setup(enemy_hp, enemy_max_hp)
	if player_health_bar:
		player_health_bar.setup(player_hp, player_max_hp)

	update_hp_labels()

	if player_sprite:
		player_sprite.flip_h = false
		if player_spawn:
			player_sprite.global_position = player_spawn.global_position
		if player_sprite.sprite_frames and player_sprite.sprite_frames.has_animation("idle_right"):
			player_sprite.play("idle_right")
		elif player_sprite.sprite_frames and player_sprite.sprite_frames.has_animation("walk_right"):
			player_sprite.animation = "walk_right"
			player_sprite.stop()
			player_sprite.frame = 0

	if attack_effect:
		attack_effect.visible = false
		var p_frames = _get_or_create_player_attack_frames()
		if p_frames:
			attack_effect.sprite_frames = p_frames
	
	if enemy_attack_effect:
		enemy_attack_effect.visible = false
		var lookup_c = soldier_creature_power if is_soldier_battle else enemy_name
		var e_frames = _get_or_create_enemy_frames(lookup_c)
		if e_frames:
			enemy_attack_effect.sprite_frames = e_frames

	if fight_button and catch_button and run_button:
		fight_button.focus_neighbor_top = run_button.get_path()
		fight_button.focus_neighbor_bottom = catch_button.get_path()
		catch_button.focus_neighbor_top = fight_button.get_path()
		catch_button.focus_neighbor_bottom = run_button.get_path()
		run_button.focus_neighbor_top = catch_button.get_path()
		run_button.focus_neighbor_bottom = fight_button.get_path()

	var intro_msg: String = ""
	if is_soldier_battle:
		intro_msg = "Soldier challenged you to battle!\nSoldier channels %s power (%s)!" % [
			current_soldier_profile.get("element", "Earth"),
			current_soldier_profile.get("creature", "Terron")
		]
	else:
		intro_msg = "A wild " + enemy_name + " appeared!\nWhat will Player do?"

	show_main_menu(intro_msg)

func _setup_soldier_battle_opponent(gs: Node) -> void:
	# 1. Hide wild creature sprite
	if creature_sprite:
		creature_sprite.visible = false

	# 2. Determine elemental profile using DQN tactical adaptation and soldier assignment
	var adaptation: Dictionary = {}
	if gs and gs.has_method("get_next_adaptation"):
		adaptation = gs.get_next_adaptation()

	var assigned: String = ""
	if gs and "soldier_assigned_element" in gs:
		assigned = gs.soldier_assigned_element

	# If overworld soldier has a dedicated assigned power (Fire, Water, Earth, Air), respect it!
	# If soldier is adaptive or unassigned, the in-engine DQN forward-pass runner selects the counter!
	if assigned != "" and assigned != "Adaptive" and SOLDIER_ELEMENTAL_PROFILES.has(assigned):
		soldier_element = assigned
		var banner_msg = "[NEXUS TACTICAL ADAPTATION: Soldier equipped with %s Power!]" % soldier_element
		var recommended = adaptation.get("element", "")
		if recommended != "" and recommended != soldier_element:
			banner_msg = "[NEXUS TACTICAL ADAPTATION: Soldier deployed with %s Power! (Nexus Counter: %s)]" % [soldier_element, recommended]
		adaptation["banner_text"] = banner_msg
	elif adaptation.has("element"):
		# DQN forward-pass selects the optimal enemy elemental counter
		soldier_element = adaptation.get("element", "Water")
	else:
		soldier_element = _creature_to_element(enemy_name)

	current_soldier_profile = SOLDIER_ELEMENTAL_PROFILES.get(soldier_element, SOLDIER_ELEMENTAL_PROFILES["Earth"]).duplicate()
	soldier_creature_power = current_soldier_profile.get("creature", "Terron")

	# 3. Position and display Soldier directly on fighting ground platform (246, 105)
	if soldier_sprite:
		soldier_sprite.visible = true
		soldier_sprite.global_position = Vector2(246, 105)
		soldier_sprite.scale = soldier_orig_scale
		soldier_orig_pos = soldier_sprite.global_position
		_set_soldier_left_facing()

	# 4. Update status box to soldier title & rank
	if enemy_name_label:
		enemy_name_label.text = current_soldier_profile.get("title", "Soldier (Guard)")
	if enemy_lv_label:
		enemy_lv_label.text = current_soldier_profile.get("rank", "Lv. 12")

	# 5. Display DQN Tactical Adaptation Banner
	_show_tactical_banner(adaptation)

func _setup_wild_creature_opponent() -> void:
	if soldier_sprite:
		soldier_sprite.visible = false
	if adaptation_banner:
		adaptation_banner.visible = false

	spawn_creature(enemy_name)

	if enemy_name_label:
		enemy_name_label.text = enemy_name
	if enemy_lv_label:
		enemy_lv_label.text = "Lv. 12"

func _set_soldier_left_facing() -> void:
	if not soldier_sprite:
		return
	if soldier_sprite.sprite_frames:
		if soldier_sprite.sprite_frames.has_animation("idle_left"):
			soldier_sprite.play("idle_left")
		elif soldier_sprite.sprite_frames.has_animation("walk_left"):
			soldier_sprite.animation = "walk_left"
			soldier_sprite.stop()
			soldier_sprite.frame = 0
		else:
			soldier_sprite.flip_h = false

func _show_tactical_banner(adaptation: Dictionary) -> void:
	if not adaptation_banner or not banner_label:
		return

	var text_msg = adaptation.get("banner_text", "")
	if text_msg == "":
		text_msg = "[NEXUS TACTICAL ADAPTATION: Soldier equipped with %s Power!]" % current_soldier_profile.get("element", "Earth")
	
	banner_label.text = text_msg
	adaptation_banner.visible = true
	adaptation_banner.modulate.a = 0.0
	adaptation_banner.position.y = -18.0

	var tween = create_tween()
	tween.tween_property(adaptation_banner, "modulate:a", 1.0, 0.35)
	tween.parallel().tween_property(adaptation_banner, "position:y", 2.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _creature_to_element(c_name: String) -> String:
	for k in CREATURE_ELEMENT_NAME.keys():
		if k.to_lower() == c_name.to_lower():
			return CREATURE_ELEMENT_NAME[k]
	return "Earth"

func spawn_creature(c_name: String) -> void:
	var tex_path: String = ""
	for k in CREATURE_TEXTURES.keys():
		if k.to_lower() == c_name.to_lower():
			tex_path = CREATURE_TEXTURES[k]
			break
	if tex_path == "":
		tex_path = CREATURE_TEXTURES.get(c_name, "")
	
	var tex: Texture2D = null
	if ResourceLoader.exists(tex_path):
		tex = load(tex_path)
	if tex == null and tex_path != "":
		var abs_path = ProjectSettings.globalize_path(tex_path)
		var img = Image.load_from_file(abs_path)
		if img == null or img.is_empty():
			img = Image.load_from_file(tex_path)
		if img and not img.is_empty():
			tex = ImageTexture.create_from_image(img)
	
	if tex and creature_sprite:
		creature_sprite.texture = tex
		creature_sprite.visible = true
		if enemy_spawns.size() > 0:
			var chosen = enemy_spawns.pick_random()
			creature_sprite.global_position = chosen.global_position
		var tex_h = tex.get_height()
		if tex_h > 0:
			var target_scale = 66.0 / tex_h
			creature_sprite.scale = Vector2(target_scale, target_scale)
		creature_orig_pos = creature_sprite.global_position
		creature_orig_scale = creature_sprite.scale

func update_hp_labels() -> void:
	if enemy_hp_text:
		enemy_hp_text.text = str(enemy_hp) + " / " + str(enemy_max_hp)
	if player_hp_text:
		player_hp_text.text = str(player_hp) + " / " + str(player_max_hp)
	if enemy_health_bar:
		enemy_health_bar.set_hp(enemy_hp)
	if player_health_bar:
		player_health_bar.set_hp(player_hp)

func update_moves_ui() -> void:
	if move1_button:
		move1_button.text = "Flame Blast  %d/%d" % [flame_blast_pp, flame_blast_max_pp]
		if flame_blast_pp <= 0:
			move1_button.modulate = Color(0.6, 0.6, 0.6, 0.8)
		else:
			move1_button.modulate = Color(1, 1, 1, 1)

func show_main_menu(msg: String = "What will Player do?") -> void:
	current_state = BattleState.MENU
	if dialogue_label:
		dialogue_label.visible = true
		dialogue_label.offset_right = 198.0
		dialogue_label.text = msg
	if action_menu:
		action_menu.visible = true
	if moves_menu:
		moves_menu.visible = false
	if fight_button and fight_button.is_inside_tree():
		fight_button.grab_focus()

func show_moves_menu() -> void:
	current_state = BattleState.MOVES
	if dialogue_label:
		dialogue_label.visible = false
	if action_menu:
		action_menu.visible = false
	if moves_menu:
		moves_menu.visible = true
	update_moves_ui()
	if move1_button and move1_button.is_inside_tree():
		move1_button.grab_focus()

func _on_fight_button_pressed() -> void:
	if current_state == BattleState.MENU:
		show_moves_menu()

func _on_run_button_pressed() -> void:
	if current_state != BattleState.MENU:
		return
	current_state = BattleState.BUSY
	if action_menu:
		action_menu.visible = false
	if dialogue_label:
		dialogue_label.visible = true
		dialogue_label.offset_right = 304.0
		dialogue_label.text = "Got away safely!"

	var gs = get_node_or_null("/root/GameState")
	if gs and gs.telemetry:
		gs.telemetry.record_run()

	if player_sprite:
		player_sprite.flip_h = true
		var run_tween = create_tween()
		run_tween.tween_property(player_sprite, "position:x", player_sprite.position.x - 50.0, 0.4)
	await get_tree().create_timer(0.8).timeout
	return_to_world()

func _on_cancel_button_pressed() -> void:
	if current_state == BattleState.MOVES:
		show_main_menu()

func _show_no_pp_message(move_name: String) -> void:
	if moves_menu:
		moves_menu.visible = false
	if dialogue_label:
		dialogue_label.visible = true
		dialogue_label.offset_right = 304.0
		dialogue_label.text = "There's no PP left for " + move_name + "!"
	await get_tree().create_timer(1.2).timeout
	if current_state == BattleState.MOVES:
		show_moves_menu()

func _on_move_1_pressed() -> void:
	if current_state != BattleState.MOVES:
		return
	if flame_blast_pp <= 0:
		_show_no_pp_message("Flame Blast")
		return
	flame_blast_pp -= 1
	var base_damage: int = randi_range(12, 14)
	execute_attack("Flame Blast", base_damage)

func execute_attack(move_name: String, damage: int) -> void:
	current_state = BattleState.BUSY
	if moves_menu:
		moves_menu.visible = false
	if action_menu:
		action_menu.visible = false
	
	var gs = get_node_or_null("/root/GameState")

	if dialogue_label:
		dialogue_label.visible = true
		dialogue_label.offset_right = 304.0
		dialogue_label.text = "Player used " + move_name + "!"

	# Player step forward and back
	if player_sprite:
		var orig_x = player_sprite.position.x
		var lunge_tween = create_tween()
		lunge_tween.tween_property(player_sprite, "position:x", orig_x + 12.0, 0.15)
		lunge_tween.tween_property(player_sprite, "position:x", orig_x, 0.15)

	await get_tree().create_timer(0.3).timeout

	# Identify active target node (soldier or creature)
	var target_node: Node2D = soldier_sprite if (is_soldier_battle and soldier_sprite) else creature_sprite
	var target_pos: Vector2 = target_node.global_position if target_node else Vector2(246, 105)

	# Play attack animation directly over target
	if attack_effect:
		var fb_frames = _get_or_create_player_attack_frames()
		if fb_frames:
			attack_effect.sprite_frames = fb_frames
		attack_effect.flip_h = false
		attack_effect.global_position = target_pos
		attack_effect.scale = Vector2(0.42, 0.42)
		attack_effect.frame = 0
		attack_effect.visible = true
		attack_effect.play("flame_blast")
	await get_tree().create_timer(0.5).timeout
	if attack_effect:
		attack_effect.visible = false
		attack_effect.stop()
	
	# Target hit flash and shake
	if target_node:
		var flash_tween = create_tween()
		var o_pos = target_node.position
		flash_tween.tween_property(target_node, "modulate", Color(2.2, 0.4, 0.4, 1), 0.1)
		flash_tween.tween_property(target_node, "modulate", Color(1, 1, 1, 1), 0.1)
		var shake = create_tween()
		shake.tween_property(target_node, "position:x", o_pos.x + 5, 0.05)
		shake.tween_property(target_node, "position:x", o_pos.x - 5, 0.05)
		shake.tween_property(target_node, "position:x", o_pos.x, 0.05)

	# Elemental interaction against soldier
	var final_damage = damage
	var effect_msg = ""
	if is_soldier_battle:
		if soldier_element == "Water":
			final_damage = max(5, int(damage * 0.65)) # Water dampens Fire!
			effect_msg = "\nIt's not very effective against Water armor!"
		elif soldier_element == "Fire":
			final_damage = max(6, int(damage * 0.75)) # Fire resists Fire!
			effect_msg = "\nIt's not very effective against Fire armor!"
		elif soldier_element == "Earth":
			final_damage = int(damage * 1.1)
		elif soldier_element == "Air":
			final_damage = int(damage * 1.25)
			effect_msg = "\nIt's super effective against Air!"

	# Telemetry record
	if gs and gs.telemetry:
		gs.telemetry.record_move(move_name, final_damage)
		gs.telemetry.record_turn()

	enemy_hp = max(0, enemy_hp - final_damage)
	update_hp_labels()

	if effect_msg != "" and dialogue_label:
		dialogue_label.text += effect_msg

	await get_tree().create_timer(0.7).timeout
	
	if enemy_hp <= 0:
		# Victory flow
		if is_soldier_battle:
			if dialogue_label:
				dialogue_label.text = "Soldier was defeated!\nPlayer won the battle!"
			if soldier_sprite:
				var faint_tween = create_tween()
				faint_tween.tween_property(soldier_sprite, "modulate:a", 0.0, 0.8)
				faint_tween.parallel().tween_property(soldier_sprite, "position:y", soldier_sprite.position.y + 16.0, 0.8)
			if gs:
				if "last_battled_soldier" in gs and gs.last_battled_soldier != "":
					if not gs.defeated_soldiers.has(gs.last_battled_soldier):
						gs.defeated_soldiers.append(gs.last_battled_soldier)
				if gs.telemetry:
					gs.telemetry.record_battle_end(true)
		else:
			if dialogue_label:
				dialogue_label.text = "Enemy " + enemy_name + " fainted!\nPlayer won the battle!"
			if creature_sprite:
				var faint_tween = create_tween()
				faint_tween.tween_property(creature_sprite, "modulate:a", 0.0, 0.8)
				faint_tween.parallel().tween_property(creature_sprite, "position:y", creature_sprite.position.y + 20.0, 0.8)
			if gs and gs.telemetry:
				gs.telemetry.record_battle_end(true)

		await get_tree().create_timer(1.8).timeout
		return_to_world()
		return

	# Enemy Retaliation
	await execute_enemy_turn()

func execute_enemy_turn() -> void:
	if is_soldier_battle:
		var profile = current_soldier_profile
		var elem = profile.get("element", "Earth")
		var creature = profile.get("creature", "Terron")
		var move_name = profile.get("attack_move", "Rock Crash")
		var enemy_damage = profile.get("damage", 10)

		if dialogue_label:
			dialogue_label.text = "Soldier unleashes %s %s!" % [creature, move_name]
		await get_tree().create_timer(0.6).timeout

		# Soldier lunges forward
		if soldier_sprite:
			var soldier_lunge = create_tween()
			var o_x = soldier_sprite.position.x
			soldier_lunge.tween_property(soldier_sprite, "position:x", o_x - 14.0, 0.12)
			soldier_lunge.tween_property(soldier_sprite, "position:x", o_x, 0.12)

		await get_tree().create_timer(0.15).timeout

		# Play creature attack animation on player
		await play_enemy_attack_animation(creature)

		_apply_damage_to_player(enemy_damage)
	else:
		if dialogue_label:
			dialogue_label.text = "Wild " + enemy_name + " attacks!"
		await get_tree().create_timer(0.6).timeout

		if creature_sprite:
			var enemy_lunge = create_tween()
			var o_x = creature_sprite.position.x
			enemy_lunge.tween_property(creature_sprite, "position:x", o_x - 14.0, 0.12)
			enemy_lunge.tween_property(creature_sprite, "position:x", o_x, 0.12)

		await get_tree().create_timer(0.15).timeout

		await play_enemy_attack_animation(enemy_name)
		_apply_damage_to_player(10)

func _apply_damage_to_player(enemy_damage: int) -> void:
	if player_sprite:
		var player_flash = create_tween()
		player_flash.tween_property(player_sprite, "modulate", Color(2.2, 0.4, 0.4, 1), 0.1)
		player_flash.tween_property(player_sprite, "modulate", Color(1, 1, 1, 1), 0.1)
		var player_shake = create_tween()
		var p_x = player_sprite.position.x
		player_shake.tween_property(player_sprite, "position:x", p_x - 4, 0.05)
		player_shake.tween_property(player_sprite, "position:x", p_x + 4, 0.05)
		player_shake.tween_property(player_sprite, "position:x", p_x, 0.05)

	player_hp = max(0, player_hp - enemy_damage)
	update_hp_labels()

	var gs = get_node_or_null("/root/GameState")
	if gs and gs.telemetry:
		gs.telemetry.record_hp(player_hp, player_max_hp)

	if dialogue_label:
		dialogue_label.text = "Player took " + str(enemy_damage) + " damage!"

	await get_tree().create_timer(1.0).timeout

	if player_hp <= 0:
		if dialogue_label:
			dialogue_label.text = "Player blacked out!"
		if player_sprite:
			var player_faint = create_tween()
			player_faint.tween_property(player_sprite, "modulate:a", 0.0, 0.8)
		if gs and gs.telemetry:
			gs.telemetry.record_battle_end(false)
		await get_tree().create_timer(1.8).timeout
		return_to_world()
		return

	show_main_menu()

func _on_catch_button_pressed() -> void:
	if current_state != BattleState.MENU:
		return
	execute_catch()

func execute_catch() -> void:
	current_state = BattleState.BUSY
	if action_menu:
		action_menu.visible = false
	if moves_menu:
		moves_menu.visible = false
	
	if dialogue_label:
		dialogue_label.visible = true
		dialogue_label.offset_right = 304.0
		dialogue_label.text = "Player threw a Catch-Tube!"

	_ensure_catch_nodes()

	var empty_tex = _get_tube_texture("empty")
	if empty_tex and catch_tube:
		catch_tube.texture = empty_tex

	var tex_h: float = 468.0
	if catch_tube and catch_tube.texture:
		tex_h = float(catch_tube.texture.get_height())
	var tube_scale_factor: float = 28.0 / tex_h
	var tube_target_scale = Vector2(tube_scale_factor, tube_scale_factor)

	var start_pos = player_sprite.global_position if player_sprite else Vector2(83, 145)
	var target_pos = soldier_sprite.global_position if (is_soldier_battle and soldier_sprite) else creature_orig_pos
	if not is_soldier_battle and creature_sprite and creature_sprite.visible:
		target_pos = creature_sprite.global_position
	var landing_pos = Vector2(target_pos.x, 122.0)

	if catch_tube:
		catch_tube.global_position = start_pos
		catch_tube.scale = tube_target_scale
		catch_tube.rotation = 0.0
		catch_tube.modulate = Color(1, 1, 1, 1)
		catch_tube.visible = true

	# 1. Throw arc towards target
	var throw_duration: float = 0.52
	var throw_tween = create_tween()
	throw_tween.tween_property(catch_tube, "position:x", target_pos.x, throw_duration).set_trans(Tween.TRANS_LINEAR)
	
	var peak_y = min(start_pos.y, target_pos.y) - 34.0
	var y_tween = create_tween()
	y_tween.tween_property(catch_tube, "position:y", peak_y, throw_duration * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	y_tween.tween_property(catch_tube, "position:y", target_pos.y, throw_duration * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	var rot_tween = create_tween()
	rot_tween.tween_property(catch_tube, "rotation", TAU * 2.0, throw_duration)

	await throw_tween.finished
	if catch_tube:
		catch_tube.rotation = 0.0

	# --- REQUIREMENT 3: IF SOLDIER BATTLE, CLEAN DEFLECTION ---
	if is_soldier_battle:
		var gs = get_node_or_null("/root/GameState")
		if gs and gs.telemetry:
			gs.telemetry.record_catch("Soldier", false)
			gs.telemetry.record_turn()

		# Deflection sparks
		if catch_sparkles:
			catch_sparkles.global_position = target_pos
			catch_sparkles.restart()
			catch_sparkles.emitting = true

		# Tube bounces harmlessly off the soldier
		if catch_tube:
			var deflect_tween = create_tween()
			deflect_tween.tween_property(catch_tube, "position:x", target_pos.x - 28.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			deflect_tween.parallel().tween_property(catch_tube, "position:y", target_pos.y + 32.0, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			deflect_tween.parallel().tween_property(catch_tube, "modulate:a", 0.0, 0.3)
			await deflect_tween.finished
			catch_tube.visible = false
			catch_tube.modulate = Color(1, 1, 1, 1)

		if dialogue_label:
			dialogue_label.text = "You can't catch a human soldier!\nThe soldier deflects the Catch-Tube!"
		await get_tree().create_timer(1.6).timeout

		if dialogue_label:
			dialogue_label.text = "Soldier retaliates against the tube attack!"
		await get_tree().create_timer(0.8).timeout

		await execute_enemy_turn()
		return

	# --- WILD CREATURE CATCH SEQUENCE ---
	if dialogue_label:
		dialogue_label.text = "The wild " + enemy_name + " is being absorbed!"

	if creature_sprite:
		var flash_tween = create_tween()
		flash_tween.tween_property(creature_sprite, "modulate", Color(2.8, 2.8, 2.8, 1.0), 0.12)
		await flash_tween.finished

		var absorb_tween = create_tween()
		absorb_tween.tween_property(creature_sprite, "scale", Vector2(0.01, 0.01), 0.28)
		absorb_tween.parallel().tween_property(creature_sprite, "global_position", catch_tube.global_position, 0.28)
		absorb_tween.parallel().tween_property(creature_sprite, "modulate:a", 0.0, 0.28)
		await absorb_tween.finished
		creature_sprite.visible = false

	if catch_tube:
		var drop_tween = create_tween()
		drop_tween.tween_property(catch_tube, "position:y", landing_pos.y, 0.16).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		await drop_tween.finished
	await get_tree().create_timer(0.28).timeout

	var hp_ratio: float = float(enemy_hp) / float(enemy_max_hp)
	var catch_chance: float = 0.0
	var fail_shakes: int = 1

	if hp_ratio > 0.75:
		catch_chance = 0.10
		fail_shakes = 1
	elif hp_ratio > 0.25:
		catch_chance = 0.45 + (0.75 - hp_ratio) * 0.40
		fail_shakes = 2 if randf() < 0.60 else 1
	else:
		catch_chance = 0.85 + (0.25 - hp_ratio) * 0.45
		fail_shakes = 3 if randf() < 0.70 else 2

	var roll: float = randf()
	var is_success: bool = (roll < catch_chance)
	var total_shakes: int = 3 if is_success else fail_shakes

	for s in range(1, total_shakes + 1):
		if dialogue_label:
			dialogue_label.text = "..."
		if catch_tube:
			var wobble_tween = create_tween()
			wobble_tween.tween_property(catch_tube, "rotation", deg_to_rad(-16), 0.08).set_trans(Tween.TRANS_SINE)
			wobble_tween.tween_property(catch_tube, "rotation", deg_to_rad(16), 0.12).set_trans(Tween.TRANS_SINE)
			wobble_tween.tween_property(catch_tube, "rotation", deg_to_rad(-6), 0.08).set_trans(Tween.TRANS_SINE)
			wobble_tween.tween_property(catch_tube, "rotation", 0.0, 0.08).set_trans(Tween.TRANS_SINE)
			await wobble_tween.finished
		await get_tree().create_timer(0.35).timeout

	var gs_wild = get_node_or_null("/root/GameState")

	if is_success:
		if catch_tube:
			var click_tween = create_tween()
			click_tween.tween_property(catch_tube, "scale", tube_target_scale * Vector2(1.25, 0.75), 0.08)
			click_tween.tween_property(catch_tube, "scale", tube_target_scale, 0.08)
			await click_tween.finished

			var elem_tex = _get_tube_texture(enemy_name)
			if elem_tex:
				catch_tube.texture = elem_tex

			if catch_sparkles:
				catch_sparkles.global_position = catch_tube.global_position
				catch_sparkles.restart()
				catch_sparkles.emitting = true

			var glow_tween = create_tween()
			glow_tween.tween_property(catch_tube, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.12)
			glow_tween.tween_property(catch_tube, "modulate", Color(1, 1, 1, 1), 0.2)
			await glow_tween.finished

		var elem_name: String = "Creature"
		for k in CREATURE_ELEMENT_NAME.keys():
			if k.to_lower() == enemy_name.to_lower():
				elem_name = CREATURE_ELEMENT_NAME[k]
				break

		if dialogue_label:
			dialogue_label.text = "Gotcha! Wild %s was caught in the %s Tube!" % [enemy_name, elem_name]

		if gs_wild:
			if gs_wild.has_method("add_caught_creature"):
				gs_wild.add_caught_creature(enemy_name, elem_name, enemy_hp, enemy_max_hp)
			if gs_wild.telemetry:
				gs_wild.telemetry.record_catch(enemy_name, true)
				gs_wild.telemetry.record_battle_end(true)

		await get_tree().create_timer(2.2).timeout
		return_to_world()
	else:
		if catch_tube:
			var pop_tween = create_tween()
			pop_tween.tween_property(catch_tube, "scale", tube_target_scale * 1.5, 0.09)
			pop_tween.parallel().tween_property(catch_tube, "position:y", catch_tube.position.y - 12.0, 0.09)
			pop_tween.parallel().tween_property(catch_tube, "modulate:a", 0.0, 0.12)
			await pop_tween.finished
			catch_tube.visible = false

		if creature_sprite:
			creature_sprite.global_position = landing_pos
			creature_sprite.scale = Vector2(0.05, 0.05)
			creature_sprite.modulate = Color(2.8, 2.8, 2.8, 1.0)
			creature_sprite.visible = true
			var respawn_tween = create_tween()
			respawn_tween.tween_property(creature_sprite, "scale", creature_orig_scale, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			respawn_tween.parallel().tween_property(creature_sprite, "global_position", creature_orig_pos, 0.22)
			respawn_tween.parallel().tween_property(creature_sprite, "modulate", Color(1, 1, 1, 1), 0.25)
			await respawn_tween.finished

		if gs_wild and gs_wild.telemetry:
			gs_wild.telemetry.record_catch(enemy_name, false)
			gs_wild.telemetry.record_turn()

		if dialogue_label:
			dialogue_label.text = "Oh no! The wild " + enemy_name + " broke free!"
		await get_tree().create_timer(0.9).timeout

		await execute_enemy_turn()

func _ensure_catch_nodes() -> void:
	if catch_tube == null:
		if has_node("CatchTube"):
			catch_tube = $CatchTube
		else:
			catch_tube = Sprite2D.new()
			catch_tube.name = "CatchTube"
			catch_tube.z_index = 4
			catch_tube.visible = false
			add_child(catch_tube)

	if catch_sparkles == null:
		if has_node("CatchSparkles"):
			catch_sparkles = $CatchSparkles
		else:
			catch_sparkles = CPUParticles2D.new()
			catch_sparkles.name = "CatchSparkles"
			catch_sparkles.z_index = 6
			catch_sparkles.emitting = false
			catch_sparkles.amount = 16
			catch_sparkles.lifetime = 0.6
			catch_sparkles.one_shot = true
			catch_sparkles.explosiveness = 0.9
			catch_sparkles.spread = 180.0
			catch_sparkles.gravity = Vector2(0, 35)
			catch_sparkles.initial_velocity_min = 35.0
			catch_sparkles.initial_velocity_max = 65.0
			catch_sparkles.scale_amount_min = 2.0
			catch_sparkles.scale_amount_max = 3.5
			catch_sparkles.color = Color(1, 0.88, 0.28, 1)
			add_child(catch_sparkles)

func _ensure_soldier_sprite() -> void:
	if soldier_sprite == null:
		if has_node("SoldierSprite"):
			soldier_sprite = $SoldierSprite
		else:
			soldier_sprite = AnimatedSprite2D.new()
			soldier_sprite.name = "SoldierSprite"
			soldier_sprite.position = Vector2(246, 105)
			soldier_sprite.scale = Vector2(0.42, 0.42)
			soldier_sprite.visible = false
			add_child(soldier_sprite)

	if soldier_sprite.sprite_frames == null:
		var paths = [
			"res://assets/soldier_frames.tres",
			"res://assets/characters/soldier/soldier_frames.tres"
		]
		for p in paths:
			if ResourceLoader.exists(p):
				soldier_sprite.sprite_frames = load(p)
				break

	if adaptation_banner == null and has_node("CanvasLayer/AdaptationBanner"):
		adaptation_banner = $CanvasLayer/AdaptationBanner
	if banner_label == null and has_node("CanvasLayer/AdaptationBanner/BannerLabel"):
		banner_label = $CanvasLayer/AdaptationBanner/BannerLabel

func _get_tube_texture(tube_key: String) -> Texture2D:
	if _cached_tube_textures.has(tube_key):
		return _cached_tube_textures[tube_key]

	var path: String = TUBE_TEXTURES.get(tube_key, "")
	if path == "":
		for k in TUBE_TEXTURES.keys():
			if k.to_lower() == tube_key.to_lower():
				path = TUBE_TEXTURES[k]
				break

	if path != "" and ResourceLoader.exists(path):
		var tex = load(path)
		if tex:
			_cached_tube_textures[tube_key] = tex
			return tex

	# Fallback: direct load from PNG on disk
	if path != "":
		var abs_path = ProjectSettings.globalize_path(path)
		var img: Image = Image.load_from_file(abs_path)
		if img == null or img.is_empty():
			img = Image.load_from_file(path)
		if img and not img.is_empty():
			var tex = ImageTexture.create_from_image(img)
			_cached_tube_textures[tube_key] = tex
			return tex

	# Fallback: slice from catch-tubes.png dynamically
	var master_path = ProjectSettings.globalize_path("res://assets/catch-tubes.png")
	var master_img: Image = Image.load_from_file(master_path)
	if master_img == null or master_img.is_empty():
		master_img = Image.load_from_file("res://assets/catch-tubes.png")
	if master_img and not master_img.is_empty():
		var rect := Rect2i(1453, 229, 213, 468)
		var lk = tube_key.to_lower()
		if "water" in lk or "aqufin" in lk:
			rect = Rect2i(91, 229, 211, 468)
		elif "earth" in lk or "terron" in lk:
			rect = Rect2i(424, 229, 210, 468)
		elif "fire" in lk or "amberfox" in lk:
			rect = Rect2i(777, 229, 211, 468)
		elif "air" in lk or "zephyrin" in lk:
			rect = Rect2i(1119, 229, 211, 468)
		elif "empty" in lk or "clear" in lk:
			rect = Rect2i(1453, 229, 213, 468)

		var sub_img = master_img.get_region(rect)
		if sub_img and not sub_img.is_empty():
			var tex = ImageTexture.create_from_image(sub_img)
			_cached_tube_textures[tube_key] = tex
			return tex

	return null

func play_enemy_attack_animation(c_name: String) -> void:
	var lookup_name = c_name
	for k in ENEMY_ATTACK_DATA.keys():
		if k.to_lower() == c_name.to_lower():
			lookup_name = k
			break
	
	var data: Dictionary = ENEMY_ATTACK_DATA.get(lookup_name, ENEMY_ATTACK_DATA["Amberfox"])
	var fx_node: AnimatedSprite2D = enemy_attack_effect if enemy_attack_effect else attack_effect
	if not fx_node or not player_sprite:
		await get_tree().create_timer(0.3).timeout
		return

	var frames_res: SpriteFrames = _get_or_create_enemy_frames(lookup_name)
	if frames_res and frames_res.has_animation(data["anim"]):
		fx_node.sprite_frames = frames_res
		fx_node.animation = data["anim"]
		fx_node.flip_h = data.get("flip_h", false)
		fx_node.global_position = player_sprite.global_position + data["offset"]
		fx_node.scale = data["scale"]
		fx_node.frame = 0
		fx_node.visible = true
		fx_node.play(data["anim"])
		var play_time: float = data.get("duration", 0.75)
		await get_tree().create_timer(play_time).timeout
		fx_node.visible = false
		fx_node.stop()
		fx_node.flip_h = false
		return
	
	await get_tree().create_timer(0.3).timeout

func _get_or_create_player_attack_frames() -> SpriteFrames:
	if _cached_player_frames != null:
		return _cached_player_frames
	
	const TRES_PATH = "res://assets/effects/flame_blast_frames.tres"
	if ResourceLoader.exists(TRES_PATH):
		var res = load(TRES_PATH) as SpriteFrames
		if res and res.has_animation("flame_blast") and res.get_frame_count("flame_blast") > 0:
			var t = res.get_frame_texture("flame_blast", 0)
			if t != null and t.get_width() > 0:
				_cached_player_frames = res
				return res
	
	var sf = SpriteFrames.new()
	sf.add_animation("flame_blast")
	sf.set_animation_speed("flame_blast", 10.0)
	sf.set_animation_loop("flame_blast", false)
	for i in range(5):
		var p = "res://assets/effects/flame_blast/frame_%d.png" % i
		var abs_p = ProjectSettings.globalize_path(p)
		var img: Image = Image.load_from_file(abs_p)
		if img == null or img.is_empty():
			img = Image.load_from_file(p)
		if img != null and not img.is_empty():
			sf.add_frame("flame_blast", ImageTexture.create_from_image(img))
	
	_cached_player_frames = sf
	return sf

func _get_or_create_enemy_frames(c_name: String) -> SpriteFrames:
	var lookup_name = "Amberfox"
	for k in ENEMY_ATTACK_DATA.keys():
		if k.to_lower() == c_name.to_lower():
			lookup_name = k
			break
	
	if _cached_enemy_frames.has(lookup_name):
		return _cached_enemy_frames[lookup_name]
	
	var data: Dictionary = ENEMY_ATTACK_DATA.get(lookup_name, ENEMY_ATTACK_DATA["Amberfox"])
	var anim_name: String = data["anim"]
	var frames_path: String = data["frames_path"]
	
	if ResourceLoader.exists(frames_path):
		var res = load(frames_path) as SpriteFrames
		if res and res.has_animation(anim_name) and res.get_frame_count(anim_name) > 0:
			var first_tex = res.get_frame_texture(anim_name, 0)
			if first_tex != null and first_tex.get_width() > 0:
				_cached_enemy_frames[lookup_name] = res
				print("[Battle] Loaded attack frames for %s from resource (%d frames)" % [lookup_name, res.get_frame_count(anim_name)])
				return res
	
	var sf = SpriteFrames.new()
	sf.add_animation(anim_name)
	var fps: float = data.get("fps", 10.0)
	sf.set_animation_speed(anim_name, fps)
	sf.set_animation_loop(anim_name, false)
	
	var dir_path: String = data.get("dir_path", "")
	var frame_count: int = data.get("frame_count", 0)
	
	for i in range(frame_count):
		var res_path = "%s/frame_%d.png" % [dir_path, i]
		var abs_path = ProjectSettings.globalize_path(res_path)
		var img: Image = Image.load_from_file(abs_path)
		if img == null or img.is_empty():
			img = Image.load_from_file(res_path)
		if img == null or img.is_empty():
			var fallback_img = Image.new()
			var err = fallback_img.load(abs_path)
			if err == OK and not fallback_img.is_empty():
				img = fallback_img
			else:
				err = fallback_img.load(res_path)
				if err == OK and not fallback_img.is_empty():
					img = fallback_img
		
		if img != null and not img.is_empty():
			var tex = ImageTexture.create_from_image(img)
			sf.add_frame(anim_name, tex)
	
	if sf.get_frame_count(anim_name) > 0:
		_cached_enemy_frames[lookup_name] = sf
		print("[Battle] Dynamically built attack frames for %s (%d frames)" % [lookup_name, sf.get_frame_count(anim_name)])
		return sf
	
	push_error("[Battle] Failed to load any attack frames for creature: %s" % c_name)
	return null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if current_state == BattleState.MOVES:
				show_main_menu()
			elif current_state == BattleState.MENU:
				_on_run_button_pressed()

func return_to_world() -> void:
	current_state = BattleState.FINISHED
	print("Returning to overworld...")
	get_tree().change_scene_to_file("res://scenes/world.tscn")
