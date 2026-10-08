# Town map and movement demo

This separate Godot 4.7.2 project shows the existing town layout, building
shells, roads, set dressing, and collision with a first-person character. It
opens on the central street. WASD moves, the mouse looks, Shift sprints, Space
jumps, Esc releases the mouse, and a click recaptures it. There are no guards,
weapons, combat, mission objectives, or extraction flow in this demo.

The playable mission remains in the repository root. `scripts/demo_map.gd` is
a focused copy of its town generator: house placement, streets, collision,
residence, lighting, dressing, and backdrop are kept. The shared world scripts
and visual assets are copied unchanged from the existing project during setup.
The copy includes the town Blender source and available asset provenance and
license files. Generated imports and copied assets are local outputs, excluded
from Git; the branch tracks this independent project's authored source and the
setup recipe.

From the repository root, run:

```sh
python3 tools/create_map_movement_demo.py
/Users/quan/Downloads/Godot.app/Contents/MacOS/Godot --headless --path demos/map_movement --import
/Users/quan/Downloads/Godot.app/Contents/MacOS/Godot --path demos/map_movement
```

After setup, `demos/map_movement` is self-contained and can be copied to a new
location. The setup script can be rerun to refresh its unchanged shared files.
This is a focused demonstration of the current map and movement work, not a
new claim that the complete mission has passed a human playtest.

The included checks can be run from the repository root:

```sh
/Users/quan/Downloads/Godot.app/Contents/MacOS/Godot --headless --path demos/map_movement --script res://tests/smoke.gd
/Users/quan/Downloads/Godot.app/Contents/MacOS/Godot --path demos/map_movement --script res://tests/visual_review.gd
```

The first checks map creation, walking, jumping, Esc/click controls, and a
house collider. The second writes a rendered starting-view image to
`/private/tmp/town_map_movement_spawn.png`. These scripted checks do not
replace someone manually walking through the demo.
