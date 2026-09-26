# AAA Shooter Benchmarks: Weapons and Assets

Status: research note written by Claude Code on 26 September 2026, after the user asked for a comparison with AAA, shooter and open-world games before further production. It records how those games plan the shooting system and the art assets, and turns that into a gap list for this project. Findings are labeled by evidence level: **primary** (a developer or publisher page I opened), **talk notes** (a third-party transcript or notes of a developer talk I opened), and **secondary** (search summaries, wikis or community pages I did not verify against a developer source). What was implemented from this note is recorded in [CLAUDE_HANDOFF.md](CLAUDE_HANDOFF.md).

## The target restated

The user rejected the first graybox ("毛胚房", a bare shell) and asked for a grounded, real-world 3D shooter look ([ART_DIRECTION.md](ART_DIRECTION.md)). The six selected references are Hell Let Loose screenshots. The confirmed mission rules in [GAME_VISION.md](GAME_VISION.md) do not change: one SMG, 30-round magazine, required reload, unlimited reserve, optional combat, zero-kill completion, finite reinforcements.

## How AAA shooters plan the shooting system

### 1. Gun feel is designed as a whole, not as one number

Battlefield 6's GDC session frames game feel as the alignment of player intent with the game's audio-visual response, with "gun feel" at the center of its first-person combat (secondary: GDC schedule listing). In practice every shot is a bundle of synchronized responses: camera and viewmodel kick, muzzle flash and light, sound layers, an impact at the target, and a reaction from whatever was hit. A shooter feels thin when only the ammo counter and hit points change.

### 2. Recoil is a learnable pattern; spread is a separate, smaller random term

- Rainbow Six Siege replaced a random "diamond" recoil with multi-stage, authored patterns. The first bullet "always goes exactly where you are aiming", later bullets follow a predetermined sequence, and weapons are grouped into families that share a pattern. The stated goal was never letting the player feel "cheated out of a skillful shot" (primary: Ubisoft recoil overhaul).
- Counter-Strike separates **recoil** (a fixed per-shot table that resets after a short pause) from **inaccuracy** (random, raised by moving, jumping and sustained fire, recovered faster when crouched). The first shot has the best accuracy (secondary: community wiki).

Rule taken: authored recoil pattern with recovery, plus a small random spread cone that grows with movement and sustained fire and shrinks when aiming or crouched. First shot accurate.

### 3. Realism shooters trade crosshairs for sights, sway and suppression

- Insurgency: Sandstorm has no on-screen crosshair, relies on iron sights, adds sway that grows as stamina drops and under fire, and uses a hybrid ballistic model that behaves like hitscan for the first 100 ms before simulated flight (secondary: search summary of Epic's spotlight, whose page returned 403 to me).
- Battlefield 3 introduced suppression: near misses blur the view and widen spread to push players into cover (secondary: fan wiki).
- Hell Let Loose, the user's chosen visual reference, is in the same realism family; its player discussions center on weapon weight, sway and suppression (secondary: Steam discussions).

Rule taken: keep a minimal hip crosshair (this mission is not a hardcore sim and has a ten-minute target), hide it while aiming down sights, add breathing and movement sway, and make incoming fire readable through near-miss effects instead of silent hit-scan damage. Town engagement distances (under 60 m) make pure hitscan acceptable.

### 4. Sound is layered and aware of the space

Infinity Ward built Modern Warfare's weapon audio from separate layers (direct report per operating mechanism, mechanical detail, shell ejection "travelling in 3D space") plus three environmental systems: reverb and slap delay, a contextual atmospheric layer, and a reflection system in which "the game knows where the sound will interact with the environments". Open spaces give "big, deep, booming" echoes; confined spaces are more muffled with less echo. They recorded with about 90 microphones per shot, 20 of them for the player perspective (primary: Activision blog).

Rule taken: layer the Sten's report (crack, low thump, bolt mechanics, tail) and change the tail with the space around the player, measured with a few raycasts.

### 5. "Juice" and permanence

Vlambeer's "Art of Screenshake" demo turns a flat prototype into a satisfying one with about 30 small tricks, among them muzzle flash, gun kickback, camera shake on fire, enemy hit animations, brief hit-pause, and permanence such as spent shells and remains that stay in the world (secondary: talk summaries). AAA shooters apply the same principles at higher fidelity: bullet holes and dust at impacts, blood or cloth puffs on hits, visible tracers.

### 6. Hit and damage feedback

Modern shooters confirm hits with hit markers, distinguish kills and headshots, react the enemy's body to where it was hit, and show the player where incoming damage comes from with a directional indicator and a screen-edge vignette (secondary: UX analysis and design wiki). Hit-location damage (head vs body) turns aim precision into a strategy.

### 7. First-person animation is a planned set

First-person weapon packages ship a standard state list: idle, walk, sprint, ADS in/out and aimed idle/walk, fire and aimed fire, tactical reload (magazine not empty) and empty reload, equip/holster, inspect. Tactical and empty reloads are deliberately distinct (secondary: animation vendor guides). For the Sten, an open-bolt SMG, the historically grounded distinction is that an empty magazine also needs the bolt re-cocked.

## How AAA teams plan assets

### 1. Modular kits, then clutter, then lighting

Bethesda's Skyrim dungeon team built seven architectural kits that produced "well over 400" interiors with two full-time artists supporting eight level designers. Rules: one uniform footprint with snapping at half the footprint; pieces live inside their bounds; decide pivots early; stress-test kits by looping and stacking them; avoid hero pieces early; hide repetition by varying clutter (players notice repeated small details sooner than repeated architecture), kit-bashing between kits and good lighting with ambient occlusion (talk notes: Game Developer write-up of the GDC 2013 talk). The Level Design Book adds a standard piece list (wall, floor, doorway, window, corner, glue pieces) and says texture variations are cheap because they do not re-validate geometry (primary: Level Design Book).

### 2. Trim sheets and tileables cover most surfaces

Insomniac's Sunset Overdrive paired a standardized trim layout with 45-degree bevel normals so any material could be swapped without new UVs; each material had "a trim and a plain tileable version" that together "cover any surface" (talk notes: GDC 2015 transcript).

### 3. Scanned and hand-made assets are mixed

DICE used photogrammetry for Star Wars Battlefront environments and cut per-asset production from about two weeks to one (secondary: talk coverage; the Game Developer page I opened only announces the talk). Hell Let Loose's maps mix mostly hand-crafted assets with some Megascans and temporary MAWI blockout pieces (secondary: search summary of ArtStation pages). For this project the free equivalent is CC0 scanned assets from Poly Haven.

### 4. Texel density is consistent, with deliberate exceptions

Keep texel density consistent between assets seen at the same distance; first-person weapons, cinematic and inspectable objects are the accepted exceptions (primary: Beyond Extent deep-dive). Community guidance cites roughly 256–512 px/m for environment and about 1024 px/m for first-person weapons (secondary).

### 5. Open worlds place content by rules, with manual overrides

Far Cry 5's Houdini pipeline spawned vegetation by per-species "viability" scores from slope, altitude, occlusion and flow maps, with priorities (trees over bushes), viability radius and age parameters. Designers painted sub-biomes, and splines for roads, fences and power lines cleared or placed content automatically. The team's lesson was to balance automation with control (talk notes: GDC 2018 notes).

Rule taken: this town is small enough for hand placement, but dressing should follow rules (weeds at wall bases and yard edges, props near doors and shop fronts, sandbags at checkpoints, poles and wires along streets) rather than being scattered evenly.

## Gap analysis for 1944 Town Mission

State at takeover, from code and the Codex-era screenshots in [media](media/).

| Area | AAA practice | This project at takeover | Action |
| --- | --- | --- | --- |
| Recoil | Authored pattern, first shot exact, recovery | Fixed 0.008 rad pitch per shot, no recovery or horizontal pattern | Data-driven pattern with recovery |
| Spread | Random cone by movement, sustained fire, stance | None: every bullet on the exact center ray | Add spread model |
| ADS | Sights, lower FOV, slower movement, crosshair hidden | FOV 76→62 and a pose; crosshair stays; full speed | Aim time, move penalty, crosshair hidden, sway |
| Sprint | Weapon lowered, sprint-to-fire delay | Can fire while sprinting | Lowered pose and fire delay |
| Reload | Tactical and empty variants | One 1.9 s reload | Tactical 1.9 s; empty adds bolt re-cock |
| Hit zones | Head, body, falloff | Every hit 34 damage | Head multiplier, range falloff |
| Impacts | Decals, dust, blood | None | Decals and particles by surface |
| Muzzle | Flash sprite, light, smoke, shells | Glowing sphere and light | Flash cards, smoke, shell ejection, tracers |
| Audio | Layered, space-aware | One noise burst, no space | Layered synthesis and reflection tail |
| Hit feedback | Hit marker, kill and headshot marks, enemy flinch | Crosshair character swaps to "×" | Drawn markers, flinch, death fall |
| Incoming fire | Tracers, near-miss cracks, direction indicator | Silent 9-damage hitscan | Visible guard fire, near misses, direction indicator |
| Lighting | Filmic tonemap, GI or AO, aerial fog | Default tonemap, SSAO only | AgX, SSIL, fog, tuned shadows |
| Set dressing | Rule-based clutter, vegetation, war traces | Sparse crates, flat mud field | CC0 props, weeds and shrubs, sandbags, wires, damage |
| Repetition | Kit variation, tints, clutter | Two house shells repeated | Per-house tint variation and dressing |
| Characters | Skeletal animation sets | Baked stride morphs | Out of scope for this pass; plan in handoff |

The weapon changes do not alter confirmed rules: one SMG, 30 rounds, reload required when empty, unlimited reserve. Damage, spread and recoil values are provisional tuning, measured in [CLAUDE_HANDOFF.md](CLAUDE_HANDOFF.md).

## Sources

Primary or talk notes, opened on 26 September 2026:

- [Activision: Weapon Sounds in Call of Duty: Modern Warfare](https://blog.activision.com/call-of-duty/2019-07/Modern-Warfare-Initial-Intel-Creating-an-Orchestra-of-Incredible-Audio-Effects-Weapon-Sounds-in-Call-of-Duty-Modern-Warfare)
- [Ubisoft: Rainbow Six Siege weapon recoil overhaul](https://www.ubisoft.com/en-ca/game/rainbow-six/siege/news-updates/1k3EGuOGxKxe6mhOlFBhbj/weapon-recoil-overhaul)
- [Game Developer: Skyrim's Modular Approach to Level Design](https://www.gamedeveloper.com/design/skyrim-s-modular-approach-to-level-design)
- [The Level Design Book: Modular kit design](https://book.leveldesignbook.com/process/blockout/metrics/modular) and [Texturing](https://book.leveldesignbook.com/process/env-art/texturing)
- [GDC 2015 transcript: The Ultimate Trim (Sunset Overdrive)](https://archive.org/stream/GDC2015Olsen2/GDC2015-Olsen-2_djvu.txt)
- [Notes on Procedural World Generation of Far Cry 5](https://christianjmills.com/posts/procedural-tools-far-cry-5-notes/)
- [Beyond Extent: Texel Density](https://www.beyondextent.com/deep-dives/deepdive-texeldensity)

Secondary, from search results only:

- [GDC: Battlefield 6, Game Feel is the Message](https://schedule.gdconf.com/session/battlefield-6-game-feel-is-the-message/915257)
- [Epic spotlight: Insurgency: Sandstorm](https://www.unrealengine.com/en-US/spotlights/how-insurgency-sandstorm-raises-the-bar-for-realistic-first-person-shooters) (403 when opened)
- [Counter-Strike wiki: Recoil](https://counterstrike.fandom.com/wiki/Recoil), [Battlefield wiki: Suppression](https://battlefield.fandom.com/wiki/Suppression)
- [The Art of Screenshake (video)](https://www.youtube.com/watch?v=SkgkIXZ_13Y), [DICE photogrammetry talk](https://www.gdcvault.com/play/1023272/Photogrammetry-and-Star-Wars-Battlefront)
- [Hell Let Loose environment art (ArtStation)](https://www.artstation.com/artwork/WBdAJv), [First-person animation guide](https://mocaponline.com/blogs/mocap-news/first-person-animation-guide), [FPS damage indicator UX analysis](https://medium.com/@jasper.stephenson/a-ux-analysis-of-first-person-shooter-damage-indicators-59ac9d41caf8)
