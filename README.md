💎 indie-pixel by team ALcadex

<p align="center">

<strong>REAL WORLD × AI × GAMING</strong><br>
<em>Turn the Real World into a Game.</em>

</p>

<p align="center">

A GBA-inspired 2D pixel RPG where real-world geography becomes the game
world, cadex (creatures with different powers) become powers, and enemies learn from the way you
fight.

</p>

<p align="center">






</p>

🎮 Overview

indie-pixel is an AI-powered, real-world-inspired pixel RPG created
for KICKR CODEMANIA 2026.

The game combines three pillars into one gameplay loop:

🌍 REAL WORLD - real-world-inspired geography (implemented map is part rishikesh)
🤖 AI - enemies that can adapt to player behavior as game goes on that create critical thinking part which makes it more intresting
🎮 GAMING - exploration, encounters, battles, progression and story

Instead of using AI as a cosmetic feature, indie-pixel is designed so
that player behavior can directly influence gameplay.

📖 Story

You wake up inside a destroyed secret laboratory wear a special gear suite.

You don't remember who you are.

The facility is burning. Something has gone horribly wrong.

While escaping, you discover a wounded creature. When you reach out to
help it, something impossible happens:

The creature is absorbed into you.

A strange crystal appears inside your backpack.

As you explore the city, fragments of the truth begin to surface.

A secret organization has been experimenting on humans and creatures,
attempting to create enhanced soldiers powerful enough to control the
world.

And there is one disturbing possibility:

You may be one of their experiments.

Your journey is no longer just about escaping.

You must discover:

Who created the crystals?

Why can you absorb creatures?

What happened inside the laboratory?

What is the organization building?

And most importantly...

Who are you?

🌍 REAL WORLD × GAMING

indie pixel transforms real-world-inspired geography into a playable RPG
environment.

The prototype world is inspired by Indian city geography, with
locations represented through a classic top-down pixel-art style.

Real-world geography can become:

🏙️ City areas

🌊 Rivers and water bodies

🌉 Bridges

🛣️ Roads

🌳 Natural zones

🧪 Secret laboratories

👾 Creature encounter regions

🪖 Enemy-controlled areas

The goal is simple:

The map isn't just a background. It becomes part of the game
system.

🤖 AI-DRIVEN COMBAT

indie pixel uses AI where it matters most: gameplay.

Instead of giving enemies completely fixed behavior, the system can
observe recent player actions and use that information when selecting an
enemy response.

Example

PLAYER
🔥 Fire Attack
🔥 Fire Attack
🔥 Fire Attack
       │
       ▼
AI OBSERVES PATTERN
       │
       ▼
ENEMY ADAPTS
       │
       ▼
🛡️ Defensive / Counter Strategy
       │
       ▼
PLAYER MUST ADAPT

This creates a simple but important design principle:

The player teaches the enemy how they play.

The AI should influence decision-making, not secretly change stats
or cheat.

💎 THE CRYSTAL SYSTEM

Creatures aren't simply collectibles.

They become abilities.

When a creature is absorbed, its essence becomes a crystal stored in the
player's backpack.

CREATURE
    ↓
ABSORB
    ↓
CRYSTAL
    ↓
ABILITY
    ↓
NEW STRATEGY

Creature → Crystal Examples

Creature               Crystal         Example Ability

🔥 Emberfox            Ember Crystal   Flame blast
💧 aqufin             Water Crystal   Water wave
☁️ zephyrin              Wind Crystal    Wind slash
🪨 terrion             Stone Crystal   Rock slam

The crystal system connects exploration, combat and progression.

👾 CREATURE ENCOUNTERS

Creatures can appear naturally while exploring the world.

Visible grass is not required.

Instead, the game can use hidden encounter zones and movement-based
encounter checks.

PLAYER EXPLORES
      ↓
MOVEMENT STEP
      ↓
ENCOUNTER CHECK
      ↓
RANDOM / ZONE CHANCE
      ↓
CREATURE APPEARS
      ↓
BATTLE

Different areas can use different encounter rates, allowing the same
world to feel different depending on where the player explores.

⚔️ BATTLE SYSTEM

indie pixel follows a classic handheld RPG battle philosophy while
adding adaptive enemy behavior.

Core Battle Loop

EXPLORE
   ↓
ENCOUNTER
   ↓
BATTLE
   ↓
PLAYER ACTION
   ↓
AI RESPONSE
   ↓
VICTORY / DEFEAT
   ↓
CRYSTAL / PROGRESSION
   ↓
EXPLORE AGAIN

Possible battle actions include:

⚔️ FIGHT

💎 CRYSTAL

🛡️ DEFEND

🏃 RUN

The intended experience is easy to understand but difficult to
completely memorize because enemy decisions can respond to the player's
behavior.

🗺️ WORLD DESIGN

The current prototype focuses on rishikesh cities as the playable
environment.

The world is designed with a classic GBA-era visual language:

Low-resolution pixel art

Top-down exploration

Tile/map-based environments

Compact readable spaces

Rivers and bridges

Buildings and roads

Natural areas

Hidden encounter zones

Story locations

Visual Direction

Classic handheld RPG + Indian real-world geography + modern AI
gameplay

🧍 CHARACTER

Players can choose their protagonist:

👦 Boy

A pixel-art protagonist equipped with the crystal backpack system.

👧 Girl

An alternate protagonist with the same core gameplay systems and a
distinct visual identity.

The backpack is an important part of the game's visual language because
it houses the player's collected crystals.

🎯 THE PROBLEM WE ARE SOLVING

Many games treat AI, real-world data and gameplay as separate
features.

 our game explores how they can become one system.

Traditional approach

FIXED WORLD
     +
FIXED ENEMIES
     +
FIXED BEHAVIOR

Crystalborn approach

REAL-WORLD-INSPIRED WORLD
          +
DYNAMIC ENCOUNTERS
          +
PLAYER-RESPONSIVE AI
          +
CREATURE-BASED POWERS

Our design goal

Where you explore and how you play should both matter.

This creates a foundation for games that can feel more dynamic without
requiring every interaction to be manually scripted.
also you have full freedom to customize attacks

🔁 CORE GAME LOOP

┌─────────────────┐
│    EXPLORE      │
└────────┬────────┘
         ↓
┌─────────────────┐
│   ENCOUNTER     │
└────────┬────────┘
         ↓
┌─────────────────┐
│     BATTLE      │
└────────┬────────┘
         ↓
┌─────────────────┐
│ ABSORB / DEFEAT │
└────────┬────────┘
         ↓
┌─────────────────┐
│  GET CRYSTAL    │
└────────┬────────┘
         ↓
┌─────────────────┐
│  NEW ABILITY    │
└────────┬────────┘
         ↓
┌─────────────────┐
│     EXPLORE     │
└─────────────────┘

🏆 KICKR CODEMANIA 2026

Theme

REAL WORLD × AI × GAMING

indie pixel maps directly to the theme:

Theme           Crystalborn

🌍 Real World   Real-world-inspired city geography
🤖 AI           Player-responsive enemy decision making
🎮 Gaming       Exploration + encounters + battles + progression

Why it fits

The real-world layer affects where gameplay happens.

The AI layer affects how gameplay responds.

The game layer connects both into a playable loop.

🎬 DEMO FLOW

Our recommended 3--5 minute presentation flow:

01  CHARACTER SELECT
        ↓
02  ENTER CITY
        ↓
03  EXPLORE REAL-WORLD-INSPIRED MAP
        ↓
04  CREATURE ENCOUNTER
        ↓
05  BATTLE
        ↓
06  ABSORB CREATURE
        ↓
07  CRYSTAL POWER UNLOCKED
        ↓
08  ENEMY SOLDIER ENCOUNTER
        ↓
09  AI ADAPTS TO PLAYER
        ↓
10  PLAYER CHANGES STRATEGY
        ↓
11  VICTORY
        ↓
12  STORY / MEMORY REVEAL

🛠️ TECH STACK

Technology                Purpose

Godot 4               Game engine
GDScript              Gameplay programming
2D Tile/Map Systems   World construction
Pixel Art             GBA-inspired visual style
Encounter System      Dynamic creature spawning
Battle System         Turn-based combat
Adaptive AI           Player-responsive enemy decisions

📁 PROJECT STRUCTURE

indie-pixel/
│
├── assets/
│   ├── player/
│   ├── creatures/
│   ├── map/
│   └── battle/
│
├── scenes/
│   ├── main/
│   ├── world/
│   └── battle/
│
├── scripts/
│   ├── player.gd
│   ├── world.gd
│   ├── encounter_manager.gd
│   ├── battle_manager.gd
│   ├── battle_creature.gd
│   └── game_state.gd
│
├── data/
│   ├── creatures.json
│   └── moves.json
│
└── project.godot

🎮 CONTROLS

Movement

Key         Action

W / ↑   Move Up
A / ←   Move Left
S / ↓   Move Down
D / →   Move Right

Additional interaction and battle controls may evolve during
development.

🚀 RUN THE PROJECT

Requirements

Godot 4

Git

Clone the repository

git clone https://github.com/kezv166-web/indie-pixel.git
cd indie-pixel

Open the project in Godot and run the configured main scene.

🔮 FUTURE ROADMAP

Crystalborn is designed as a foundation that can grow beyond the
hackathon prototype.

📍 GPS-Driven Gameplay

Real player location could influence:

Creature encounters

Rare spawns

Missions

Events

City-specific content



📊 PROJECT STATUS

Hackathon Prototype

GBA-inspired visual direction

Player movement

City/world prototype

Encounter-system architecture

Creature concepts

Crystal progression concept

Battle-system architecture

Adaptive AI design

Full story campaign

Complete boss encounter

Expanded crystal abilities

GPS/camera/live-data integration

Features marked as planned are part of the roadmap and should not be
considered fully implemented in the current prototype.

👥 TEAM  ALcadex

Project: indie-pixel
Repository: indie-pixel
Engine: Godot 4
Genre: AI-powered 2D Pixel RPG
Theme: REAL WORLD × AI × GAMING
Event: KICKR CODEMANIA 2026

💎 THE VISION

pixel world is built around one idea:

What if the world around you could become the game --- and the game
could learn how you play?

Explore the world.
Encounter the unknown.
Absorb creatures.
Master crystals.
Outsmart adaptive enemies.
Uncover your identity.

EXPLORE. ABSORB. ADAPT. BECOME.

ppt link- https://drive.google.com/drive/folders/1LG-RjHrHt8dQ2Pr7_dJY-faksAPzOX3Y?usp=sharing


some assets - https://drive.google.com/drive/folders/1AgKIHAVrEgdmslaH_QdlR8u6PA8Hv3ih

📜 License

Add the project's license here.
