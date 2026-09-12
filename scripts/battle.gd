extends Node2D

## Battle Scene Controller
## Handles authentic GBA-style turn-based combat, creature animations, health bars, and docked menus.

@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var enemy_spawns: Array[Marker2D] = [
	$EnemySpawn1,
	$EnemySpawn2,
	$EnemySpawn3,
	$EnemySpawn4
]
@onready var creature_sprite: Sprite2D = $CreatureSprite
@onready var player_sprite: AnimatedSprite2D = $PlayerSprite
@onready var attack_effect: AnimatedSprite2D = $AttackEffect
@onready var enemy_attack_effect: AnimatedSprite2D = $EnemyAttackEffect if has_node("EnemyAttackEffect") else $AttackEffect

@onready var enemy_name_label: Label = $CanvasLayer/EnemyStatusBox/VBox/TopRow/EnemyNameLabel
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

@onready var catch_tube: Sprite2D = $CatchTube if has_node("CatchTube") else null
@onready var catch_sparkles: CPUParticles2D = $CatchSparkles if has_node("CatchSparkles") else null

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
	"Air": "res://assets/tubes/tube_air.png",
	"Red": "res://assets/tubes/tube_fire.png",
	"Blue": "res://assets/tubes/tube_water.png",
	"Brown": "res://assets/tubes/tube_earth.png",
	"Orange": "res://assets/tubes/tube_earth.png",
	"White": "res://assets/tubes/tube_air.png"
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

	if has_node("/root/GameState"):
		var gs = get_node("/root/GameState")
		if gs.encounter_creature != "":
			enemy_name = gs.encounter_creature

	if enemy_name_label:
		enemy_name_label.text = enemy_name

	if enemy_health_bar:
		enemy_health_bar.setup(enemy_hp, enemy_max_hp)
	if player_health_bar:
		player_health_bar.setup(player_hp, player_max_hp)

	update_hp_labels()
	spawn_creature(enemy_name)

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
		var e_frames = _get_or_create_enemy_frames(enemy_name)
		if e_frames:
			enemy_attack_effect.sprite_frames = e_frames

	if fight_button and catch_button and run_button:
		fight_button.focus_neighbor_top = run_button.get_path()
		fight_button.focus_neighbor_bottom = catch_button.get_path()
		catch_button.focus_neighbor_top = fight_button.get_path()
		catch_button.focus_neighbor_bottom = run_button.get_path()
		run_button.focus_neighbor_top = catch_button.get_path()
		run_button.focus_neighbor_bottom = fight_button.get_path()

	show_main_menu("A wild " + enemy_name + " appeared!\nWhat will Player do?")

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
	var nerfed_damage: int = randi_range(12, 14)
	execute_attack("Flame Blast", nerfed_damage)

func execute_attack(move_name: String, damage: int) -> void:
	current_state = BattleState.BUSY
	if moves_menu:
		moves_menu.visible = false
	if action_menu:
		action_menu.visible = false
	
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

	# Play attack animation directly over target creature
	if attack_effect and creature_sprite:
		var fb_frames = _get_or_create_player_attack_frames()
		if fb_frames:
			attack_effect.sprite_frames = fb_frames
		attack_effect.flip_h = false
		attack_effect.global_position = creature_sprite.global_position
		attack_effect.scale = Vector2(0.42, 0.42)
		attack_effect.frame = 0
		attack_effect.visible = true
		attack_effect.play("flame_blast")
	await get_tree().create_timer(0.5).timeout
	if attack_effect:
		attack_effect.visible = false
		attack_effect.stop()
	
	# Enemy creature hit flash and shake
	if creature_sprite:
		var flash_tween = create_tween()
		var o_pos = creature_sprite.position
		flash_tween.tween_property(creature_sprite, "modulate", Color(2.2, 0.4, 0.4, 1), 0.1)
		flash_tween.tween_property(creature_sprite, "modulate", Color(1, 1, 1, 1), 0.1)
		var shake = create_tween()
		shake.tween_property(creature_sprite, "position:x", o_pos.x + 5, 0.05)
		shake.tween_property(creature_sprite, "position:x", o_pos.x - 5, 0.05)
		shake.tween_property(creature_sprite, "position:x", o_pos.x, 0.05)

	# Apply damage and update health bar with color transitions
	enemy_hp = max(0, enemy_hp - damage)
	update_hp_labels()

	await get_tree().create_timer(0.7).timeout
	
	if enemy_hp <= 0:
		# Victory flow
		if dialogue_label:
			dialogue_label.text = "Wild " + enemy_name + " fainted!\nPlayer won the battle!"
		if creature_sprite:
			var faint_tween = create_tween()
			faint_tween.tween_property(creature_sprite, "modulate:a", 0.0, 0.8)
			faint_tween.parallel().tween_property(creature_sprite, "position:y", creature_sprite.position.y + 20.0, 0.8)
		await get_tree().create_timer(1.8).timeout
		return_to_world()
		return

	# Enemy Retaliation
	await execute_enemy_turn()

func execute_enemy_turn() -> void:
	if dialogue_label:
		dialogue_label.text = "Wild " + enemy_name + " attacks!"
	await get_tree().create_timer(0.6).timeout

	if creature_sprite:
		var enemy_lunge = create_tween()
		var o_x = creature_sprite.position.x
		enemy_lunge.tween_property(creature_sprite, "position:x", o_x - 14.0, 0.12)
		enemy_lunge.tween_property(creature_sprite, "position:x", o_x, 0.12)

	await get_tree().create_timer(0.15).timeout

	# Play creature's attack animation directly on the player
	await play_enemy_attack_animation(enemy_name)

	if player_sprite:
		var player_flash = create_tween()
		player_flash.tween_property(player_sprite, "modulate", Color(2.2, 0.4, 0.4, 1), 0.1)
		player_flash.tween_property(player_sprite, "modulate", Color(1, 1, 1, 1), 0.1)
		var player_shake = create_tween()
		var p_x = player_sprite.position.x
		player_shake.tween_property(player_sprite, "position:x", p_x - 4, 0.05)
		player_shake.tween_property(player_sprite, "position:x", p_x + 4, 0.05)
		player_shake.tween_property(player_sprite, "position:x", p_x, 0.05)

	var enemy_damage = 10
	player_hp = max(0, player_hp - enemy_damage)
	update_hp_labels()
	if dialogue_label:
		dialogue_label.text = "Player took " + str(enemy_damage) + " damage!"

	await get_tree().create_timer(1.0).timeout

	if player_hp <= 0:
		if dialogue_label:
			dialogue_label.text = "Player blacked out!"
		if player_sprite:
			var player_faint = create_tween()
			player_faint.tween_property(player_sprite, "modulate:a", 0.0, 0.8)
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
	var target_pos = creature_orig_pos
	if creature_sprite and creature_sprite.visible:
		target_pos = creature_sprite.global_position
	var landing_pos = Vector2(target_pos.x, 122.0)

	if catch_tube:
		catch_tube.global_position = start_pos
		catch_tube.scale = tube_target_scale
		catch_tube.rotation = 0.0
		catch_tube.modulate = Color(1, 1, 1, 1)
		catch_tube.visible = true

	# 1. Throw arc towards target creature
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

	# 2. Creature absorbs / transforms into energy and enters the tube
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

	# 3. Tube drops to platform oval and settles with a bounce
	if catch_tube:
		var drop_tween = create_tween()
		drop_tween.tween_property(catch_tube, "position:y", landing_pos.y, 0.16).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		await drop_tween.finished
	await get_tree().create_timer(0.28).timeout

	# 4. Catch calculation scaling inversely with remaining HP
	var hp_ratio: float = float(enemy_hp) / float(enemy_max_hp)
	var catch_chance: float = 0.0
	var fail_shakes: int = 1

	if hp_ratio > 0.75:
		# High HP (Green, > 75%): very low catch rate (~10%)
		catch_chance = 0.10
		fail_shakes = 1
	elif hp_ratio > 0.25:
		# Medium HP (Yellow, 26%-75%): moderate catch rate (~45%-65%)
		catch_chance = 0.45 + (0.75 - hp_ratio) * 0.40
		fail_shakes = 2 if randf() < 0.60 else 1
	else:
		# Critical low HP (Red, 1%-25%): high catch rate (~85%-95%)
		catch_chance = 0.85 + (0.25 - hp_ratio) * 0.45
		fail_shakes = 3 if randf() < 0.70 else 2

	var roll: float = randf()
	var is_success: bool = (roll < catch_chance)
	var total_shakes: int = 3 if is_success else fail_shakes

	# 5. GBA-style wobble shakes (1 to 3 shakes)
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

	if is_success:
		# CATCH SUCCESS SEQUENCE
		# Click and lock animation
		if catch_tube:
			var click_tween = create_tween()
			click_tween.tween_property(catch_tube, "scale", tube_target_scale * Vector2(1.25, 0.75), 0.08)
			click_tween.tween_property(catch_tube, "scale", tube_target_scale, 0.08)
			await click_tween.finished

			# Turn to creature's elemental color tube
			var elem_tex = _get_tube_texture(enemy_name)
			if elem_tex:
				catch_tube.texture = elem_tex

			# Sparkling star burst & brightness pulse
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

		# Save to GameState
		if has_node("/root/GameState"):
			var gs = get_node("/root/GameState")
			if gs.has_method("add_caught_creature"):
				gs.add_caught_creature(enemy_name, elem_name, enemy_hp, enemy_max_hp)
			elif gs.get("caught_creatures") != null:
				gs.caught_creatures.append({"name": enemy_name, "tube": elem_name, "hp": enemy_hp, "max_hp": enemy_max_hp})

		await get_tree().create_timer(2.2).timeout
		return_to_world()
	else:
		# BREAKOUT SEQUENCE
		# Tube pops open and bursts away
		if catch_tube:
			var pop_tween = create_tween()
			pop_tween.tween_property(catch_tube, "scale", tube_target_scale * 1.5, 0.09)
			pop_tween.parallel().tween_property(catch_tube, "position:y", catch_tube.position.y - 12.0, 0.09)
			pop_tween.parallel().tween_property(catch_tube, "modulate:a", 0.0, 0.12)
			await pop_tween.finished
			catch_tube.visible = false

		# Creature bursts out from the tube landing position back to its stance
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

		if dialogue_label:
			dialogue_label.text = "Oh no! The wild " + enemy_name + " broke free!"
		await get_tree().create_timer(0.9).timeout

		# Wild creature retaliates
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
		var rect := Rect2i(1453, 229, 213, 468) # default empty
		var lk = tube_key.to_lower()
		if "water" in lk or "aqufin" in lk or "blue" in lk:
			rect = Rect2i(91, 229, 211, 468)
		elif "earth" in lk or "terron" in lk or "brown" in lk or "orange" in lk:
			rect = Rect2i(424, 229, 210, 468)
		elif "fire" in lk or "amberfox" in lk or "red" in lk:
			rect = Rect2i(777, 229, 211, 468)
		elif "air" in lk or "zephyrin" in lk or "white" in lk:
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
	
	# Attempt 1: Try loading pre-built .tres resource
	if ResourceLoader.exists(frames_path):
		var res = load(frames_path) as SpriteFrames
		if res and res.has_animation(anim_name) and res.get_frame_count(anim_name) > 0:
			var first_tex = res.get_frame_texture(anim_name, 0)
			if first_tex != null and first_tex.get_width() > 0:
				_cached_enemy_frames[lookup_name] = res
				print("[Battle] Loaded attack frames for %s from resource (%d frames)" % [lookup_name, res.get_frame_count(anim_name)])
				return res
	
	# Attempt 2: Build SpriteFrames dynamically from PNGs using Image.load_from_file
	# This guarantees textures are loaded in any runtime environment even without Godot's .import cache
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
		else:
			push_warning("[Battle] Could not load attack frame: %s" % res_path)
	
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
