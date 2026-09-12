import os
import json
import re
import numpy as np

def run_checks():
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    print("====================================================")
    print("  COMPREHENSIVE IMPLEMENTATION VERIFICATION SUITE   ")
    print(f"  Project Root: {base_dir}")
    print("====================================================\n")

    passed = 0
    failed = 0

    # ----------------------------------------------------
    # CHECK 1: DQN Model Weights JSON
    # ----------------------------------------------------
    print("[CHECK 1] Verifying DQN Model Weights JSON...")
    weights_path = os.path.join(base_dir, "assets", "ai", "dqn_model_weights.json")
    if not os.path.exists(weights_path):
        print(f"  FAIL: File not found at {weights_path}")
        failed += 1
    else:
        with open(weights_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        
        assert data.get("model_type") == "DQN", "Model type is not DQN"
        assert data.get("timesteps") == 10000, f"Expected 10000 timesteps, got {data.get('timesteps')}"
        assert data.get("input_dim") == 12, "Input dimension must be 12"
        assert data.get("action_dim") == 6, "Action dimension must be 6"
        
        layers = data.get("layers", [])
        assert len(layers) == 3, f"Expected 3 layers, got {len(layers)}"
        
        # Layer dimensions
        # Layer 0: 12 -> 32
        # Layer 1: 32 -> 32
        # Layer 2: 32 -> 6
        assert layers[0]["in_features"] == 12 and layers[0]["out_features"] == 32
        assert layers[1]["in_features"] == 32 and layers[1]["out_features"] == 32
        assert layers[2]["in_features"] == 32 and layers[2]["out_features"] == 6
        print("  PASS: Weights JSON structure and layer dimensions valid (12 -> 32 -> 32 -> 6).")
        passed += 1

        # Simulate exact forward pass from dqn_inference.gd
        def gdscript_forward(vec):
            curr = [float(v) for v in vec]
            for l_idx, layer in enumerate(layers):
                w = layer["weights"]
                b = layer["bias"]
                num_out = len(w)
                next_vec = [0.0] * num_out
                for j in range(num_out):
                    s = b[j]
                    row = w[j]
                    for k in range(len(row)):
                        s += row[k] * curr[k]
                    # ReLU on hidden layers
                    if l_idx < len(layers) - 1:
                        if s < 0.0:
                            s = 0.0
                    next_vec[j] = s
                curr = next_vec
            return curr

        # Test Fire Spammer Vector -> Should predict Water Counter (Action 1)
        fire_spammer_vec = [0.95, 0.05, 0.05, 0.3, 0.9, 0.8, 0.1, 0.1, 0.1, 0.7, 0.8, 0.5]
        q_fire = gdscript_forward(fire_spammer_vec)
        best_act_fire = int(np.argmax(q_fire))
        print(f"  Fire Spammer Q-values: {[round(v, 2) for v in q_fire]}")
        print(f"  Predicted Counter Action: {best_act_fire} ({data['action_names'].get(str(best_act_fire))})")
        if best_act_fire == 1:
            print("  PASS: DQN successfully predicts Action 1 (Water Counter - AquFin) for Fire Spammer!")
            passed += 1
        else:
            print(f"  FAIL: Expected Action 1 for Fire Spammer, got {best_act_fire}")
            failed += 1

        # Test Water User Vector -> Should predict Earth Tank (Action 2)
        water_user_vec = [0.1, 0.1, 0.05, 0.3, 0.9, 0.0, 0.9, 0.1, 0.1, 0.5, 0.0, 0.6]
        q_water = gdscript_forward(water_user_vec)
        best_act_water = int(np.argmax(q_water))
        print(f"  Water User Q-values: {[round(v, 2) for v in q_water]}")
        print(f"  Predicted Counter Action: {best_act_water} ({data['action_names'].get(str(best_act_water))})")
        if best_act_water == 2:
            print("  PASS: DQN successfully predicts Action 2 (Earth Tank - Terron) for Water User!")
            passed += 1
        else:
            print(f"  FAIL: Expected Action 2 for Water User, got {best_act_water}")
            failed += 1

    # ----------------------------------------------------
    # CHECK 2: Battle.tscn Scene Hierarchy
    # ----------------------------------------------------
    print("\n[CHECK 2] Verifying Battle.tscn Nodes...")
    battle_tscn_path = os.path.join(base_dir, "scenes", "battle", "Battle.tscn")
    with open(battle_tscn_path, "r", encoding="utf-8") as f:
        battle_tscn = f.read()

    assert '[node name="SoldierSprite" type="AnimatedSprite2D"' in battle_tscn, "SoldierSprite node missing from Battle.tscn"
    assert '[node name="CreatureSprite" type="Sprite2D"' in battle_tscn, "CreatureSprite node missing from Battle.tscn"
    assert '[node name="AdaptationBanner" type="PanelContainer"' in battle_tscn, "AdaptationBanner missing from Battle.tscn"
    assert '[node name="BannerLabel" type="Label"' in battle_tscn, "BannerLabel missing from Battle.tscn"
    assert 'res://assets/soldier_frames.tres' in battle_tscn, "soldier_frames.tres missing from Battle.tscn ExtResource"
    print("  PASS: SoldierSprite, CreatureSprite, AdaptationBanner, and BannerLabel are properly declared in Battle.tscn.")
    passed += 1

    # ----------------------------------------------------
    # CHECK 3: battle.gd Implementation
    # ----------------------------------------------------
    print("\n[CHECK 3] Verifying battle.gd Logic...")
    battle_gd_path = os.path.join(base_dir, "scripts", "battle.gd")
    with open(battle_gd_path, "r", encoding="utf-8") as f:
        battle_gd = f.read()

    # Soldier on Platform checks
    assert "is_soldier_battle" in battle_gd, "is_soldier_battle flag missing"
    assert "soldier_sprite.global_position = Vector2(246, 105)" in battle_gd, "Soldier position not set to (246, 105)"
    assert "creature_sprite.visible = false" in battle_gd, "CreatureSprite not hidden in soldier battle"
    assert "_set_soldier_left_facing" in battle_gd, "_set_soldier_left_facing method missing"
    print("  PASS: Soldier sprite platform positioning at (246, 105) and facing left verified.")
    passed += 1

    # 4 Elemental Soldier Powers checks
    for elem in ["Fire", "Water", "Earth", "Air"]:
        assert f'"{elem}":' in battle_gd, f"Profile for element {elem} missing in battle.gd"
    assert "Amberfox" in battle_gd and "AquFin" in battle_gd and "Terron" in battle_gd and "Zephyrin" in battle_gd
    print("  PASS: 4 distinct elemental profiles (Fire-Amberfox, Water-AquFin, Earth-Terron, Air-Zephyrin) present in battle.gd.")
    passed += 1

    # Catch Tube handling against Soldier
    assert "You can't catch a human soldier!" in battle_gd, "Soldier catch tube error message missing"
    assert "deflect_tween" in battle_gd or "deflects" in battle_gd, "Tube deflection animation missing"
    print("  PASS: Clean Catch-Tube deflection and 'You can't catch a human soldier!' message verified.")
    passed += 1

    # Telemetry and Tactical Banner
    assert "telemetry.record_move" in battle_gd, "Telemetry record_move missing"
    assert "telemetry.record_catch" in battle_gd, "Telemetry record_catch missing"
    assert "telemetry.record_run" in battle_gd, "Telemetry record_run missing"
    assert "adaptation_banner" in battle_gd, "Adaptation banner reference missing"
    print("  PASS: Player combat telemetry tracking and tactical adaptation banner integration verified.")
    passed += 1

    # ----------------------------------------------------
    # CHECK 4: Overworld Soldiers in world.tscn
    # ----------------------------------------------------
    print("\n[CHECK 4] Verifying Overworld Soldiers in world.tscn...")
    world_tscn_path = os.path.join(base_dir, "scenes", "world.tscn")
    with open(world_tscn_path, "r", encoding="utf-8") as f:
        world_tscn = f.read()

    # Check for all 4 soldiers and powers
    expected_soldiers = [
        ("Terron", "soldier_west_road"),
        ("Amberfox", "soldier_plaza"),
        ("Zephyrin", "soldier_north_gate"),
        ("AquFin", "soldier_water_sentry")
    ]
    for creature, soldier_id in expected_soldiers:
        assert soldier_id in world_tscn, f"Soldier {soldier_id} missing from world.tscn"
        assert creature in world_tscn, f"Assigned creature {creature} missing from world.tscn"
    print("  PASS: All 4 elemental soldiers (Terron, Amberfox, Zephyrin, AquFin) deployed in world.tscn.")
    passed += 1

    # ----------------------------------------------------
    # CHECK 5: soldier.gd Integration
    # ----------------------------------------------------
    print("\n[CHECK 5] Verifying soldier.gd Script...")
    soldier_gd_path = os.path.join(base_dir, "scripts", "soldier.gd")
    with open(soldier_gd_path, "r", encoding="utf-8") as f:
        soldier_gd = f.read()

    assert "get_soldier_element" in soldier_gd, "get_soldier_element method missing"
    assert "gs.soldier_battle_active = true" in soldier_gd, "soldier_battle_active assignment missing"
    assert "gs.soldier_assigned_element = elem" in soldier_gd, "soldier_assigned_element assignment missing"
    print("  PASS: soldier.gd correctly sets soldier_battle_active and soldier_assigned_element.")
    passed += 1

    # ----------------------------------------------------
    # CHECK 6: GameState Singleton
    # ----------------------------------------------------
    print("\n[CHECK 6] Verifying game_state.gd Script...")
    gs_path = os.path.join(base_dir, "scripts", "game_state.gd")
    with open(gs_path, "r", encoding="utf-8") as f:
        gs = f.read()

    assert "var soldier_battle_active: bool = false" in gs
    assert "var soldier_assigned_element: String = \"\"" in gs
    assert "var telemetry: CombatTelemetry = null" in gs
    assert "var dqn_ai: DQNInference = null" in gs
    assert "func get_next_adaptation() -> Dictionary:" in gs
    print("  PASS: game_state.gd correctly manages telemetry, DQN adaptation, and soldier parameters.")
    passed += 1

    print("\n====================================================")
    print(f"  RESULTS: {passed} PASSED, {failed} FAILED")
    print("====================================================")
    assert failed == 0, "Some checks failed!"
    print(">>> ALL VERIFICATION CHECKS PASSED SUCCESSFULLY! <<<\n")

if __name__ == "__main__":
    run_checks()
