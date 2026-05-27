# Automatic Dreamland — Opening Experience MVP Spec

## Overview

A playable opening sequence: walk around a cozy village, talk to NPCs, get a quest, fight a tutorial battle, return to find the village destroyed, rescue Claira. Grid-based top-down movement, dialogue system, quest state machine, and scene transitions integrating with the existing battle system.

## Scope

### In Scope
- Grid-based top-down village map (TileMap, placeholder tiles)
- Player character with grid movement (arrow keys/WASD)
- ~14 NPCs on the map
- Dialogue system: bottom text box (normal) + full screen overlay (cinematic moments)
- Auto-trigger and interact-button NPC activation
- Quest state machine tracking opening progress
- Claira follows player as companion NPC between square and elder's house
- Scene transitions: village → road → homestead → village destroyed
- Tutorial combat on the road (hooks into existing battle system, solo fight)
- Destruction scene (same map, darker, ruined, find Claira)
- Trinket acquisition
- Claira joins party after rescue
- Placeholder art throughout (colored rectangles)

### Out of Scope
- Full art/sprites
- Building interiors (doors trigger dialogue)
- Inventory system
- Animated cutscenes
- Sound/music
- Anything past leaving the destroyed village

## Architecture

### Dialogue System

#### DialogueData (`scripts/data/dialogue_data.gd`)
- `class_name DialogueData extends RefCounted`
- Stores dialogue as an array of line dictionaries
- Each line: `{speaker: String, text: String, mode: String}` where mode is `"normal"` or `"cinematic"`
- Static factory methods for each conversation in the opening (elder, claira, tavern keeper, old couple, flavor NPCs, story moments)

#### DialogueBox (`scripts/ui/dialogue_box.gd`)
- Bottom-of-screen text box for normal dialogue
- Shows speaker name and text
- Advance on Space/Enter/click
- Emits `line_advanced` and `dialogue_finished`
- Typing effect (text appears letter by letter)

#### CinematicOverlay (`scripts/ui/cinematic_overlay.gd`)
- Full screen dark overlay with centered text and speaker name
- Same input to advance as DialogueBox
- Used for tree kiss, finding Claira in the barrier, leaving the village
- Emits same signals as DialogueBox

#### DialogueManager (`scripts/ui/dialogue_manager.gd`)
- Singleton or node that plays a dialogue sequence
- Receives an array of lines from DialogueData
- Per line, picks DialogueBox or CinematicOverlay based on mode
- Disables player movement while dialogue is active
- Emits `dialogue_finished` when the full sequence is done

### Overworld System

#### Player (`scripts/overworld/player.gd`)
- Grid-based movement: arrow keys or WASD
- Moves one tile at a time, smooth tween between tiles
- Collision check before moving (walls, buildings, NPCs)
- Interact button: Space or Enter — triggers dialogue on facing NPC
- Can be disabled (during dialogue, cutscenes)
- Facing direction tracked for interact targeting

#### NPC (`scripts/overworld/npc.gd`)
- Placed on the grid with a position
- Properties: `npc_name`, `trigger_mode` ("auto" or "interact"), `repeatable` (bool)
- Has a method `get_dialogue(quest_state) -> Array` — returns dialogue lines based on current quest state
- Auto-trigger NPCs fire when player steps adjacent
- Interact NPCs fire when player faces them and presses interact
- Visual: colored rectangle with name label (like character sprites in battle)

#### FollowNPC (`scripts/overworld/follow_npc.gd`)
- Extends NPC behavior — follows behind the player on the grid
- Maintains 1 tile distance, follows player's previous positions
- Used for Claira walking to the elder's house
- Can be told to stop following and stay at a position

### Quest State System

#### QuestState (`scripts/data/quest_state.gd`)
- `class_name QuestState extends RefCounted`
- Enum:

```
enum State {
    EXPLORE_VILLAGE,
    TALKED_TO_CLAIRA,
    WALKING_TO_ELDER,
    AT_ELDER,
    GOT_QUEST,
    ON_THE_ROAD,
    AT_HOMESTEAD,
    RETURNING,
    VILLAGE_DESTROYED,
    FOUND_CLAIRA,
    LEAVING
}
```

- `current_state: State`
- `advance() -> void` — moves to next state
- `set_state(state: State) -> void` — jump to specific state
- NPCs check `current_state` to decide dialogue
- Signal: `state_changed(new_state: State)`

### Scenes

#### Village (`scenes/overworld/village.tscn`)
- TileMap-based grid map, ~20x30 tiles at 16px
- Tile types: grass (green, walkable), path (tan, walkable), water (blue, not walkable — fountain), building wall (brown, not walkable), building door (dark brown, walkable — triggers dialogue), field (yellow-green, walkable), tree (dark green, not walkable)
- All one map, no interiors
- Player spawns at their house
- NPCs placed at their positions per the design doc
- Village exit at the top of the map

**NPC placement:**

| NPC | Position | Trigger | Quest State for Dialogue |
|-----|----------|---------|------------------------|
| Tavern Keeper | Inside tavern area | interact | EXPLORE_VILLAGE: gossip + warmth. GOT_QUEST: "Off on an errand?" |
| Tavern Patron 1 | Tavern area | interact | One flavor line |
| Tavern Patron 2 | Tavern area | interact | One flavor line |
| Kid 1 | Near fountain | interact | One flavor line |
| Kid 2 | Near fountain | interact | One flavor line |
| Old Man (couple) | Bench near square | interact | Sweet line + one haunting hint |
| Old Woman (couple) | Bench near square | interact | Sweet line |
| Farmer 1 | Fields | interact | Friendly wave |
| Farmer 2 (Dad) | Fields | interact | EXPLORE_VILLAGE: "Have a good day." GOT_QUEST: "Be safe out there." |
| Farmer 3 | Fields | interact | Flavor line |
| Claira | Square near fountain | auto | EXPLORE_VILLAGE: banter, teasing. Advances to TALKED_TO_CLAIRA. |
| Elder | Elder's house | auto | AT_ELDER: tea, warmth, the errand. Advances to GOT_QUEST. |

**Quest-triggered events on the village map:**
- Player reaches Claira → auto dialogue → state: TALKED_TO_CLAIRA → Claira follows
- Player reaches tree area with Claira following → cinematic: kiss moment → state: WALKING_TO_ELDER
- Player reaches elder's house → auto dialogue with elder → state: GOT_QUEST → Claira stops following, stays at elder's house
- Player reaches village exit → scene transition to road

#### Road (`scenes/overworld/road.tscn`)
- Simple linear path, ~10x30 tiles
- Player walks forward
- Critter NPC at midpoint — auto-trigger starts tutorial battle
- After battle: continue to end of road
- Reaching the end triggers scene transition to homestead
- Grass and path tiles only, some trees on the sides

#### Homestead (`scenes/overworld/homestead.tscn`)
- Tiny scene, ~10x10 tiles
- One building, one NPC (homestead resident)
- Talk to NPC: deliver package, receive trinket (normal dialogue)
- State advances to RETURNING
- Walking to exit: text overlay — "You see smoke on the horizon."
- Scene transition to village_destroyed

#### Village Destroyed (`scenes/overworld/village_destroyed.tscn`)
- Same layout as village map but with darker tile palette
- Ruined building tiles replace normal ones
- No NPCs except Claira
- Claira is near the elder's house area, behind a fading barrier (glowing tile or simple visual)
- Walking to Claira → cinematic overlay: grandmother's barrier fading, pull her out
- State: FOUND_CLAIRA
- Walking to village exit → cinematic: "The trinket, Claira, and the road ahead."
- State: LEAVING → end of opening MVP

### Scene Transition Manager

#### SceneManager (`scripts/overworld/scene_manager.gd`)
- Autoload/singleton that handles scene transitions
- `transition_to(scene_path: String)` — fade to black, load scene, fade in
- Simple ColorRect overlay that tweens alpha
- Carries quest state across scenes

### Integration with Battle System

The tutorial fight on the road:
- When critter auto-triggers, SceneManager transitions to `scenes/battle/battle.tscn`
- Pre-fight UI is skipped or simplified — player has only the protagonist, one hex, auto-placed
- Enemy encounter: 2 weak critters (simpler than the goblin test encounter)
- After battle won, SceneManager transitions back to road scene, player continues
- Need a way to pass encounter data and return point to the battle scene

#### Tutorial Encounter (`scripts/data/encounter_data.gd`)
Add a static method `tutorial_encounter() -> EncounterData`:
- 2 Slimes: low stats, basic melee attack, no abilities
- Simple enough to win with just the protagonist

#### Battle Scene Modifications
- Accept an encounter parameter (which enemies to spawn)
- Accept ally data parameter (which allies to use — just protagonist for tutorial)
- Skip pre-fight placement for tutorial (auto-place protagonist)
- On win: emit signal / call SceneManager to return to overworld
- On lose: game over → reload from village (quest state reset to GOT_QUEST)

## File Structure

```
scripts/
├── data/
│   ├── dialogue_data.gd          # All dialogue content
│   ├── quest_state.gd            # Quest state machine
│   └── encounter_data.gd         # (modify) Add tutorial_encounter()
├── ui/
│   ├── dialogue_box.gd           # Bottom text box
│   ├── cinematic_overlay.gd      # Full screen story overlay
│   └── dialogue_manager.gd       # Plays dialogue sequences
├── overworld/
│   ├── player.gd                 # Grid movement + interact
│   ├── npc.gd                    # NPC with dialogue + trigger mode
│   ├── follow_npc.gd             # Companion NPC that follows player
│   ├── village_map.gd            # Village scene script
│   ├── road_map.gd               # Road scene script
│   ├── homestead_map.gd          # Homestead scene script
│   ├── village_destroyed_map.gd  # Destroyed village scene script
│   └── scene_manager.gd          # Scene transitions (autoload)
└── battle/
    └── battle_manager.gd         # (modify) Accept encounter params, skip pre-fight option

scenes/
├── overworld/
│   ├── village.tscn
│   ├── road.tscn
│   ├── homestead.tscn
│   └── village_destroyed.tscn
└── ui/
    ├── dialogue_box.tscn
    └── cinematic_overlay.tscn
```

## Open Questions (Post-MVP)
- Player sprite art
- NPC portraits in dialogue
- Village tile art
- Interior scenes for tavern and player house
- Music and ambient sound
- The road to Town 2 after the opening
- Trinket UI / buff display
- Secrets and optional discoveries in the village
