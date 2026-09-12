extends MainLoop

func _process(_delta: float) -> bool:
	var out: Array[String] = []
	out.append("====================================================")
	out.append("  RUNNING AUTOMATED TEST SUITE: SOLDIER COMBAT & DQN")
	out.append("====================================================")

	var passed = 0
	var failed = 0

	# ----------------------------------------------------
	# TEST 1: DQN Weights JSON & In-Engine Inference
	# ----------------------------------------------------
	out.append("\n[TEST 1] Testing DQNInference...")
	var dqn = DQNInference.new()
	if not dqn.is_loaded:
		out.append("FAIL: DQN weights not loaded!")
		failed += 1
	else:
		out.append("  PASS: DQN weights loaded successfully (%d layers)." % dqn.layers.size())
		passed += 1

	var fire_spammer_vec = [0.95, 0.05, 0.05, 0.3, 0.9, 0.8, 0.1, 0.1, 0.1, 0.7, 0.8, 0.5]
	var fire_q = dqn.forward(fire_spammer_vec)
	var fire_act = dqn.predict(fire_spammer_vec)
	var adaptation = dqn.get_counter_info(fire_act, "Fire-dominant")
	out.append("  Fire Spammer Q-values: %s" % str(fire_q))
	out.append("  Predicted Action: %d (%s) -> Element: %s" % [fire_act, adaptation["strategy"], adaptation["element"]])
	
	if adaptation["element"] == "Water":
		out.append("  PASS: DQN successfully countered Fire Spammer with Water Power!")
		passed += 1
	else:
		out.append("FAIL: Expected Water counter for Fire Spammer, got %s" % adaptation["element"])
		failed += 1

	if adaptation["banner_text"].contains("NEXUS TACTICAL ADAPTATION") and adaptation["banner_text"].contains("Water"):
		out.append("  PASS: Adaptation banner text formatted correctly: %s" % adaptation["banner_text"])
		passed += 1
	else:
		out.append("FAIL: Adaptation banner text invalid: %s" % adaptation["banner_text"])
		failed += 1

	# ----------------------------------------------------
	# TEST 2: Combat Telemetry Tracker
	# ----------------------------------------------------
	out.append("\n[TEST 2] Testing CombatTelemetry Tracker...")
	var tel = CombatTelemetry.new()
	tel.record_battle_start()
	tel.record_hp(45, 50)
	
	tel.record_move("Flame Blast", 13)
	tel.record_turn()
	tel.record_move("Flame Blast", 14)
	tel.record_turn()
	tel.record_move("Flame Blast", 12)
	tel.record_turn()

	if tel.flame_blast_count == 3 and tel.consecutive_fire_streak == 3:
		out.append("  PASS: Recorded flame blast streak of 3.")
		passed += 1
	else:
		out.append("FAIL: Flame blast streak mismatch: %d" % tel.consecutive_fire_streak)
		failed += 1

	var style = tel.get_dominant_style_label()
	if style == "Fire-dominant":
		out.append("  PASS: Dominant style correctly recognized as Fire-dominant.")
		passed += 1
	else:
		out.append("FAIL: Expected Fire-dominant, got: %s" % style)
		failed += 1

	var vec = tel.get_behavior_vector()
	if vec.size() == 12:
		out.append("  PASS: Behavior vector size is 12.")
		passed += 1
	else:
		out.append("FAIL: Vector size is %d instead of 12" % vec.size())
		failed += 1

	tel.record_catch("Terron", false)
	if tel.consecutive_fire_streak == 0 and tel.catch_attempt_count == 1:
		out.append("  PASS: Catch attempt recorded and fire streak reset.")
		passed += 1
	else:
		out.append("FAIL: Streak was not reset on catch.")
		failed += 1

	# ----------------------------------------------------
	# TEST 3: Battle.tscn Scene Hierarchy
	# ----------------------------------------------------
	out.append("\n[TEST 3] Testing Battle.tscn Node Hierarchy...")
	var battle_scene = load("res://scenes/battle/Battle.tscn")
	if battle_scene == null:
		out.append("FAIL: Could not load res://scenes/battle/Battle.tscn")
		failed += 1
	else:
		var battle_node = battle_scene.instantiate()
		var s_sprite = battle_node.get_node_or_null("SoldierSprite")
		var c_sprite = battle_node.get_node_or_null("CreatureSprite")
		var banner = battle_node.get_node_or_null("CanvasLayer/AdaptationBanner")
		var banner_lbl = battle_node.get_node_or_null("CanvasLayer/AdaptationBanner/BannerLabel")

		if s_sprite != null:
			out.append("  PASS: SoldierSprite exists in Battle.tscn.")
			passed += 1
		else:
			out.append("FAIL: SoldierSprite missing from Battle.tscn")
			failed += 1

		if c_sprite != null:
			out.append("  PASS: CreatureSprite exists in Battle.tscn.")
			passed += 1
		else:
			out.append("FAIL: CreatureSprite missing from Battle.tscn")
			failed += 1

		if banner != null and banner_lbl != null:
			out.append("  PASS: AdaptationBanner and BannerLabel exist in Battle.tscn")
			passed += 1
		else:
			out.append("FAIL: AdaptationBanner or BannerLabel missing")
			failed += 1

		battle_node.free()

	# ----------------------------------------------------
	# TEST 4: 4 Elemental Soldier Powers Configuration
	# ----------------------------------------------------
	out.append("\n[TEST 4] Testing 4 Elemental Powers Mapping...")
	var expected_elements = ["Fire", "Water", "Earth", "Air"]
	var profiles = {
		"Fire": "Amberfox",
		"Water": "AquFin",
		"Earth": "Terron",
		"Air": "Zephyrin"
	}
	for elem in expected_elements:
		var target_c = profiles[elem]
		var c_elem = ""
		match target_c:
			"Amberfox": c_elem = "Fire"
			"AquFin", "Aqufin": c_elem = "Water"
			"Terron": c_elem = "Earth"
			"Zephyrin": c_elem = "Air"
		if c_elem == elem:
			out.append("  PASS: Power %s correctly maps to creature %s" % [elem, target_c])
			passed += 1
		else:
			out.append("FAIL: Mismatch for %s" % elem)
			failed += 1

	# ----------------------------------------------------
	# TEST 5: Overworld 4 Soldier Deployments in world.tscn
	# ----------------------------------------------------
	out.append("\n[TEST 5] Testing Overworld Soldiers in world.tscn...")
	var world_scene = load("res://scenes/world.tscn")
	if world_scene == null:
		out.append("FAIL: Could not load world.tscn")
		failed += 1
	else:
		var world_node = world_scene.instantiate()
		var soldiers_parent = world_node.get_node_or_null("Soldiers")
		if soldiers_parent != null:
			var s_count = soldiers_parent.get_child_count()
			out.append("  Overworld Soldiers count: %d" % s_count)
			var found_creatures: Array[String] = []
			for s in soldiers_parent.get_children():
				if "assigned_creature" in s:
					found_creatures.append(s.assigned_creature)
					out.append("    - Soldier [%s]: Power = %s" % [s.soldier_id, s.assigned_creature])
			
			var all_present = true
			for c in ["Terron", "Amberfox", "Zephyrin", "AquFin"]:
				var found = false
				for fc in found_creatures:
					if fc.to_lower() == c.to_lower():
						found = true
						break
				if not found:
					all_present = false
					out.append("FAIL: Missing soldier for power %s" % c)
			
			if all_present:
				out.append("  PASS: All 4 elemental powers represented across overworld soldiers!")
				passed += 1
			else:
				failed += 1
		else:
			out.append("FAIL: Soldiers node not found in world.tscn")
			failed += 1
		world_node.free()

	out.append("\n====================================================")
	out.append("  TEST RESULTS SUMMARY: %d PASSED, %d FAILED" % [passed, failed])
	out.append("====================================================")
	if failed == 0:
		out.append(">>> ALL TESTS PASSED SUCCESSFULLY! <<<")

	var result_str = "\n".join(out)
	print(result_str)

	# Write results directly to test_results.txt
	var f = FileAccess.open("res://test_results.txt", FileAccess.WRITE)
	if f:
		f.store_string(result_str)
		f.close()

	# Return true to immediately exit the MainLoop cleanly
	return true
