# Environment, Blender, and Godot Responsibilities

Status: future production proposal. MCP and asset import have not been validated here. The user has authorized production by the Astra-led team; asset research and production execution belong to Sol/high subagents. “Modules” means reusable objects or building pieces, not a mandatory grid-shaped town.

## Confirmed Asset-First Policy

Search online for suitable existing assets before proposing custom modeling. Cover the required asset categories: modular buildings and interiors, doors/windows, furniture, rubble, vegetation, weapons, characters/animations, materials, audio and effects. Evaluate a bounded shortlist per category; the goal is a usable, coherent set, not an exhaustive download of everything available.

Check source/license/attribution, visual consistency, historical fit, file formats, editable parts, interior access, collision, animation compatibility and measured Godot performance on the target Mac. Downloadable does not mean open-source or cleared for redistribution. Record provenance and modifications. Use free assets only: no purchases, paid subscriptions or paid acquisition routes. Notify the user when a suitable free resource requires registration, and coordinate that step before account creation.

Use Godot to assemble the town and implement routes, interactions, lighting, guards and mission logic. Use Blender only when a selected asset needs conversion, repair, optimization or a small adaptation that cannot reasonably be handled in the import/scene workflow. Propose from-scratch modeling only for a required gap with no suitable existing asset or acceptable substitute, explaining the gap and expected cost first. Do not spend subagent work on custom models by default.

Reference images remain research material, not cleared game assets. The upstairs contact residence specifically needs usable access, stairs and an interior; an attractive exterior-only model is insufficient.

## Proposed Later Workflow

1. Derive an asset requirements list from the confirmed game design and reference selection.
2. Search and compare compatible asset packs; record licenses, costs and functional gaps before bulk acquisition.
3. Develop the layout and playable Godot blockout, testing travel time, route choices and post-handoff changes before final art. Reference evidence and gameplay adaptation remain distinguishable.
4. Import a small representative asset set and validate scale, materials, collision, animation and performance. Select routine asset details within the authorized scope; return major visual choices to the user; reject paid options.
5. Assemble selected assets in Godot. Adapt only the necessary gaps; preserve playable connections and avoid forcing the town into a repetitive grid.
6. Walk the complete mission, including reinforced extraction, and verify navigation, readability and performance before expanding the library.

Blender and MCP are optional tools, not required pipeline stages. A connected tool or downloaded model is not proof of a usable game asset. Existing technical leads: [Godot 3D import](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html) and [scene instancing](https://docs.godotengine.org/en/stable/getting_started/step_by_step/instancing.html); verify version-specific behavior during production.

## Proposed Asset Handoff Record

Include `asset_id`, reference IDs, intended placement, dimensions/units, variants, origin/orientation, material slots, collision approach, LOD or performance budget, original downloaded source files, modified sources if applicable, Godot-ready export, and import results. Astra reviews the record before a level agent uses the asset.

## Proposed Small Validation Experiment

Use one irregular street corner: two different facades, a traversable alley, one damaged feature, and a reusable prop. Use downloaded assets first. Compare blockout routes against routes after model replacement; measure scale, collision, and frame rate in Godot. Identify specific adaptation needs before considering Blender work. Schedule this experiment within the authorized production plan when its dependencies are ready.

## Choices Not Yet Fixed

- GridMap, manually placed scene instances, procedural generation, or a mixture: choose based on actual street geometry and reuse.
- Full interiors: initially model only spaces needed for the mission and routes.
- Asset detail, texture resolution, and lighting: derive budgets from target-machine measurements.

## Existing Weapon Asset Proposals

The user selected a submachine gun and suggested downloadable assets. No asset has been selected or imported. Evaluate clearly licensed existing models before deciding what needs custom work.

Check models/textures, independently movable parts such as magazines, first-person arms and animations, audio, and gameplay code separately. A model listing does not establish a complete weapon system. First inspect close-up quality, scale/orientation, materials, animation compatibility, editable parts, and runtime cost; validate one weapon's import, shooting, and reload before expanding the library.

Retain creator, source URL, license, attribution requirements, original package, and modification history. Third-party assets need not include a native `.blend`; retain their actual source formats and project conversions.

Existing discovery leads, not selections: a [Sketchfab Thompson](https://sketchfab.com/3d-models/thompson-submachine-gun-e118cf3b76b5425997132c3b97703c73) search result indicated download availability and CC Attribution, but the detail page returned 403, so files, licensing details, and animation were not verified. [Kenney Blaster Kit](https://kenney.nl/assets/blaster-kit) was listed as CC0 and may serve as a prototype placeholder, not final WWII realistic art. Recheck these records before acquisition.

## User-Supplied Poly Haven References

Pages checked 25 September 2026. All three list free models, CC0 licensing and glTF downloads. Files have not been downloaded or tested in Godot. Historical suitability and animation readiness are not established by the listings.

| Reference | Assessment |
| --- | --- |
| [Bolt Action Rifle 7.62](https://polyhaven.com/a/bolt_action_rifle_7_62) | Mateusz Sadek; reference candidate, not a submachine gun or an approved replacement for the player's weapon |
| [Service Pistol](https://polyhaven.com/a/service_pistol) | Mateusz Sadek; page includes a Cold War tag, so 1944 suitability needs verification; no sidearm mechanic is approved |
| [Stick Grenade](https://polyhaven.com/a/stick_grenade) | singaii; page tags include WWII/German, but exact historical fit still needs review; no grenade mechanic is approved |

Retain these as visual/asset leads. Adding a weapon system requires a separate scope decision. See [Poly Haven's asset license](https://polyhaven.com/license).
