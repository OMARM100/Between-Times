# Systems

## Current known systems
- Player
- Movement
- Camera
- Interaction
- Doors
- Enemies / AI
- Multiplayer
- Level management
- Save / Load
- UI
- Audio

## Rule
Before changing a working system, inspect its current implementation and dependencies. Avoid duplicate systems and unnecessary rewrites.

## Current system status
### Player / Movement / Camera
- Prototype implementation exists in `scripts/player_controller.gd`.
- Player uses Godot 4 `CharacterBody3D`.
- Current features: WASD movement, mouse look, gravity, jump, sprint, acceleration, and collision-ready capsule.
- Prototype scene: `scenes/player.tscn`.
- Test environment: `scenes/test_arena.tscn`.
- Runtime verification is still pending because Godot is not available in the current execution environment.
