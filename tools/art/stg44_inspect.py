"""Inspect the downloaded StG 44 source in an isolated Blender process."""

from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parents[2]
FBX = ROOT / "assets/vendor/weapon_visual/stg44/source/original/source/STG44_Full.fbx"
assert bpy.app.background
bpy.ops.import_scene.fbx(filepath=str(FBX), use_image_search=False)
for obj in bpy.data.objects:
    if obj.type != "MESH":
        print("OBJECT", obj.name, obj.type, "parent", obj.parent.name if obj.parent else None)
        continue
    print("MESH", obj.name, "parent", obj.parent.name if obj.parent else None,
          "verts", len(obj.data.vertices), "faces", len(obj.data.polygons),
          "dim", tuple(round(v, 4) for v in obj.dimensions),
          "world loc", tuple(round(v, 4) for v in obj.matrix_world.translation),
          "mats", [m.name if m else None for m in obj.data.materials])
    for mat in obj.data.materials:
        if mat and mat.use_nodes:
            print("MATERIAL", mat.name, [(n.name, n.type, getattr(n.image, 'filepath', '') if n.type == 'TEX_IMAGE' else '') for n in mat.node_tree.nodes])
