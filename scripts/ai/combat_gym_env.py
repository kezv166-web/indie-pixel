import gymnasium as gym
from gymnasium import spaces
import numpy as np

class CombatGymEnv(gym.Env):
    """
    Gymnasium Combat Environment simulating turn-based encounters between
    the player (with observable telemetry habits) and the enemy AI agent.

    Observation Space (12-D vector normalized [0.0, 1.0]):
      0: flame_blast_freq - Player tendency to use Fire/Flame Blast attack
      1: catch_attempt_freq - Player tendency to attempt tube capture
      2: run_freq - Player flee/run frequency
      3: avg_turn_count - Normalized average combat duration (turns / 10)
      4: health_preservation - Current player HP ratio (hp / max_hp)
      5: fire_creature_pref - Player usage/caught count of Fire creatures
      6: water_creature_pref - Player usage/caught count of Water creatures
      7: earth_creature_pref - Player usage/caught count of Earth creatures
      8: air_creature_pref - Player usage/caught count of Air creatures
      9: damage_dealt_avg - Normalized avg damage dealt per action
      10: consecutive_fire_attacks - Normalized consecutive fire attack streak (streak / 5)
      11: encounter_history_length - Total past encounters count normalized (count / 20)

    Action Space (Discrete 6):
      0: Aggressive Fire Rush (Soldier channels Fire - Amberfox)
      1: Water Counter (Soldier channels Water - AquFin)
      2: Earth Tanking (Soldier channels Earth - Terron)
      3: Air Evasion (Soldier channels Air - Zephyrin)
      4: Defensive Shield / Flame Dampen
      5: Ranged Punish
    """
    metadata = {"render_modes": ["human"]}

    def __init__(self):
        super().__init__()
        self.observation_space = spaces.Box(
            low=0.0,
            high=1.0,
            shape=(12,),
            dtype=np.float32
        )
        self.action_space = spaces.Discrete(6)
        self.state = np.zeros(12, dtype=np.float32)
        self.current_step = 0
        self.max_steps = 15

    def reset(self, seed=None, options=None):
        super().reset(seed=seed)
        self.current_step = 0
        
        # Archetypes for diverse training:
        # 0: Fire Spammer (Spams flame blast, high fire streak)
        # 1: Tube Collector (Tries to catch constantly)
        # 2: Cautious Runner (Flees or preserves health)
        # 3: Water/Balanced (Uses Water or mixed)
        # 4: Earth/Sturdy
        archetype = self.np_random.integers(0, 5)

        if archetype == 0:
            # Fire Spammer
            flame_blast_freq = self.np_random.uniform(0.7, 1.0)
            catch_freq = self.np_random.uniform(0.0, 0.2)
            run_freq = self.np_random.uniform(0.0, 0.1)
            consec_fire = self.np_random.uniform(0.6, 1.0)
            fire_pref = self.np_random.uniform(0.6, 1.0)
            water_pref = self.np_random.uniform(0.0, 0.2)
            earth_pref = self.np_random.uniform(0.0, 0.2)
            air_pref = self.np_random.uniform(0.0, 0.2)
        elif archetype == 1:
            # Tube Collector
            flame_blast_freq = self.np_random.uniform(0.1, 0.4)
            catch_freq = self.np_random.uniform(0.6, 1.0)
            run_freq = self.np_random.uniform(0.0, 0.2)
            consec_fire = self.np_random.uniform(0.0, 0.2)
            fire_pref = self.np_random.uniform(0.2, 0.5)
            water_pref = self.np_random.uniform(0.2, 0.5)
            earth_pref = self.np_random.uniform(0.2, 0.5)
            air_pref = self.np_random.uniform(0.2, 0.5)
        elif archetype == 2:
            # Cautious Runner
            flame_blast_freq = self.np_random.uniform(0.2, 0.5)
            catch_freq = self.np_random.uniform(0.1, 0.3)
            run_freq = self.np_random.uniform(0.6, 1.0)
            consec_fire = self.np_random.uniform(0.0, 0.3)
            fire_pref = self.np_random.uniform(0.1, 0.4)
            water_pref = self.np_random.uniform(0.1, 0.4)
            earth_pref = self.np_random.uniform(0.1, 0.4)
            air_pref = self.np_random.uniform(0.1, 0.4)
        elif archetype == 3:
            # Water Dominant
            flame_blast_freq = self.np_random.uniform(0.1, 0.3)
            catch_freq = self.np_random.uniform(0.1, 0.3)
            run_freq = self.np_random.uniform(0.0, 0.2)
            consec_fire = 0.0
            fire_pref = self.np_random.uniform(0.0, 0.2)
            water_pref = self.np_random.uniform(0.7, 1.0)
            earth_pref = self.np_random.uniform(0.0, 0.2)
            air_pref = self.np_random.uniform(0.0, 0.2)
        else:
            # Earth / Balanced
            flame_blast_freq = self.np_random.uniform(0.2, 0.5)
            catch_freq = self.np_random.uniform(0.2, 0.4)
            run_freq = self.np_random.uniform(0.1, 0.3)
            consec_fire = self.np_random.uniform(0.1, 0.3)
            fire_pref = self.np_random.uniform(0.2, 0.4)
            water_pref = self.np_random.uniform(0.2, 0.4)
            earth_pref = self.np_random.uniform(0.6, 1.0)
            air_pref = self.np_random.uniform(0.1, 0.3)

        avg_turns = self.np_random.uniform(0.2, 0.8)
        hp_ratio = self.np_random.uniform(0.3, 1.0)
        dmg_avg = self.np_random.uniform(0.3, 0.9)
        enc_hist = self.np_random.uniform(0.1, 1.0)

        self.state = np.array([
            flame_blast_freq,
            catch_freq,
            run_freq,
            avg_turns,
            hp_ratio,
            fire_pref,
            water_pref,
            earth_pref,
            air_pref,
            dmg_avg,
            consec_fire,
            enc_hist
        ], dtype=np.float32)

        return self.state, {}

    def step(self, action: int):
        self.current_step += 1
        
        flame_blast_freq = self.state[0]
        catch_freq = self.state[1]
        run_freq = self.state[2]
        water_pref = self.state[6]
        earth_pref = self.state[7]
        air_pref = self.state[8]
        consec_fire = self.state[10]

        reward = 0.0

        # Elemental Counter Matrix:
        # Water counters Fire (Action 1 counters Flame Blast / Fire Spammer)
        # Earth counters Water (Action 2 counters Water)
        # Air counters Earth (Action 3 counters Earth)
        # Fire counters Air (Action 0 counters Air)
        # Defensive Shield/Dampen (Action 4) counters aggressive Fire / high damage
        # Ranged Punish (Action 5) counters Catch spam / Runner

        if flame_blast_freq > 0.55 or consec_fire > 0.4:
            # Player is heavily using Flame Blast / Fire
            if action == 1:
                # Water Counter (AquFin) -> Best counter!
                reward = 2.0
            elif action == 4:
                # Defensive Flame Dampen -> Strong counter
                reward = 1.2
            elif action == 0:
                # Fire vs Fire -> Neutral
                reward = 0.1
            elif action == 3:
                # Air vs Fire -> Disadvantaged
                reward = -0.6
            elif action == 2:
                # Earth vs Fire -> Very weak
                reward = -1.5
            else:
                reward = -0.2
        elif catch_freq > 0.5:
            # Player spams tube catching
            if action == 5 or action == 0:
                # Ranged Punish or Aggressive Fire Rush -> Punishes passive catching
                reward = 1.8
            elif action == 1 or action == 2:
                reward = 0.5
            else:
                reward = 0.0
        elif run_freq > 0.5:
            # Player is running away
            if action == 3 or action == 5:
                # Air Evasion / Fast Punish -> Intercepts runners
                reward = 1.8
            else:
                reward = 0.2
        elif water_pref > 0.5:
            # Water user
            if action == 2:
                # Earth counters Water
                reward = 2.0
            elif action == 1:
                reward = 0.2
            elif action == 0:
                reward = -1.5
            else:
                reward = 0.5
        elif earth_pref > 0.5:
            # Earth user
            if action == 3:
                # Air counters Earth
                reward = 2.0
            elif action == 2:
                reward = 0.2
            elif action == 1:
                reward = -1.0
            else:
                reward = 0.5
        else:
            # Balanced or Air
            if action == 0:
                reward = 1.5
            elif action == 1 or action == 2:
                reward = 0.8
            else:
                reward = 0.6

        # Slight noise to state over time
        noise = self.np_random.normal(0, 0.02, size=12).astype(np.float32)
        self.state = np.clip(self.state + noise, 0.0, 1.0)

        terminated = self.current_step >= self.max_steps
        truncated = False

        return self.state, float(reward), terminated, truncated, {}
