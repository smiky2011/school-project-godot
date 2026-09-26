# Claude Code Session Handoff (26 September 2026)

Status: record of work done by Claude Code between Codex sessions, written so Codex (Astra/Sol) can resume. The user asked Claude Code to take over, compare the game with AAA shooters, and above all close the gap to the selected Hell Let Loose references (`reference/games/G01-07`..`G01-12`). Design rules in [GAME_VISION.md](GAME_VISION.md) are unchanged. Everything below is implemented and tested unless marked open.

## Commits in this session

| Commit | Summary |
| --- | --- |
| `75ac3f2` | Added `CLAUDE.md` (guidance file for Claude Code). |
| `0c39204` | Committed Codex's pending 16fa7347 QA/doc edits unchanged, with the user's approval, as the baseline. |
| `6520c6f` | Data-driven Sten handling and combat feedback; research note [SHOOTER_BENCHMARKS.md](SHOOTER_BENCHMARKS.md). |
| `ba76ef6` | First visual pass toward the references (lighting, materials, ground, dressing, backdrop). |
| (this commit) | Second visual pass: lower-sun sky, facade damage, rooflines, pavements, carts, wool sleeves, compact HUD, this handoff. |

## 1. Research

[SHOOTER_BENCHMARKS.md](SHOOTER_BENCHMARKS.md) compares AAA practice (Rainbow Six Siege recoil, Modern Warfare layered and reflected audio, Counter-Strike spread vs recoil, Skyrim modular kits, Sunset Overdrive trim sheets, Far Cry 5 rule-based placement, texel density) with this project. Every source is labeled primary, talk notes or secondary. It ends with the gap table that drove the work below.

## 2. Weapon feel (commit `6520c6f`)

The user later said these features are "fine but not very necessary"; the style gap mattered more. They are complete and tested, so they stay.

- `scripts/player/weapon_profile.gd`: Sten data. Authored recoil pattern (first shot exact) with recovery, separate spread cone (movement, air, crouch, bloom), ADS time 0.22 s and 62% move speed, sprint-to-fire 0.2 s, head hits x3 (sphere test at `guard.get_head_center()`), range falloff beyond 30 m. **Confirmed rules kept:** 30 rounds, reload required, unlimited reserve. **Changed:** an empty magazine now takes 2.45 s (the open-bolt Sten is re-cocked); a tactical reload stays 1.9 s. `tests/mission_regression.gd` waits 2.7 s for this. All numbers are provisional tuning.
- `scripts/player/player.gd`: uses the profile; recoil offsets are on the head and camera, not the player's own aim; `notify_incoming_fire()` feeds the near-miss sound, suppression and hit-direction data.
- `scripts/player/weapon_presentation.gd`: spring recoil, mouse-lag sway, breathing, sprint pose, bolt jerk on empty reload, flash cards, barrel smoke, ejection port. Viewmodel meshes render on layer 2, so decals skip them.
- `scripts/audio/sound_synth.gd`: procedural layered shot (crack, thump, bolt ring) plus a separate tail chosen by `_probe_space()` (open, street, interior), reload foley, dry click, near-miss snap, impacts and footsteps (`town_level.get_ground_surface()`).
- `scripts/fx/combat_fx.gd` and `fx_textures.gd`: pooled bullet-hole decals, dust, chips, sparks, body-hit puffs, moving tracers, ejected shells that stay on the ground, and static decals (scorch, shell holes).
- `scripts/actors/guard.gd`: visible tracer, impact and report for every shot, plus a visual flinch on hits. **Hit rules, damage, AI timing and detection are unchanged.**
- HUD: the crosshair hides while aiming; hit markers are white (hit), gold (head) or red (kill).

Evidence: [ADS hit frame](media/claude_combat_ads_hit.png); `tests/rendered_combat.gd` passed (first aimed shot hit, kill in 4 aimed shots, empty reload 2.48 s).

## 3. Visual style pass

The biggest gaps from the references were flat light, identical box-like houses, an empty mud field, no war traces and an arena wall. Frames after the pass: [spawn street](media/claude_style_spawn.png), [east street](media/claude_style_east_street.png), [ruin square](media/claude_style_ruin_square.png), [courtyard](media/claude_style_courtyard.png), [town edge](media/claude_style_town_edge.png).

| System | File | What it does |
| --- | --- | --- |
| Light and atmosphere | `scripts/world/town_atmosphere.gd` | CC0 `kloofendal_38d_partly_cloudy_puresky` sky. The sun direction is measured from the HDRI's brightest pixel (38 degrees up), and the sky is yawed -19 degrees so light rakes across the N-S streets. AgX tonemap, SSAO, SSIL, SSR, glow, light aerial fog, 4-split shadows. **Keep the default shadow bias:** larger normal bias, blur or `light_angular_distance` erased the near-field house shadows. |
| Facades | `scripts/world/facade_variation.gd` | Per house: scanned rubble stone (`rock_wall_13`) or weathered plaster (`damaged_plaster`) with tint variants, shutter paint, slate shade, second brick chimney stack, clay pots, doorstep, and a canvas or striped awning on about 30%. Roof height varies from 95% to 112% (`town_presentation.gd`). |
| Ground | `scripts/world/town_ground.gdshader`, `town_ground.gd` | One shader blending cobbles, mud (settling into sett gaps first), brick grit, puddles (glossy, reflected by SSR) and weedy edges by world noise. The noise is baked with `FastNoiseLite.get_seamless_image`; `NoiseTexture2D` generated late and read as solid mud. `debug_layers` shows the masks. |
| Dressing | `scripts/world/town_dressing.gd` | Rule-based and seeded: weeds and grass tufts at wall bases, flagstone pavements and curbs on street-facing facades, brick and stone drifts, rubble heaps, shell-hole and bullet-pock decals on about 30% of houses, sandbag positions, tarped dumps, jerrycans, benches, buckets, cast-iron street and wall lamps, two telegraph lines, trees, three wrecked carts, two shelled ruins with a smouldering fire, and a radio set, oil lamp and bookshelf in the contact room. |
| Beyond the town | `scripts/world/town_backdrop.gd` | The outer 4 m wall visuals are hidden (collision kept), replaced by a 1.5 m field wall and a double hedgerow of scanned shrubs, plus 1.6 km of fields, edge trees that become cards at 140 m, horizon tree cards, six distant farms and three smoke columns. |
| Arms and HUD | `assets/player/gloved_hands.gd`, `scripts/ui/hud.gd` | Wool sleeves (hessian weave normal, olive drab, creases, UVs) replace the plain tubes. HUD plates are smaller and translucent, with text shadows; the information shown is unchanged. |
| Shared | `scripts/world/pbr_library.gd` | Cached PBR materials and model loading for the CC0 folders. |

**Gameplay safety:** every solid dressing piece uses `_solid_box()`, which adds a collider and registers the footprint in `town_level._obstacles` before the guard path grid is built. `KEEP_CLEAR` in `town_dressing.gd` keeps the core courtyard, all covered passages, the spawn and the scout shelter free of solid props. Pavements, curbs, rubble drifts, weeds and courtyard debris have no collision.

**Assets:** 27 Poly Haven CC0 downloads through `tools/art/fetch_polyhaven.py` (MD5-checked, `PROVENANCE.json` per folder, listed in [ASSET_PROVENANCE.md](ASSET_PROVENANCE.md)). The 3.9M-triangle jacaranda scan is reduced to `assets/environment/trees/town_tree.glb` (143k triangles) and a billboard card by `tools/art/build_tree_lod.py`. The 208 MB source `.bin` is Git- and import-ignored; re-fetch it with `python3 tools/art/fetch_polyhaven.py model jacaranda_tree 1k`. No account or payment was needed.

**Review tool:** `tools/art/render_style_review.gd` renders 12 fixed camera views to `build/qa/style/` (or `STYLE_OUT`). Set `STYLE_ONLY=<prefix>` for one view and `STYLE_HUD=1` to keep the HUD. Compare its output side by side with `reference/games/G01-*`.

## 4. Validation (final tree, M4 Pro, Godot 4.7.2 Metal, 1280 x 720)

- Headless: `mission_regression` PASS (40), `guard_regression` PASS (31), `player_stance_regression` PASS (9).
- Rendered covered route: PASS, 202.85 s, zero kills, 100 health, 12 guards after lockdown, about 119 FPS average, 97 minimum.
- Rendered direct-west route: PASS, 207.95 s, zero kills, 118 FPS average, 76 minimum, 10.2 ms p95 frame time.
- Rendered combat probe: PASS.
- **Intermittent:** the first run right after a large asset reimport failed once each for `mission_regression` ("Upstairs contact is reachable") and the covered route (shot near the residence). Two immediate reruns of each passed, and a direct probe showed a clear line to the contact. Likely load-timing sensitivity in wall-clock-driven tests; rerun before treating it as a regression.
- **Not done:** a human playthrough of the new build, and a rebuilt Mac package. `build/1944 Town Mission.app` still holds the older 16fa7347 PCK; run `bash tools/build_macos.sh`. The PCK will grow by roughly 90 MB of textures and models.

## 5. Open items for Codex, in priority order

1. Rebuild the package, then do an exact-PCK route and a human play session. Record FPS with the new dressing.
2. **User decision needed:** painted wall advertisements and shop signs, a strong reference cue ("BIERE FRANCAISE", "CHERBOURG"), were left out because text language implies a region, and region, month and factions are still open. Ask the user before adding language-specific signage.
3. Guards still walk with baked stride morphs. Skeletal locomotion (for example a CC0 animation library retargeted in Blender to the MakeHuman rig) is the next big realism gain for characters.
4. The core courtyard walls (`Core west edge` and `Core east edge`, 4 m) still read as arena walls; consider damage, a lower visual height or dressing.
5. Tune the weapon numbers after human play (recoil, spread, ADS move speed), following the project's mechanics-before-tuning rule.
6. Possible performance levers if needed: hedgerow shrub count (`town_backdrop.gd`), tree count, SSIL, the 4-split shadow distance of 140 m.
