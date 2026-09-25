# Town Visual Production and Review

Status: representative environment frames rendered on the target Mac with Godot 4.7.2 Metal Forward+ on 25 September 2026. This is a coherent art increment for review, not final acceptance of a realistic town or a human-played mission.

The user explicitly rejected the initial raw box buildings and weapon as the intended result and authorized Blender custom modeling/adaptation where free assets could not form a coherent grounded 1944 European look. The setting is a fictional European town; factions, exact region and month remain open. The selected G01-07 through G01-12 images guide form and mood but are research references, not game texture sources. [Art direction](ART_DIRECTION.md) records the confirmed and provisional choices.

## Current visible implementation

- Two native-Blender-authored 9 × 16 m exterior house variants replace the visible masses on ordinary plots. They have pitched slate roofs, recessed closed windows/doors, shutters, cornices and chimneys. Their editable `.blend`, exported GLBs and map rights are itemized in [environment asset screening](ENVIRONMENT_ASSET_SCREENING.md). The exterior shells are non-colliding visuals over the existing plot collision bodies; their doors are closed and cannot promise an inaccessible interior.
- `scripts/world/service_wing_visual.gd` builds purpose-sized 2.5–7 m passage wings with real door/window openings in the visual wall, recessed glazing, closed timber doors, plinths and pitched roofs. The wings do not compress the 9 m house model or change the passage footprint. Per-wing visual geometry is grouped into six material meshes.
- `scripts/world/town_presentation.gd` adds shared PBR cobble/mud surfaces, interrupted low curbs, modest puddles, colliding roadside crates/barrels, discarded timber and small clustered masonry rubble. The new crate/barrel footprints are registered as guard AStar obstacles with the same 0.55 m route clearance as other solid world objects; the roofed passages and player route remain open. `scripts/world/town_level.gd` adds the CC0 overcast HDRI, subdued daylight, stone boundary walls, the contact-room window wall, visible stair treads over the original traversable ramp, desk/chair, wood floor joints, and separate clothed contact/scout visuals. Both NPC models rest at floor height while the mission interaction anchors remain unchanged. Their GLBs contain no collision or damage behavior.
- Cobblestone and sky downloads, authors, hashes and CC0 rights are recorded in [asset provenance](ASSET_PROVENANCE.md). The weapon and character visual work have their own [weapon](WEAPON_CHARACTER_ASSETS.md) and [character](CHARACTER_PRODUCTION.md) records.

## Rendered evidence

The model-only inspection script `tools/art/render_architecture_preview.gd` regenerates the two-house asset image [preview_townhouses.png](media/preview_townhouses.png). The playable-scene script `tools/art/render_town_street_preview.gd` loads the real `scenes/main.tscn`, starts the mission, places the player camera at fixed route positions and saves 1280 × 720 frames after rendering. It completed with exit code 0 and `result=0` for every town PNG under Metal Forward+. These are camera inspections, not input-driven navigation or a packaged-build run.

| View | Evidence | What it verifies |
| --- | --- | --- |
| Spawn and first west lane | [town_spawn_preview.png](media/town_spawn_preview.png) | House silhouettes, cobble scale, cloudy sky and nearby road dressing in the playable scene. |
| Central approach | [town_approach_preview.png](media/town_approach_preview.png) | Long side façades and the stone boundary surface at route scale. |
| Contact entrance and stairs | [town_contact_entry_preview.png](media/town_contact_entry_preview.png) | The collision-backed ramp remains legible as stairs and reaches the upper room. |
| Contact interior | [town_contact_room_preview.png](media/town_contact_room_preview.png) | The civilian stands on the upper floor beside the desk and packet; wood joints break up the floor texture. |
| Narrow covered passage | [town_narrow_passage_preview.png](media/town_narrow_passage_preview.png) | The 2.5–3.5 m wings keep normal-sized closed doors and roof pitches on either side of the original passage. |
| Far extraction shelter | [town_exit_preview.png](media/town_exit_preview.png) | Stone boundary, low slate shelter roof, posts, localized rubble and the field-clothed scout are visible. |
| Scout at interaction distance | [town_scout_close_preview.png](media/town_scout_close_preview.png) | Muted khaki workwear, relaxed empty hands, front-facing body and grounded shoes are visible without the old green box. |

The final source-level `tests/guard_regression.gd` exited 0 with 31 checks, including covered-passage clearance and recursive verification that both mission NPC visual trees contain no collision or damage handler. `tests/mission_regression.gd` exited 0 with `MISSION REGRESSION PASS`, including contact, extraction and restart behavior. Local raw outputs are retained under ignored `build/qa/environment_visual/{guard_regression,mission_regression,render_preview}.log`. Headless Godot still logs a dummy-renderer null-material message during mission restarts and sandbox-denied user-log writes; the Metal render run exited 0 and saved all seven frames without those diagnostics. These checks do not establish a human-played or packaged-build pass for this new art.

## Review limits

The repeated domestic exteriors, simple weathering and long boundary wall are still visibly game-like; the first art increment does not meet a finished real-world visual target by itself. The contact room is functional and furnished only at a minimal level. The extraction scout is a static clothed visual without idle animation. A fixed-camera screenshot cannot verify route readability while moving, occlusion during combat, animation, frame-rate stability across the full 410 m town, or performance in the packaged app. Those need the full rendered mission and package checks after all runtime visuals are frozen.
