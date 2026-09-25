# Art Direction and Reference Research

Status: working design with a first environment-art production pass, updated 25 September 2026. The first cross-region reference search and downloads were completed on 24–25 September. The user subsequently removed seven images and selected **G01-07 through G01-12** as preferred core references. The user confirmed a fictional European town in 1944; exact region and month remain open, and factions are not locked. Reference downloads do not constitute game-asset reuse permission. The user explicitly rejected the raw box buildings and gun as the target experience and asked for a grounded real-world 3D shooter. Custom Blender modeling/adaptation is authorized when suitable free assets cannot make a coherent style.

## Confirmed Reference Preference

All six selected images are Hell Let Loose reference images in `reference/games/`:

| Image | Visible features | Proposed design use |
| --- | --- | --- |
| [G01-07](../reference/games/G01-07.jpg) | Trees, surviving houses, rubble, a burning vehicle wreck | A damaged public space with recognizable town structure |
| [G01-08](../reference/games/G01-08.jpg) | Exposed floors, broken walls, timber, neighboring surviving buildings | Locally severe damage and altered connections |
| [G01-09](../reference/games/G01-09.jpg) | Stone houses, shops, street furniture, sandbags and debris | Everyday town character under military occupation |
| [G01-10](../reference/games/G01-10.jpg) | Continuous stone facades, shutters, awnings, narrow street, puddles | Main architectural and street-detail vocabulary |
| [G01-11](../reference/games/G01-11.jpg) | Field emplacement, timber, vegetation and distant countryside | Military presence at the town edge |
| [G01-12](../reference/games/G01-12.jpg) | Small stone outbuilding, muddy track, fences and fields | A short transition between countryside and town |

The selection is confirmed; the interpretation below is a proposal, not blanket approval of every pictured object or mechanic.

Suggested direction: a compact stone-built European town near farmland, recently affected by fighting and still occupied. Surviving homes and shops coexist with collapsed buildings, temporary defenses, and wreckage. Cloudy daylight, intermittent sun, muddy surfaces, green vegetation and distant smoke establish atmosphere. Damage should be substantial in selected locations rather than uniform across the entire town. Tanks, artillery, and expansive countryside gameplay are not automatically added by selecting these images.

## Visual Principles

- The town should feel inhabited before it feels designed for combat: irregular streets, purposeful buildings, natural sightlines and occlusion.
- Damage has spatial causes; avoid conveniently symmetric rubble at every intersection.
- Historical evidence constrains appearance and place. Game and modeling examples inform readability, materials, light and production; they are not historical evidence.
- Do not copy another game's map or treat one photograph as a complete plan.
- Visible guard cones are an explicitly approved gameplay overlay. Grounded environment art does not imply removing this readability aid.

## Research Layers

| Layer | Material | Questions |
| --- | --- | --- |
| Geography and chronology | Period street plans, aerial photographs, military maps | How do roads, plots, squares and landmarks connect? Is the source before, during or after fighting? |
| Ground-level appearance | Dated/localized street photographs and footage | What are the openings, surfaces, signs, debris and surviving structures like? |
| Games and environment art | Gameplay, developer commentary, artist breakdowns | How are routes legible, assets reused and artificial arena patterns avoided? |
| Later technical validation | Official Blender/Godot references and measured samples | What imports and runs reliably on the target machine? |

## Existing Reference Collection

The user's request to research and download before choosing a setting superseded the earlier selection-first sequence.

- [Gallery](../reference/gallery.html): local images with categories and sources. Originally 40 images were downloaded; 33 remain after user curation.
- [Research synthesis](../reference/RESEARCH_SYNTHESIS.md): Normandy, Netherlands and Italy comparisons, official game maps and production methods.
- [Resource index](../reference/RESOURCE_INDEX.md): source, date, rights, access status and limitations. Some downloads were blocked by 403/429 responses or other access errors.
- Use the requested singular directory `reference/`.
- A complete, high-resolution, historically checked 1944 town plan has not been obtained. The collection is not yet a measured modeling base.

Production has now begun: two authored exterior house shells with stone/plaster PBR materials, pitched slate roofs, recessed closed openings and shutters passed Godot import/render review. Purpose-sized passage wings, shared cobble/mud surfaces, an overcast sky, contact-room details, selective roadside dressing and a neutral field-clothed scout have been integrated into representative playable-scene frames. These remain an architectural foundation, not acceptance of final realism: repetitive exteriors, limited damage/inhabited detail, static NPC presentation and full-route performance still need review. See [VISUAL_PRODUCTION.md](VISUAL_PRODUCTION.md) for exact frames and limits. The selected G01 images remain visual references, not game texture sources.

## Further Work

Archive links and item-level limitations are maintained in the [reference index](../reference/RESOURCE_INDEX.md), rather than duplicated here. Research should cover ordinary town structure as well as war damage. Exact region/month and historical framing remain user decisions; layout and asset dimensions belong to Astra's implementation review. The selected free materials and sample crate are recorded in [ASSET_PROVENANCE.md](ASSET_PROVENANCE.md).
