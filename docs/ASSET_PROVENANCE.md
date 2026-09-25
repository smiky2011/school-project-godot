# Asset Provenance and Screening

Status: small production sample, checked 25 September 2026. The mission takes place in a fictional European town in 1944. Its factions and exact architectural region remain open. These files are usable candidates, not approval of final art or evidence of a completed level.

## Acquired sample

All four items below came from [Poly Haven](https://polyhaven.com/license), whose official asset license states CC0, redistribution allowed, and attribution optional. The individual pages list the same license. Downloads were anonymous and free. Original ZIP packages are retained under `assets/vendor/polyhaven/source/`; the three extracted diffuse JPGs and the model files keep their upstream filenames. No asset was modified beyond extracting files from the packages. An offline license record is at `assets/vendor/polyhaven/LICENSE.txt`.

| ID | Author and source | Imported candidate | Original package SHA-256 | Use and limit |
| --- | --- | --- | --- | --- |
| PH-01 | Rob Tuytel, [Plastered Stone Wall](https://polyhaven.com/a/plastered_stone_wall) | `assets/vendor/polyhaven/materials/plastered_stone_wall_diff_1k.jpg` | `c95acdcd30000f240b3fd80b026bf5d52089059db483934c40fc74049653a49e` | Weathered façade sample; one 1024² diffuse texture, not a complete façade or material setup. |
| PH-02 | Charlotte Baglioni (photography), Dario Barresi (processing), [Stone Wall](https://polyhaven.com/a/stone_wall) | `assets/vendor/polyhaven/materials/stone_wall_diff_1k.jpg` | `f2a78be356d8084d185f0c5cab3f794ce1ae7ad4288d0784fcb1aba5b78198a4` | Stone wall sample; geographic fit remains unconfirmed. |
| PH-03 | Amal Kumar, [Muddy Tracks](https://polyhaven.com/a/muddy_tracks) | `assets/vendor/polyhaven/materials/muddy_tracks_diff_1k.jpg` | `d43352dc4de21b80d1eab25c0fe846192b4d68f7bc874635f17e1b4bc41ecbff` | Track/soil sample for the town edge; vehicle-track pattern should be placed selectively. |
| PH-04 | James Ray Cock (modeling), Jurita Burger (graphic design), [Wooden Crate 02](https://polyhaven.com/a/wooden_crate_02) | `assets/vendor/polyhaven/wooden_crate_02/wooden_crate_02_1k.gltf` and its `.bin` and 1K JPG textures | `a30e6796d01cf907f698074ad176e9ebfbc486b34dc16d1203edf03b93de070a` | Optional street/interior prop, roughly 1.2 m wide and 5K triangles per source page. Printed letters and visual style need review before repeated placement. No collision shape or animation is supplied. |

The three material packages are 1K Blender ZIP downloads. Their source archives contain `.blend` and texture maps; only diffuse JPGs were extracted into importable paths. Full roughness/normal maps remain in the originals for later PBR work if needed. The model package is the 1K glTF ZIP. In an isolated Godot 4.7.2 project, the crate's `.gltf`, `.bin`, and three textures imported successfully and produced a cached scene. This verifies file compatibility only; scale, rendered look, collisions and target-Mac frame rate await an in-game test. Keep `source/*.zip` in the repository for provenance but exclude it from the final game export.

## Bounded shortlist for remaining categories

| Need | Free lead | Current decision |
| --- | --- | --- |
| Building shells, doors, windows and the usable upstairs interior | [Kenney Building Kit](https://kenney.nl/assets/building-kit) and [Modular Buildings](https://kenney.nl/assets/modular-buildings), both CC0 | Suitable for route and door prototypes, visibly stylized. Build only the required contact interior in the first loop; screen realistic replacements after routes work. |
| Furniture | [Poly Haven Painted Wooden Cabinet](https://polyhaven.com/a/painted_wooden_cabinet), CC0, glTF, about 2K triangles | Candidate for the residence after interior dimensions are stable. |
| Rubble | [Poly Haven Rubble](https://polyhaven.com/a/rubble) and [Broken Wall](https://polyhaven.com/a/broken_wall), CC0 textures | Surface samples, not navigable debris meshes; use collision-aware blockout pieces first. |
| Vegetation | [Poly Haven Shrub 03](https://polyhaven.com/a/shrub_03), CC0, source page lists LODs and 17K triangles | Screen size/performance before placement. Tree candidates found were much heavier; use sparse low-detail blockout vegetation until measured. |
| Submachine gun | [Sketchfab Thompson M1928](https://sketchfab.com/3d-models/thompson-m1928-low-poly-52e1701ca8ef48438948d3eb2de42302) and [MP 40](https://sketchfab.com/3d-models/mp-40-7f699510d9a44f96820aa4988a04da50), both listed CC BY by their creators | **Unselected.** Either implies a faction/context choice; parts, first-person suitability and import are unverified. [Sketchfab's download API documentation](https://sketchfab.com/developers/download-api/downloading-models) says account authentication is required. Tell the user before relying on this free registration route. A primitive weapon placeholder is appropriate for the playable loop. |
| Guard/contact/scout characters and animation | [Kenney Animated Characters Survivors](https://kenney.nl/assets/animated-characters-survivors), CC0; [Adobe Mixamo](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html), free for games with an Adobe ID | Kenney is useful for animation/prototype but visually stylized. Mixamo requires registration and character/rig compatibility checks; no account was created. Use simple temporary figures for the loop. |
| Materials | PH-01 through PH-03 above, CC0 | Three small samples acquired. Prefer reuse before expanding the material library. |
| Audio and effects | [Kenney RPG Audio](https://kenney.nl/assets/rpg-audio), [Impact Sounds](https://kenney.nl/assets/impact-sounds) and [Interface Sounds](https://kenney.nl/assets/interface-sounds), all listed CC0 | Free leads for footsteps, hits and UI. Historical gunfire, alarm and ambience still need listening and rights review; gameplay may use distinct temporary cues first. |

No registration was needed for the acquired Poly Haven sample. The listed Kenney packs offer a free download route with an optional donation prompt. Sketchfab and Mixamo require free accounts for the cited workflows; neither has been accessed with an account or downloaded. No paid content was selected.

## Integration boundary

`reference/` contains research imagery, not cleared game art. It is Git-ignored and has a local `.gdignore` so Godot skips importing it. Asset selection must preserve the mission's routes, upstairs access, faction-neutral 1944 framing, and measured performance on the target Mac. Add placement, material configuration, collision and import observations when a sample is actually used in a scene.
