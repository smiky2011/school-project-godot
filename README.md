# 1944 Town Mission

This is a first playable, offline, single-player Godot mission in a fictional European town in 1944. Infiltrate the town, wait for a safe exchange with an upstairs contact, carry copied counterattack plans through a scripted lockdown, and deliver them to a sheltered scout. Combat is optional; a zero-kill completion is supported. The exact region, month and factions are not selected.

From the repository root, open the project in Godot 4.7.2 and press **F5**, or launch from Terminal:

```sh
'/Users/quan/Downloads/Godot.app/Contents/MacOS/Godot' --path .
```

For a self-contained local Mac app, run `bash tools/build_macos.sh` from this directory and open `build/1944 Town Mission.app`. It embeds the Godot runtime and needs no project checkout after packaging. See [packaging instructions](docs/PACKAGING.md).

Use **WASD** to move, mouse or arrow keys to look, **Shift** to sprint, **Ctrl/C** to crouch, **E** to interact, **F** for a quiet rear takedown, left click or **G** to fire, **R** to reload, and **Esc** to pause. Hold E at the contact; press it once at extraction. See [playing instructions](docs/PLAYING.md).

The town and weapon are still blockout art with a small set of free CC0 asset samples. Provenance is in [asset records](docs/ASSET_PROVENANCE.md). The exact packaged game completed a known input-driven zero-kill route in about 3:23. The intended roughly ten-minute human pace and final presentation remain open to playtesting. See the [design index](docs/PLAN_INDEX.md) and [QA report](docs/QA_REPORT.md) for current evidence and limits.
