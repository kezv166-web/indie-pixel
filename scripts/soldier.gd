extends CharacterBody2D

## Top-Down Soldier NPC Controller
## Handles patrolling between waypoints along roads/paths, playing directional
## walk/idle animations, obstacle collision with trees and buildings, and triggering
## authentic GBA-style battle encounters upon player collision or interaction.

enum SoldierState {
	PATROLLING,
	WAITING,
	ALERTED,
	BATTLING
}

@export var soldier_id: String = "soldier_1"
@export var assigned_creature: String = "Terron"
@export var move_speed: float = 40.0
@export var patrol_points: Array[Vector2] = []
@export var patrol_distance: float = 80.0
@export var patrol_axis: Vector2 = Vector2.RIGHT
@export var wait_time_at_waypoint: float = 1.6
@export var post_battle_cooldown: float = 6.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var touch_area: Area2D = $TouchArea if has_node("TouchArea") else null
@onready var interaction_area: Area2D = $InteractionArea if has_node("InteractionArea") else null
@onready var alert_balloon: Node2D = $AlertBalloon if has_node("AlertBalloon") else null
@onready var dialogue_box: PanelContainer = $DialogueBox if has_node("DialogueBox") else null
@onready var dialogue_label: Label = $DialogueBox/MarginContainer/DialogueLabel if has_node("DialogueBox/MarginContainer/DialogueLabel") else null

var current_state: SoldierState = SoldierState.PATROLLING
var current_waypoint_index: int = 0
var wait_timer: float = 0.0
var cooldown_timer: float = 0.0
var facing_direction: Vector2 = Vector2.DOWN
var player_in_range: CharacterBody2D = null
var _dialogue_tween: Tween = null
var _alert_tween: Tween = null

func _ready() -> void:
	# Proper collision layer and mask
	# Layer 3 (bit value 4) for NPC, Mask 1 (World/Trees/Buildings) + 2 (Player)
	collision_layer = 4
	collision_mask = 3
	
	_setup_input_actions()
	_ensure_sprite_frames()
	_setup_waypoints()
	_setup_signals()
	
	if alert_balloon:
		alert_balloon.visible = false
	if dialogue_box:
		dialogue_box.visible = false
	
	# Cooldown / defeat check on returning from battle
	if has_node("/root/GameState"):
		var gs = get_node("/root/GameState")
		if "last_battled_soldier" in gs and gs.last_battled_soldier == soldier_id:
			cooldown_timer = post_battle_cooldown
			gs.last_battled_soldier = ""
			print("[Soldier %s] Returned from battle, cooldown active (%.1fs)." % [soldier_id, cooldown_timer])

func _setup_input_actions() -> void:
	if not InputMap.has_action("interact"):
		InputMap.add_action("interact")
		for key in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_E]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event("interact", ev)
			var ev_log := InputEventKey.new()
			ev_log.keycode = key
			InputMap.action_add_event("interact", ev_log)

func _ensure_sprite_frames() -> void:
	if not animated_sprite:
		return
	
	var frames_valid: bool = false
	if animated_sprite.sprite_frames != null:
		if animated_sprite.sprite_frames.has_animation("idle_down") and animated_sprite.sprite_frames.get_frame_count("idle_down") > 0:
			var t = animated_sprite.sprite_frames.get_frame_texture("idle_down", 0)
			if t != null and t.get_width() > 0:
				frames_valid = true
	
	if not frames_valid:
		var paths = [
			"res://assets/characters/soldier/soldier_frames.tres",
			"res://assets/soldier_frames.tres"
		]
		for p in paths:
			if ResourceLoader.exists(p):
				var res = load(p) as SpriteFrames
				if res != null and res.has_animation("idle_down") and res.get_frame_count("idle_down") > 0:
					var t = res.get_frame_texture("idle_down", 0)
					if t != null and t.get_width() > 0:
						animated_sprite.sprite_frames = res
						frames_valid = true
						print("[Soldier %s] Loaded SpriteFrames from %s" % [soldier_id, p])
						break
	
	if not frames_valid:
		var dyn_frames = _build_dynamic_sprite_frames()
		if dyn_frames != null:
			animated_sprite.sprite_frames = dyn_frames
			frames_valid = true
			print("[Soldier %s] Built dynamic SpriteFrames from assets/soldier.png" % soldier_id)
	
	if animated_sprite.sprite_frames != null:
		_set_idle_animation("down")

func _build_dynamic_sprite_frames() -> SpriteFrames:
	var png_path = "res://assets/soldier.png"
	var abs_path = ProjectSettings.globalize_path(png_path)
	var img: Image = Image.load_from_file(abs_path)
	if img == null or img.is_empty():
		img = Image.load_from_file(png_path)
	if img == null or img.is_empty():
		var fallback_img = Image.new()
		if fallback_img.load(abs_path) == OK and not fallback_img.is_empty():
			img = fallback_img
		elif fallback_img.load(png_path) == OK and not fallback_img.is_empty():
			img = fallback_img
	
	if img == null or img.is_empty():
		push_error("[Soldier] Could not load %s" % png_path)
		return null
	
	var sf = SpriteFrames.new()
	var col_widths = [96, 96, 96, 97]
	var col_x = [0, 96, 192, 288]
	var dir_names = ["down", "left", "right", "up"]
	
	for i in range(4):
		var d_name = dir_names[i]
		var w = col_widths[i]
		var x = col_x[i]
		
		var rect1 = Rect2i(x, 20, w, 112)
		var rect2 = Rect2i(x, 132, w, 112)
		
		var sub1 = img.get_region(rect1)
		var sub2 = img.get_region(rect2)
		
		var tex1 = ImageTexture.create_from_image(sub1)
		var tex2 = ImageTexture.create_from_image(sub2)
		
		var idle_anim = "idle_" + d_name
		sf.add_animation(idle_anim)
		sf.set_animation_speed(idle_anim, 1.0)
		sf.set_animation_loop(idle_anim, true)
		sf.add_frame(idle_anim, tex1)
		
		var walk_anim = "walk_" + d_name
		sf.add_animation(walk_anim)
		sf.set_animation_speed(walk_anim, 5.0)
		sf.set_animation_loop(walk_anim, true)
		sf.add_frame(walk_anim, tex1)
		sf.add_frame(walk_anim, tex2)
	
	return sf

func _setup_waypoints() -> void:
	if patrol_points.is_empty():
		var p1: Vector2 = global_position
		var p2: Vector2 = global_position + (patrol_axis.normalized() * patrol_distance)
		patrol_points.append(p1)
		patrol_points.append(p2)
		current_waypoint_index = 1
	else:
		current_waypoint_index = 0

func _setup_signals() -> void:
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_body_entered)
		interaction_area.body_exited.connect(_on_interaction_area_body_exited)
	if touch_area:
		touch_area.body_entered.connect(_on_touch_area_body_entered)

func is_defeated() -> bool:
	if has_node("/root/GameState"):
		var gs = get_node("/root/GameState")
		if "defeated_soldiers" in gs and gs.defeated_soldiers.has(soldier_id):
			return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range != null and event.is_pressed() and not event.is_echo():
		if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
			_handle_player_interaction(player_in_range)
		elif event is InputEventKey and (event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_E] or event.physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_E]):
			_handle_player_interaction(player_in_range)

func get_soldier_element() -> String:
	var c_low = assigned_creature.to_lower()
	if "amber" in c_low or "fire" in c_low:
		return "Fire"
	elif "aqu" in c_low or "water" in c_low:
		return "Water"
	elif "terr" in c_low or "earth" in c_low:
		return "Earth"
	elif "zephyr" in c_low or "air" in c_low:
		return "Air"
	elif "adapt" in c_low or "nexus" in c_low:
		return "Adaptive"
	return "Earth"

func _handle_player_interaction(player: CharacterBody2D) -> void:
	if current_state == SoldierState.ALERTED or current_state == SoldierState.BATTLING:
		return
	if is_defeated():
		var elem_label = get_soldier_element()
		if elem_label == "Adaptive":
			_show_temporary_dialogue("You fought honorably, recruit!\nThe Nexus tactical network has recorded your skill.", 2.2)
		else:
			_show_temporary_dialogue("You fought honorably, recruit!\nMay the power of %s protect you." % elem_label, 2.2)
	elif cooldown_timer > 0.0:
		_show_temporary_dialogue("Stay sharp, citizen!\nOur elemental guard is on high alert.", 2.0)
	else:
		trigger_encounter(player)

func on_player_touched(player: CharacterBody2D) -> void:
	if current_state == SoldierState.ALERTED or current_state == SoldierState.BATTLING:
		return
	if is_defeated() or cooldown_timer > 0.0:
		return
	trigger_encounter(player)

func _physics_process(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
	
	if current_state == SoldierState.BATTLING or current_state == SoldierState.ALERTED:
		return
	
	# Fallback check for manual interaction key press
	if player_in_range != null:
		if _is_interact_just_pressed():
			_handle_player_interaction(player_in_range)
			return

	match current_state:
		SoldierState.PATROLLING:
			_process_patrol(delta)
		SoldierState.WAITING:
			_process_wait(delta)

func _process_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		_set_idle_animation(get_facing_direction_name())
		return
	
	var target: Vector2 = patrol_points[current_waypoint_index]
	var to_target: Vector2 = target - global_position
	var dist: float = to_target.length()
	
	if dist <= 4.0:
		# Waypoint reached
		global_position = target
		velocity = Vector2.ZERO
		current_state = SoldierState.WAITING
		wait_timer = wait_time_at_waypoint
		_set_idle_animation(get_facing_direction_name())
		return
	
	var move_dir: Vector2 = to_target.normalized()
	velocity = move_dir * move_speed
	_update_walk_animation(move_dir)
	
	var prev_pos = global_position
	move_and_slide()
	
	# Check physical collisions with player or obstacles
	var slide_count: int = get_slide_collision_count()
	for i in range(slide_count):
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider is CharacterBody2D and collider.name == "Player":
			on_player_touched(collider)
			return
		elif dist > 8.0 and global_position.distance_to(prev_pos) < 0.2:
			# Hit a solid obstacle/tree/building; skip to next waypoint or reverse
			current_waypoint_index = (current_waypoint_index + 1) % patrol_points.size()
			current_state = SoldierState.WAITING
			wait_timer = 0.8
			break

func _process_wait(delta: float) -> void:
	velocity = Vector2.ZERO
	_set_idle_animation(get_facing_direction_name())
	wait_timer -= delta
	if wait_timer <= 0.0:
		current_waypoint_index = (current_waypoint_index + 1) % patrol_points.size()
		current_state = SoldierState.PATROLLING

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == "Player":
		player_in_range = body

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null

func _on_touch_area_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == "Player":
		on_player_touched(body)

func _is_interact_just_pressed() -> bool:
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
		return true
	return false

func trigger_encounter(player: CharacterBody2D) -> void:
	if current_state == SoldierState.ALERTED or current_state == SoldierState.BATTLING:
		return
	if is_defeated() or cooldown_timer > 0.0:
		return
	
	current_state = SoldierState.ALERTED
	velocity = Vector2.ZERO
	
	# Stop and freeze player during dramatic cue
	if player:
		if "velocity" in player:
			player.velocity = Vector2.ZERO
		player.set_physics_process(false)
		if player.has_method("_update_idle_animation"):
			player._update_idle_animation()
	
	# Face each other
	var dir_to_player: Vector2 = (player.global_position - global_position).normalized()
	set_facing_direction(dir_to_player)
	if player and player.has_method("set_facing_direction"):
		player.set_facing_direction(-dir_to_player)
	
	# Show alert exclamation mark pop-up and dialogue cue
	var elem = get_soldier_element()
	_play_alert_effect()
	if elem == "Adaptive":
		_show_dialogue("Halt! Prepare to face Nexus Tactical power!")
	else:
		_show_dialogue("Halt! Prepare to face %s power!" % elem)
	
	# Short dramatic pause so alert is fully seen and felt
	await get_tree().create_timer(1.1).timeout
	
	# Set GameState parameters
	if has_node("/root/GameState"):
		var gs = get_node("/root/GameState")
		gs.player_return_position = player.global_position
		gs.encounter_creature = assigned_creature
		gs.last_battled_soldier = soldier_id
		gs.soldier_battle_active = true
		gs.soldier_assigned_element = elem
	
	current_state = SoldierState.BATTLING
	print("[Soldier %s] Engaging battle with %s (%s Power)!" % [soldier_id, assigned_creature, elem])
	get_tree().change_scene_to_file("res://scenes/battle/Battle.tscn")

func _play_alert_effect() -> void:
	if not alert_balloon:
		return
	alert_balloon.visible = true
	alert_balloon.scale = Vector2.ZERO
	if _alert_tween and _alert_tween.is_valid():
		_alert_tween.kill()
	_alert_tween = create_tween()
	_alert_tween.tween_property(alert_balloon, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_alert_tween.tween_property(alert_balloon, "scale", Vector2(1.0, 1.0), 0.1)

func _show_dialogue(text_content: String) -> void:
	if not dialogue_box or not dialogue_label:
		return
	dialogue_label.text = text_content
	dialogue_box.visible = true
	dialogue_box.modulate.a = 0.0
	if _dialogue_tween and _dialogue_tween.is_valid():
		_dialogue_tween.kill()
	_dialogue_tween = create_tween()
	_dialogue_tween.tween_property(dialogue_box, "modulate:a", 1.0, 0.2)

func _show_temporary_dialogue(text_content: String, duration: float) -> void:
	_show_dialogue(text_content)
	await get_tree().create_timer(duration).timeout
	if dialogue_box and current_state != SoldierState.ALERTED and current_state != SoldierState.BATTLING:
		if _dialogue_tween and _dialogue_tween.is_valid():
			_dialogue_tween.kill()
		_dialogue_tween = create_tween()
		_dialogue_tween.tween_property(dialogue_box, "modulate:a", 0.0, 0.2)
		await _dialogue_tween.finished
		if dialogue_box:
			dialogue_box.visible = false

func _update_walk_animation(move_dir: Vector2) -> void:
	if not animated_sprite:
		return
	var dir_name: String = ""
	if abs(move_dir.x) > abs(move_dir.y):
		dir_name = "right" if move_dir.x > 0.0 else "left"
		facing_direction = Vector2.RIGHT if move_dir.x > 0.0 else Vector2.LEFT
	else:
		dir_name = "down" if move_dir.y > 0.0 else "up"
		facing_direction = Vector2.DOWN if move_dir.y > 0.0 else Vector2.UP
	
	var anim_name: String = "walk_" + dir_name
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name or not animated_sprite.is_playing():
			animated_sprite.play(anim_name)

func _set_idle_animation(dir_name: String) -> void:
	if not animated_sprite:
		return
	var idle_name: String = "idle_" + dir_name
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(idle_name):
		if animated_sprite.animation != idle_name or not animated_sprite.is_playing():
			animated_sprite.play(idle_name)
	else:
		var walk_name: String = "walk_" + dir_name
		if animated_sprite.animation != walk_name or animated_sprite.is_playing() or animated_sprite.frame != 0:
			animated_sprite.animation = walk_name
			animated_sprite.stop()
			animated_sprite.frame = 0

func set_facing_direction(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	if abs(dir.x) > abs(dir.y):
		facing_direction = Vector2.RIGHT if dir.x > 0.0 else Vector2.LEFT
	else:
		facing_direction = Vector2.DOWN if dir.y > 0.0 else Vector2.UP
	_set_idle_animation(get_facing_direction_name())

func get_facing_direction_name() -> String:
	if abs(facing_direction.x) > abs(facing_direction.y):
		return "right" if facing_direction.x > 0.0 else "left"
	return "down" if facing_direction.y >= 0.0 else "up"
