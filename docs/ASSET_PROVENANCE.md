# Asset Provenance and Screening

Status: production registry, checked 25 September 2026. The mission takes place in a fictional European town in 1944. Its factions and exact architectural region remain open. Selection of an asset does not establish acceptance of the whole level's visual quality.

## Acquired sample

All four items below came from [Poly Haven](https://polyhaven.com/license), whose official asset license states CC0, redistribution allowed, and attribution optional. The individual pages list the same license. Downloads were anonymous and free. Original ZIP packages are retained unchanged under `assets/vendor/polyhaven/source/`; the three extracted diffuse JPGs and the model files keep their upstream filenames. Derived runtime normal/roughness maps and house textures are recorded below and in [ENVIRONMENT_ASSET_SCREENING.md](ENVIRONMENT_ASSET_SCREENING.md). An offline license record is at `assets/vendor/polyhaven/LICENSE.txt`.

| ID | Author and source | Imported candidate | Original package SHA-256 | Use and limit |
| --- | --- | --- | --- | --- |
| PH-01 | Rob Tuytel, [Plastered Stone Wall](https://polyhaven.com/a/plastered_stone_wall) | `assets/vendor/polyhaven/materials/plastered_stone_wall_diff_1k.jpg` | `c95acdcd30000f240b3fd80b026bf5d52089059db483934c40fc74049653a49e` | Weathered façade sample; one 1024² diffuse texture, not a complete façade or material setup. |
| PH-02 | Charlotte Baglioni (photography), Dario Barresi (processing), [Stone Wall](https://polyhaven.com/a/stone_wall) | `assets/vendor/polyhaven/materials/stone_wall_diff_1k.jpg` | `f2a78be356d8084d185f0c5cab3f794ce1ae7ad4288d0784fcb1aba5b78198a4` | Stone wall sample; geographic fit remains unconfirmed. |
| PH-03 | Amal Kumar, [Muddy Tracks](https://polyhaven.com/a/muddy_tracks) | `assets/vendor/polyhaven/materials/muddy_tracks_diff_1k.jpg` | `d43352dc4de21b80d1eab25c0fe846192b4d68f7bc874635f17e1b4bc41ecbff` | Track/soil sample for the town edge; vehicle-track pattern should be placed selectively. |
| PH-04 | James Ray Cock (modeling), Jurita Burger (graphic design), [Wooden Crate 02](https://polyhaven.com/a/wooden_crate_02) | `assets/vendor/polyhaven/wooden_crate_02/wooden_crate_02_1k.gltf` and its `.bin` and 1K JPG textures | `a30e6796d01cf907f698074ad176e9ebfbc486b34dc16d1203edf03b93de070a` | Optional street/interior prop, roughly 1.2 m wide and 5K triangles per source page. Printed letters and visual style need review before repeated placement. No collision shape or animation is supplied. |

The three material packages are 1K Blender ZIP downloads. Their source archives contain `.blend` and texture maps. PH-01/PH-02 diffuse JPGs and converted normal/roughness maps now supply the authored house shells; the originals remain in the archives. PH-03 uses the same original [Muddy Tracks](https://polyhaven.com/a/muddy_tracks) archive (`assets/vendor/polyhaven/source/muddy_tracks_1k.blend.zip`, SHA-256 in the table) for all three runtime channels: its extracted diffuse JPG plus `textures/muddy_tracks_nor_gl_1k.exr` → `assets/world_materials/muddy_tracks_normal.png` (SHA-256 `1ebb2bac6863fdf255e0447e99cf99ea0f277f4c6065953496fe2f99420bc340`) and `textures/muddy_tracks_rough_1k.exr` → `assets/world_materials/muddy_tracks_rough.png` (SHA-256 `316b6e8db99cf70a5a97c2deca590f444a2f2893d379c4505cb304e9ba95aa72`). `tools/art/generate_environment_textures.py` decodes each EXR, clips it to 0–1 and quantizes it to 8-bit PNG; the source EXRs stay unchanged in the ZIP. The model package is the 1K glTF ZIP. Godot 4.7.2 imports the crate and the town gives each roadside instance a project-authored box collider. Keep `source/*.zip` in the repository for provenance but exclude it from the game export.

## Selected visual-production assets

| ID | Author and primary source | Runtime files and original source | Rights, acquisition and use |
| --- | --- | --- | --- |
| PH-05 | Rob Tuytel, [Cobblestone Floor 001](https://polyhaven.com/a/cobblestone_floor_001) | `assets/vendor/environment_visual/polyhaven/cobblestone_floor_001/` contains the original 1K diffuse, OpenGL normal and roughness maps. Their SHA-256 values are `893d3e7b4506c5935cbc6aca5b914d637bd4464484bcaa5d69e2ee205bb9ae9c`, `34e2ace7b704d34ede66643624ac2ed807a769f6ea4a535635111ad945ae0f8f`, and `d6bf0c029cd2fc355bcceaac70753ee1792193af488805527ce987fa0153f4e1` respectively. | [Poly Haven CC0](https://polyhaven.com/license); anonymous free download 25 September 2026. Used for the paved main lane and selected crossings with a 2.4 m material scale. Download recipe: `tools/art/fetch_cobblestone.py`. |
| PH-06 | Jarod Guest / Sky Edits, based on Sergej Majboroda's original, [Overcast Soil (Pure Sky)](https://polyhaven.com/a/overcast_soil_puresky) | `assets/vendor/environment_visual/polyhaven/overcast_soil_puresky/overcast_soil_puresky_1k.hdr`, SHA-256 `2dbbbbb1323a8e8989db2e8306bd13099b215539e5adba41b85738a250a7904e`. | [Poly Haven CC0](https://polyhaven.com/license); anonymous free download 25 September 2026. Used as the subdued cloudy sky and ambient-light source. Download recipe: `tools/art/fetch_overcast_sky.py`. |
| MH-01 | [MakeHuman Community system assets](https://static.makehumancommunity.org/assets/assetpacks/makehuman_system_assets.html), with the selected body, workwear, boots, hair, eyes and skin described in [CHARACTER_PRODUCTION.md](CHARACTER_PRODUCTION.md) | `assets/vendor/character_visual/makehuman/runtime/scout_idle.glb` (SHA-256 `0f673fa440eaf6d156b70a6f119b0c1244bf427ccd37470da046d187132f4751`); editable `source/scout_idle.blend` (SHA-256 `489c598cd622538da5ac20b4241a714b13ad8e61796fdd8aba62f745d344dc8a`); `source/scout_cloth_khaki.png` (SHA-256 `4015469d7f8087023ed4174990ea336148943c513ffc062da3e603bac5cdc21a`). | The selected system pack and MakeHuman output are CC0; no registration or payment. First authoring adapted the local, non-runtime relaxed-arm candidate `previews/guard_workwear_idle.glb` (SHA-256 `7851fcf5200f3264b5cd38de30cc56b5feea693915fa2bfacd96768bb615429f`), warming only the cloth map from gray-green to muted khaki brown. `tools/art/scout_visual.py` now re-exports by default from the retained packed `.blend` without that local candidate; its explicit `--rebuild-from-local-prototype` option documents the original creation path. The runtime model has no gun, insignia, animation or morph targets, and Godot Metal frames show grounded shoes and a visible front-facing silhouette at extraction. |

The two reusable domestic exterior GLBs, their portable native `.blend`, original map transformations, exact filenames and license chain are described in [ENVIRONMENT_ASSET_SCREENING.md](ENVIRONMENT_ASSET_SCREENING.md). The separately adapted Sten and its required CC BY 3.0 attribution are described in [WEAPON_CHARACTER_ASSETS.md](WEAPON_CHARACTER_ASSETS.md). The integrated contact, guard and scout models, retained Blender sources, CC0 chain and baked guard stride morphs are documented in [CHARACTER_PRODUCTION.md](CHARACTER_PRODUCTION.md) and its [source provenance record](../assets/vendor/character_visual/makehuman/PROVENANCE.txt). Contact and scout remain noncolliding interaction visuals at their existing anchors; guard AI and collider rules remain in place. None of the selected downloads required registration or payment.

## Claude Code visual pass (26 September 2026)

All rows below are [Poly Haven](https://polyhaven.com/license) CC0 assets, downloaded anonymously and free on 26 September 2026 with `tools/art/fetch_polyhaven.py`, which verifies each file against the MD5 the Poly Haven API reports. Each folder's `PROVENANCE.json` records source page, authors, license, URLs, sizes and MD5 values. No account, payment or registration was needed. How each asset is used is described in [CLAUDE_HANDOFF.md](CLAUDE_HANDOFF.md).

| Asset | Authors | Folder | Note |
| --- | --- | --- | --- |
| Kloofendal 38d Partly Cloudy (Pure Sky) (`kloofendal_38d_partly_cloudy_puresky`, hdri) | Greg Zaal (original), Jarod Guest (sky edits) | `assets/vendor/polyhaven_cc0/hdri/kloofendal_38d_partly_cloudy_puresky/` |  |
| Jacaranda Tree (`jacaranda_tree`, model) | Rob Tuytel (guidance), Rico Cilliers (all) | `assets/vendor/polyhaven_cc0/model/jacaranda_tree/` | Source only (Git- and import-ignored, re-fetch with the script); reduced to `assets/environment/trees/town_tree.glb` and `town_tree_card.png` by `tools/art/build_tree_lod.py`. |
| Metal Jerrycan Green (`metal_jerrycan_green`, model) | Ulan Cabanilla (all) | `assets/vendor/polyhaven_cc0/model/metal_jerrycan_green/` |  |
| Nettle Plant (`nettle_plant`, model) | Rob Tuytel (photography), Rico Cilliers (modeling) | `assets/vendor/polyhaven_cc0/model/nettle_plant/` |  |
| Old Military Crate (`old_military_crate`, model) | Jack Mava (all) | `assets/vendor/polyhaven_cc0/model/old_military_crate/` |  |
| Painted Wooden Bench (`painted_wooden_bench`, model) | Kirill Sannikov (all) | `assets/vendor/polyhaven_cc0/model/painted_wooden_bench/` |  |
| Shrub 02 (`shrub_02`, model) | Rico Cilliers (all) | `assets/vendor/polyhaven_cc0/model/shrub_02/` |  |
| Street Lamp 01 (`street_lamp_01`, model) | Josh Dean (all) | `assets/vendor/polyhaven_cc0/model/street_lamp_01/` |  |
| Street Lamp 02 (`street_lamp_02`, model) | Josh Dean (all) | `assets/vendor/polyhaven_cc0/model/street_lamp_02/` |  |
| Vintage Oil Lamp (`vintage_oil_lamp`, model) | Monsta3D (all) | `assets/vendor/polyhaven_cc0/model/vintage_oil_lamp/` |  |
| Vintage Radio Transceiver (`vintage_radio_transceiver`, model) | Mateusz Sadek (all) | `assets/vendor/polyhaven_cc0/model/vintage_radio_transceiver/` |  |
| Weed Plant 02 (`weed_plant_02`, model) | Rob Tuytel (photography), Rico Cilliers (modeling) | `assets/vendor/polyhaven_cc0/model/weed_plant_02/` |  |
| Wicker Basket 01 (`wicker_basket_01`, model) | Kuutti Siitonen (all) | `assets/vendor/polyhaven_cc0/model/wicker_basket_01/` |  |
| Wooden Bookshelf Worn (`wooden_bookshelf_worn`, model) | Ulan Cabanilla (all) | `assets/vendor/polyhaven_cc0/model/wooden_bookshelf_worn/` |  |
| Wooden Bucket 01 (`wooden_bucket_01`, model) | James Ray Cock (all) | `assets/vendor/polyhaven_cc0/model/wooden_bucket_01/` |  |
| Wooden Crate 01 (`wooden_crate_01`, model) | James Ray Cock (all) | `assets/vendor/polyhaven_cc0/model/wooden_crate_01/` |  |
| Wooden Military Crate (`wooden_military_crate`, model) | Prabhjinder Singh (all) | `assets/vendor/polyhaven_cc0/model/wooden_military_crate/` |  |
| Brick Gravel (`brick_gravel`, texture) | Dimitrios Savva (all) | `assets/vendor/polyhaven_cc0/texture/brick_gravel/` |  |
| Broken Brick Wall (`broken_brick_wall`, texture) | Amal Kumar (all) | `assets/vendor/polyhaven_cc0/texture/broken_brick_wall/` |  |
| Brown Mud 02 (`brown_mud_02`, texture) | Rob Tuytel (all) | `assets/vendor/polyhaven_cc0/texture/brown_mud_02/` |  |
| Cobblestone Floor 03 (`cobblestone_floor_03`, texture) | Rob Tuytel (all) | `assets/vendor/polyhaven_cc0/texture/cobblestone_floor_03/` |  |
| Damaged Plaster (`damaged_plaster`, texture) | Amal Kumar (all) | `assets/vendor/polyhaven_cc0/texture/damaged_plaster/` |  |
| Hessian 230 (`hessian_230`, texture) | colormass (photography), Rico Cilliers (processing) | `assets/vendor/polyhaven_cc0/texture/hessian_230/` |  |
| Leafy Grass (`leafy_grass`, texture) | Charlotte Baglioni (all) | `assets/vendor/polyhaven_cc0/texture/leafy_grass/` |  |
| Medieval Red Brick (`medieval_red_brick`, texture) | Rob Tuytel (all) | `assets/vendor/polyhaven_cc0/texture/medieval_red_brick/` |  |
| Old Planks 02 (`old_planks_02`, texture) | Rob Tuytel (all) | `assets/vendor/polyhaven_cc0/texture/old_planks_02/` |  |
| Rock Wall 13 (`rock_wall_13`, texture) | Amal Kumar (all) | `assets/vendor/polyhaven_cc0/texture/rock_wall_13/` |  |

Derived project files: `assets/environment/trees/town_tree.glb` (about 143k triangles from the 3.9M-triangle jacaranda scan) and `assets/environment/trees/town_tree_card.png` (a transparent Blender EEVEE side view for distant billboards) are both produced by `tools/art/build_tree_lod.py` from the CC0 source above. Procedural sandbags, grass tufts, rubble mounds, telegraph poles and wires, effect textures and weapon sounds are generated in code and need no license record.

## Bounded shortlist for remaining categories

| Need | Free lead | Current decision |
| --- | --- | --- |
| Building shells, doors, windows and the usable upstairs interior | [Kenney Building Kit](https://kenney.nl/assets/building-kit) and [Modular Buildings](https://kenney.nl/assets/modular-buildings), both CC0 | Screened out for the visible domestic exteriors as too stylized. Two custom exteriors and a mission-specific walkable contact room are now in production; see the dedicated environment record. |
| Furniture | [Poly Haven Painted Wooden Cabinet](https://polyhaven.com/a/painted_wooden_cabinet), CC0, glTF, about 2K triangles | Candidate for the residence after interior dimensions are stable. |
| Rubble | [Poly Haven Rubble](https://polyhaven.com/a/rubble) and [Broken Wall](https://polyhaven.com/a/broken_wall), CC0 textures | Surface samples, not navigable debris meshes; use collision-aware blockout pieces first. |
| Vegetation | [Poly Haven Shrub 03](https://polyhaven.com/a/shrub_03), CC0, source page lists LODs and 17K triangles | Screen size/performance before placement. Tree candidates found were much heavier; use sparse low-detail blockout vegetation until measured. |
| Submachine gun | [Sketchfab Thompson M1928](https://sketchfab.com/3d-models/thompson-m1928-low-poly-52e1701ca8ef48438948d3eb2de42302) and [MP 40](https://sketchfab.com/3d-models/mp-40-7f699510d9a44f96820aa4988a04da50), both listed CC BY by their creators | **Historical shortlist, unselected.** Either implies a faction/context choice; parts, first-person suitability and import are unverified. [Sketchfab's download API documentation](https://sketchfab.com/developers/download-api/downloading-models) says account authentication is required. The free, anonymously acquired CC BY 3.0 Sten Mk II is now the selected runtime visual; see [WEAPON_CHARACTER_ASSETS.md](WEAPON_CHARACTER_ASSETS.md). |
| Guard/contact/scout characters and animation | [Kenney Animated Characters Survivors](https://kenney.nl/assets/animated-characters-survivors), CC0; [Adobe Mixamo](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html), free for games with an Adobe ID | These remain screened-out alternatives. CC0 MakeHuman-derived contact, guard and scout visuals are integrated. Guard movement uses two baked stride morphs driven by actual horizontal speed, not a skeletal animation. Mixamo requires registration and was not used. |
| Materials | PH-01 through PH-03 and PH-05/06 above, CC0 | Shared wall, mud, cobble and overcast resources are now used in actual rendered town frames. |
| Audio and effects | [Kenney RPG Audio](https://kenney.nl/assets/rpg-audio), [Impact Sounds](https://kenney.nl/assets/impact-sounds) and [Interface Sounds](https://kenney.nl/assets/interface-sounds), all listed CC0 | Free leads for footsteps, hits and UI. Historical gunfire, alarm and ambience still need listening and rights review; gameplay may use distinct temporary cues first. |

No registration was needed for the acquired Poly Haven sample. The listed Kenney packs offer a free download route with an optional donation prompt. Sketchfab and Mixamo require free accounts for the cited workflows; neither has been accessed with an account or downloaded. No paid content was selected.

## Integration boundary

`reference/` contains research imagery, not cleared game art. It is Git-ignored and has a local `.gdignore` so Godot skips importing it. Asset selection must preserve the mission's routes, upstairs access, faction-neutral 1944 framing, and measured performance on the target Mac. Godot Metal screenshots establish current visible placement, but full-route art and frame-rate acceptance remain open.
