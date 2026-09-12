extends StaticBody2D

## Building Obstacle Collision System for Virbhadra City
## Solid rectangular collision constraints for all 25 buildings across town and Nexus Lab.
## Follows user-defined building boundaries from assets/Buildings.png.

const BUILDINGS: Array[Rect2] = [
	Rect2(Vector2(785.0, 0.0), Vector2(59.0, 53.0)),     # 1: north_house_1_red
	Rect2(Vector2(846.0, 0.0), Vector2(59.0, 53.0)),     # 2: north_house_2_red
	Rect2(Vector2(907.0, 0.0), Vector2(59.0, 53.0)),     # 3: north_house_3_blue
	Rect2(Vector2(725.0, 118.0), Vector2(57.0, 80.0)),   # 4: north_suburb_red
	Rect2(Vector2(784.0, 118.0), Vector2(58.0, 80.0)),   # 5: north_suburb_blue
	Rect2(Vector2(648.0, 145.0), Vector2(71.0, 102.0)),  # 6: north_civic_tower
	Rect2(Vector2(546.0, 234.0), Vector2(77.0, 74.0)),   # 7: avenue_house_blue_nw
	Rect2(Vector2(800.0, 234.0), Vector2(55.0, 63.0)),   # 8: avenue_house_red_north
	Rect2(Vector2(416.0, 271.0), Vector2(67.0, 69.0)),   # 9: west_house_red_top
	Rect2(Vector2(1429.0, 296.0), Vector2(161.0, 154.0)),# 10: nexus_lab_facility
	Rect2(Vector2(485.0, 308.0), Vector2(61.0, 70.0)),   # 11: avenue_house_red_mid1
	Rect2(Vector2(591.0, 313.0), Vector2(59.0, 65.0)),   # 12: avenue_house_red_mid2
	Rect2(Vector2(806.0, 322.0), Vector2(79.0, 81.0)),   # 13: center_pokecenter
	Rect2(Vector2(327.0, 334.0), Vector2(67.0, 74.0)),   # 14: west_house_blue_mid
	Rect2(Vector2(907.0, 384.0), Vector2(57.0, 67.0)),   # 15: center_house_red_cliff
	Rect2(Vector2(416.0, 409.0), Vector2(72.0, 109.0)),  # 16: commercial_grey_tower
	Rect2(Vector2(622.0, 418.0), Vector2(118.0, 101.0)), # 17: industrial_complex
	Rect2(Vector2(357.0, 440.0), Vector2(59.0, 78.0)),   # 18: west_house_red_mid
	Rect2(Vector2(828.0, 446.0), Vector2(64.0, 73.0)),   # 19: center_house_blue
	Rect2(Vector2(273.0, 476.0), Vector2(55.0, 62.0)),   # 20: west_house_red_corner
	Rect2(Vector2(475.0, 560.0), Vector2(60.0, 88.0)),   # 21: south_modern_red_house
	Rect2(Vector2(535.0, 560.0), Vector2(67.0, 88.0)),   # 22: south_modern_tower
	Rect2(Vector2(379.0, 678.0), Vector2(66.0, 98.0)),   # 23: south_house_blue_2
	Rect2(Vector2(445.0, 678.0), Vector2(66.0, 98.0)),   # 24: south_house_red_3
	Rect2(Vector2(223.0, 705.0), Vector2(66.0, 70.0)),   # 25: south_house_red_1
]

func _ready() -> void:
	collision_layer = 1
	collision_mask = 2
	_create_building_colliders()

func _create_building_colliders() -> void:
	for rect in BUILDINGS:
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		col.shape = shape
		# Position is centered on the rectangle
		col.position = rect.position + rect.size * 0.5
		add_child(col)
	
	print("Spawned solid collision constraints for all ", BUILDINGS.size(), " buildings.")
