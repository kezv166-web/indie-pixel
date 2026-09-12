extends Control

## GBA Pokemon-Style Dynamic Health Bar Component
## Displays the HP badge, background track, and dynamic color-shifting fill bar.

@onready var fill_bar: ProgressBar = $FillBar

const COLOR_100: Color = Color("#00e632")     # Full health (Green)
const COLOR_76_99: Color = Color("#94e600")   # High health (Light Green)
const COLOR_51_75: Color = Color("#f2e600")   # Medium health (Yellow)
const COLOR_26_50: Color = Color("#ff7300")   # Low health (Orange)
const COLOR_1_25: Color = Color("#ff1a1a")    # Critical health (Red)
const COLOR_0: Color = Color("#2c3038")       # Depleted / Fainted (Dark Gray)

var current_hp: int = 50
var max_hp: int = 50
var _tween: Tween

func _ready() -> void:
	if not fill_bar:
		fill_bar = get_node_or_null("FillBar")

func setup(p_current: int, p_max: int) -> void:
	if not fill_bar:
		fill_bar = get_node_or_null("FillBar")
	max_hp = max(1, p_max)
	current_hp = clamp(p_current, 0, max_hp)
	if fill_bar:
		fill_bar.max_value = max_hp
		fill_bar.value = current_hp
	_update_color(float(current_hp) / float(max_hp))

func set_hp(new_hp: int, animate: bool = true) -> void:
	if not fill_bar:
		fill_bar = get_node_or_null("FillBar")
	var target_hp: int = clamp(new_hp, 0, max_hp)
	current_hp = target_hp
	if not fill_bar:
		return
	
	if animate:
		if _tween and _tween.is_running():
			_tween.kill()
		_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_tween.tween_property(fill_bar, "value", float(target_hp), 0.6)
		_tween.parallel().tween_method(_update_color_from_value, fill_bar.value, float(target_hp), 0.6)
	else:
		fill_bar.value = target_hp
		_update_color(float(target_hp) / float(max_hp))

func _update_color_from_value(val: float) -> void:
	_update_color(val / float(max_hp))

func _update_color(ratio: float) -> void:
	if not fill_bar:
		return
	var c: Color
	if ratio >= 0.999:
		c = COLOR_100
	elif ratio >= 0.755:
		c = COLOR_76_99
	elif ratio >= 0.505:
		c = COLOR_51_75
	elif ratio >= 0.255:
		c = COLOR_26_50
	elif ratio > 0.001:
		c = COLOR_1_25
	else:
		c = COLOR_0

	var sb: StyleBoxFlat
	if fill_bar.has_theme_stylebox_override("fill"):
		var existing = fill_bar.get_theme_stylebox("fill")
		if existing is StyleBoxFlat:
			sb = existing.duplicate()
	if not sb:
		sb = StyleBoxFlat.new()
		sb.corner_radius_top_left = 2
		sb.corner_radius_top_right = 2
		sb.corner_radius_bottom_right = 2
		sb.corner_radius_bottom_left = 2
	sb.bg_color = c
	fill_bar.add_theme_stylebox_override("fill", sb)
