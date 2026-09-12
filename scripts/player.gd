extends CharacterBody2D

## Top-Down GBA RPG Player Controller
## Handles 8-directional movement (Arrows + WASD), dominant-axis directional animations,
## idle stance retention, collisions, and camera smoothing.

@export var move_speed: float = 100.0
@export var acceleration: float = 800.0
@export var friction: float = 1000.0
@export var camera_zoom: Vector2 = Vector2(1.0, 1.0)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D

var facing_direction: Vector2 = Vector2.DOWN
var _step_distance_accumulator: float = 0.0
const STEP_DISTANCE_THRESHOLD: float = 16.0

func _ready() -> void:
	_setup_input_actions()
	if animated_sprite:
		animated_sprite.flip_h = false
		_set_idle_animation("down")
	if camera and camera_zoom != Vector2.ZERO:
		camera.zoom = camera_zoom
	
	# Restore position if returning from battle
	if has_node("/root/GameState"):
		var gs = get_node("/root/GameState")
		if gs.player_return_position != Vector2.ZERO:
			global_position = gs.player_return_position
			gs.player_return_position = Vector2.ZERO

func _physics_process(delta: float) -> void:
	var input_direction: Vector2 = _get_input_direction()
	
	if input_direction != Vector2.ZERO:
		input_direction = input_direction.normalized()
		velocity = velocity.move_toward(input_direction * move_speed, acceleration * delta)
		_update_animation(input_direction)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		if velocity.length() < 1.0:
			velocity = Vector2.ZERO
		_update_idle_animation()
	
	var pos_before: Vector2 = global_position
	move_and_slide()
	global_position.x = clampf(global_position.x, 8.0, 1664.0)
	global_position.y = clampf(global_position.y, 8.0, 933.0)
	
	# Check physical collisions with NPCs / Soldiers
	var slide_count: int = get_slide_collision_count()
	for i in range(slide_count):
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider and collider.has_method("on_player_touched"):
			collider.on_player_touched(self)
			break
	
	# Calculate step distance traversed
	var dist_moved: float = global_position.distance_to(pos_before)
	if dist_moved > 0.0:
		_step_distance_accumulator += dist_moved
		while _step_distance_accumulator >= STEP_DISTANCE_THRESHOLD:
			_step_distance_accumulator -= STEP_DISTANCE_THRESHOLD
			if has_node("/root/EncounterManager"):
				get_node("/root/EncounterManager").on_step_completed()

func _get_input_direction() -> Vector2:
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_dir == Vector2.ZERO:
		input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir == Vector2.ZERO:
		# Direct key press fallback checking both logical keycodes and physical keycodes
		var x: float = 0.0
		var y: float = 0.0
		if Input.is_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_LEFT):
			x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_RIGHT):
			x += 1.0
		if Input.is_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_UP):
			y -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_DOWN):
			y += 1.0
		input_dir = Vector2(x, y)
	return input_dir

func _setup_input_actions() -> void:
	var key_mappings: Dictionary = {
		"ui_left": [KEY_LEFT, KEY_A],
		"ui_right": [KEY_RIGHT, KEY_D],
		"ui_up": [KEY_UP, KEY_W],
		"ui_down": [KEY_DOWN, KEY_S],
		"move_left": [KEY_LEFT, KEY_A],
		"move_right": [KEY_RIGHT, KEY_D],
		"move_up": [KEY_UP, KEY_W],
		"move_down": [KEY_DOWN, KEY_S]
	}
	for action_name in key_mappings:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		for key_code in key_mappings[action_name]:
			# Register physical keycode event
			var ev_phys := InputEventKey.new()
			ev_phys.physical_keycode = key_code
			if not InputMap.action_has_event(action_name, ev_phys):
				InputMap.action_add_event(action_name, ev_phys)
			
			# Register logical keycode event
			var ev_key := InputEventKey.new()
			ev_key.keycode = key_code
			if not InputMap.action_has_event(action_name, ev_key):
				InputMap.action_add_event(action_name, ev_key)

func _update_animation(input_dir: Vector2) -> void:
	if not animated_sprite:
		return
		
	var dir_name: String = ""
	var abs_x: float = abs(input_dir.x)
	var abs_y: float = abs(input_dir.y)
	
	if is_equal_approx(abs_x, abs_y):
		# On diagonal input, preserve the current facing axis if it matches an input direction
		if facing_direction.x != 0.0 and sign(input_dir.x) == sign(facing_direction.x):
			dir_name = "right" if facing_direction.x > 0.0 else "left"
		elif facing_direction.y != 0.0 and sign(input_dir.y) == sign(facing_direction.y):
			dir_name = "down" if facing_direction.y > 0.0 else "up"
		else:
			# Default tie-breaker if starting from stationary or perpendicular
			if input_dir.y > 0.0:
				dir_name = "down"
				facing_direction = Vector2.DOWN
			elif input_dir.y < 0.0:
				dir_name = "up"
				facing_direction = Vector2.UP
			elif input_dir.x > 0.0:
				dir_name = "right"
				facing_direction = Vector2.RIGHT
			else:
				dir_name = "left"
				facing_direction = Vector2.LEFT
	elif abs_x > abs_y:
		if input_dir.x > 0.0:
			dir_name = "right"
			facing_direction = Vector2.RIGHT
		else:
			dir_name = "left"
			facing_direction = Vector2.LEFT
	else:
		if input_dir.y > 0.0:
			dir_name = "down"
			facing_direction = Vector2.DOWN
		else:
			dir_name = "up"
			facing_direction = Vector2.UP
	
	animated_sprite.flip_h = false
	var anim_name: String = "walk_" + dir_name
	if animated_sprite.animation != anim_name or not animated_sprite.is_playing():
		animated_sprite.play(anim_name)

func _update_idle_animation() -> void:
	if not animated_sprite:
		return
	var dir_name: String = get_facing_direction_name()
	_set_idle_animation(dir_name)

func _set_idle_animation(dir_name: String) -> void:
	if not animated_sprite:
		return
	animated_sprite.flip_h = false
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
	
	if animated_sprite:
		var dir_name: String = get_facing_direction_name()
		_set_idle_animation(dir_name)

func get_facing_direction_name() -> String:
	if abs(facing_direction.x) > abs(facing_direction.y):
		return "right" if facing_direction.x > 0.0 else "left"
	return "down" if facing_direction.y >= 0.0 else "up"
