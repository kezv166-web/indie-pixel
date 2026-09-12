import os
import json
import numpy as np
import torch
from stable_baselines3 import DQN
from combat_gym_env import CombatGymEnv

def train_and_export():
    print("[AI Train] Initializing CombatGymEnv...")
    env = CombatGymEnv()

    # Policy architecture: 2 hidden layers of 32 units
    policy_kwargs = dict(
        net_arch=[32, 32]
    )

    print("[AI Train] Building DQN model...")
    model = DQN(
        "MlpPolicy",
        env,
        policy_kwargs=policy_kwargs,
        learning_rate=1e-3,
        buffer_size=10000,
        learning_starts=400,
        batch_size=64,
        gamma=0.95,
        exploration_fraction=0.3,
        exploration_initial_eps=1.0,
        exploration_final_eps=0.05,
        target_update_interval=250,
        verbose=1,
        seed=42
    )

    print("[AI Train] Training for 10,000 steps...")
    model.learn(total_timesteps=10000, log_interval=100)
    print("[AI Train] Training complete!")

    # Inspect the trained Q-network
    q_net = model.policy.q_net
    print("[AI Train] Q-Net architecture:\n", q_net)

    state_dict = q_net.state_dict()
    print("[AI Train] State dict keys:", list(state_dict.keys()))

    # Extract linear layers
    # In SB3 DQN with net_arch=[32, 32]:
    # q_net.q_net has Linear(12, 32), ReLU, Linear(32, 32), ReLU, Linear(32, 6)
    layers_data = []
    layer_idx = 0

    # Sequential search for Linear layers in state dict
    weight_keys = [k for k in state_dict.keys() if "weight" in k]
    bias_keys = [k for k in state_dict.keys() if "bias" in k]
    
    print(f"[AI Train] Found {len(weight_keys)} weight tensors and {len(bias_keys)} bias tensors.")

    for w_key, b_key in zip(weight_keys, bias_keys):
        w = state_dict[w_key].cpu().numpy().tolist() # Shape: [out_features, in_features]
        b = state_dict[b_key].cpu().numpy().tolist() # Shape: [out_features]
        layers_data.append({
            "name": f"layer_{layer_idx}",
            "weight_key": w_key,
            "bias_key": b_key,
            "weights": w,
            "bias": b,
            "in_features": len(w[0]),
            "out_features": len(w)
        })
        print(f"  Layer {layer_idx}: in={len(w[0])}, out={len(w)}")
        layer_idx += 1

    # Verify forward pass in pure NumPy against PyTorch
    test_inputs = [
        # Fire Spammer: flame_blast_freq=0.9, consec_fire=0.8
        [0.9, 0.05, 0.05, 0.3, 0.9, 0.8, 0.1, 0.1, 0.1, 0.7, 0.8, 0.5],
        # Tube Catcher: catch_freq=0.85
        [0.1, 0.85, 0.05, 0.4, 0.8, 0.2, 0.2, 0.2, 0.2, 0.3, 0.0, 0.4],
        # Water User: water_pref=0.9
        [0.1, 0.1, 0.05, 0.3, 0.9, 0.0, 0.9, 0.1, 0.1, 0.5, 0.0, 0.6],
        # Earth User: earth_pref=0.9
        [0.1, 0.1, 0.05, 0.3, 0.9, 0.1, 0.1, 0.9, 0.1, 0.5, 0.0, 0.6]
    ]

    action_names = {
        0: "Fire Rush (Amberfox)",
        1: "Water Counter (AquFin)",
        2: "Earth Tank (Terron)",
        3: "Air Evasion (Zephyrin)",
        4: "Defensive Shield",
        5: "Ranged Punish"
    }

    print("\n[AI Train] Validating Numpy forward pass against PyTorch Q-net:")
    for i, x in enumerate(test_inputs):
        x_arr = np.array(x, dtype=np.float32)
        # PyTorch forward
        with torch.no_grad():
            t_out = q_net(torch.tensor(x_arr).unsqueeze(0)).numpy().flatten()
        
        # Pure NumPy forward (simulating what GDScript will do)
        curr = x_arr
        for l_i, l_info in enumerate(layers_data):
            w = np.array(l_info["weights"], dtype=np.float32)
            b = np.array(l_info["bias"], dtype=np.float32)
            curr = np.dot(w, curr) + b
            if l_i < len(layers_data) - 1:
                # ReLU on hidden layers
                curr = np.maximum(0, curr)
        
        np_out = curr
        assert np.allclose(t_out, np_out, atol=1e-4), f"Mismatch between PyTorch and NumPy at test {i}!"
        best_action = int(np.argmax(np_out))
        print(f"  Test {i} (Player vector: Fire={x[0]:.1f}, Catch={x[1]:.1f}, Water={x[6]:.1f}):")
        print(f"    Q-values: {[round(float(v), 3) for v in np_out]}")
        print(f"    Selected Counter Action: {best_action} -> {action_names.get(best_action, 'Unknown')}")

    # Export to JSON
    export_payload = {
        "model_type": "DQN",
        "timesteps": 10000,
        "input_dim": 12,
        "action_dim": 6,
        "action_names": action_names,
        "layers": layers_data
    }

    # Save to both assets/ai/dqn_model_weights.json and scripts/ai/dqn_model_weights.json
    output_dirs = [
        os.path.join(os.path.dirname(__file__), "..", "..", "assets", "ai"),
        os.path.join(os.path.dirname(__file__))
    ]

    for d in output_dirs:
        os.makedirs(d, exist_ok=True)
        json_path = os.path.join(d, "dqn_model_weights.json")
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(export_payload, f, indent=2)
        print(f"[AI Train] Exported weights JSON to: {os.path.abspath(json_path)}")

if __name__ == "__main__":
    train_and_export()
