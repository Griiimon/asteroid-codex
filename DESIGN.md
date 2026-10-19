# Asteroids — Mini Game Design

## Goal
Build a small, playable Asteroids-style arcade game in **Godot 4**, with no external assets. Keep the implementation simple enough to complete in one pass.

## Gameplay
- The player pilots a triangular ship in a wraparound 2D space field.
- **Left / Right** rotate; **Up** thrusts forward; **Space** fires; **Enter** starts or restarts.
- Destroy rocks for points. Large rocks split into two medium rocks; medium rocks split into two small rocks; small rocks disappear.
- The ship has 3 lives. A brief spawn grace period prevents instant repeated collisions. Lose all lives and show a game-over screen.
- Clear all rocks to spawn a fresh wave, with the wave number increasing and a modest difficulty increase.

## Visual Direction
Use a black background, thin white line art, and a restrained arcade look. Draw the ship, asteroids, and bullets with Godot `draw_*` primitives in `_draw()`; generate irregular polygon vertices for rocks. Render score, lives, wave, and title/game-over prompts with `draw_string()` and Godot's fallback font. No downloaded images, fonts, audio, or other assets are needed.

## Implementation Constraints
- Prefer a single `Node2D` scene and one `main.gd` script containing movement, spawning, collision checks, drawing, HUD, and game state.
- Include only the essential project files: `project.godot`, `main.tscn`, and `main.gd`.
- Use Godot 4 GDScript syntax. Keep entities as simple arrays/dictionaries; avoid plugins, shaders, custom resources, and unnecessary scene hierarchies.
- Use a 960×640 window. Wrap the ship, rocks, and bullets at screen edges. Keep gameplay readable and responsive; modest arcade physics are sufficient.
- Handle collisions simply with distance checks. Remove expired bullets and destroyed rocks safely while iterating.

## Acceptance Criteria
1. The project opens and runs in Godot 4 without parse errors or missing assets.
2. The ship rotates, thrusts, wraps at edges, and fires visible bullets.
3. Rocks move, wrap, take bullet hits, split at the correct sizes, and award points.
4. Ship collisions remove a life; the game ends at zero lives and Enter restarts it.
5. Clearing a wave starts the next wave; score, lives, and wave are visible throughout play.
6. All game graphics are procedural and drawn in code.
