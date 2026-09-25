# Town architecture asset screening and handoff

Status: two reusable exterior shells produced and independently imported in Godot 4.7.2 on 25 September 2026. This is an asset-library checkpoint, not acceptance of the finished town or of a playable interior. The fictional European 1944 setting and selected G01-07 through G01-12 images guide scale and composition; the game screenshots are references, not reused textures or geometry.

## Selection

The [Kenney Modular Buildings](https://kenney.nl/assets/modular-buildings) and [Building Kit](https://kenney.nl/assets/building-kit) are CC0 and modular, but their deliberately simplified shapes would continue the placeholder visual language at player distance. Poly Haven's [Modular Fort 01](https://polyhaven.com/a/modular_fort_01) is CC0 and detailed but is a fortification, 71.4 m wide, rather than a domestic 9–10 m plot. These are useful resource leads, not selected house assets. Two custom Blender exteriors fill the domestic façade/roof gap while using the already selected CC0 Poly Haven wall materials. This adaptation is within the user's authorization for coherent, grounded environment art when suitable free assets are unavailable.

| Asset | Dimensions and purpose | Geometry and materials | Import evidence |
| --- | --- | --- | --- |
| `townhouse_stone_gable_9x16.glb` | 9 × 16 m footprint; 5.85 m eaves, 8 m ridge; stone-fronted surviving house | One mesh, 3,554 source polygons, six material surfaces. Recessed door and windows, side frontage, louvered shutters, stone trim, slate gable, gutter, chimney | Godot 4.7.2 import succeeded; rendered 1280 × 800 model preview in `docs/media/preview_townhouses.png`; GLB JSON has only `TownhouseStoneGable` node. |
| `townhouse_plaster_hip_9x16.glb` | 9 × 16 m footprint; 5.55 m eaves, 7.45 m ridge; plaster/stone hip-roof variant | One mesh, 4,348 source polygons, seven material surfaces. Different door placement and roof silhouette, side frontage, dormer, trim, chimney | Same Godot import/preview; GLB JSON has only `TownhousePlasterHip` node. |

Origin is ground center; local +Z is the primary street-facing end in Godot. One unit equals one metre. These are closed **exterior** shells. The doors are visibly shut; they do not claim walk-through access or interiors. Collision and guard navigation remain the responsibility of the level script, and the upstairs contact residence requires a separate interior treatment. The 2.5–3.6 m passage bays must have purpose-built modules; stretching the 9 m façade to that width would destroy door/window scale. Repetition, environmental damage, optimization, and first-person art quality still need review in the full town.

## Source, license, and editable files

- Wall maps derive from the original [Poly Haven Stone Wall](https://polyhaven.com/a/stone_wall) by Charlotte Baglioni and Dario Barresi and [Plastered Stone Wall](https://polyhaven.com/a/plastered_stone_wall) by Rob Tuytel. Both are [CC0](https://polyhaven.com/license). Existing upstream ZIPs, archive hashes, and details are in `assets/vendor/polyhaven/source/` and [ASSET_PROVENANCE.md](ASSET_PROVENANCE.md). The source EXR roughness and normal maps were converted to 8-bit PNG for portable glTF/Godot use; diffuse JPGs were extracted without retouching.
- Slate, painted shutter, and oak maps are project-authored procedural textures from `tools/art/generate_environment_textures.py`; no external image was copied for them.
- `tools/art/build_townhouses_blender.py` builds both objects in the dedicated `TownArchitectureProduction` scene and exports only that active scene/selected object. The editable native source is `assets/environment/source/townhouses_9x16.blend` with `//../textures/` relative image paths. The source directory has `.gdignore` so Godot does not scan `.blend`. Runtime GLBs embed their material images.
- Godot generates per-GLB extracted texture sidecars and `.import` files during import. They are generated results, not original source. A fresh editor import must regenerate them from the GLBs; do not remove any sidecar from a populated checkout while an imported scene still references it.

The two GLBs have 6/7 material surfaces respectively and include embedded copies of some shared texture data. A measured full-town frame-rate test and material-sharing optimization are pending; the asset preview proves import and visible scale, not acceptable frame rate at 80 instances. The native `.blend` contains only the authored production scene, not the user's default Blender scene or the separate weapon scene.
