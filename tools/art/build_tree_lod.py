"""Reduce Poly Haven's CC0 jacaranda_tree to a game-weight town tree.

Run from the repository root (Blender 5.2):
    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup \
        --python tools/art/build_tree_lod.py

Input : assets/vendor/polyhaven_cc0/model/jacaranda_tree/jacaranda_tree_1k.gltf
        (about 3.9 M triangles; kept only as an ignored-by-Godot source)
Output: assets/environment/trees/town_tree.glb      (game mesh)
        assets/environment/trees/town_tree_card.png (transparent side view
        used for distant treeline billboards)

Leaf cards are thinned by deleting whole leaf islands at random and scaling
the survivors up about their own centers, the usual foliage LOD trick; the
branch and trunk meshes use collapse decimation.
"""

import random
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "assets/vendor/polyhaven_cc0/model/jacaranda_tree/jacaranda_tree_1k.gltf"
OUT_DIR = ROOT / "assets/environment/trees"
OUT_DIR.mkdir(parents=True, exist_ok=True)
KEEP_LEAVES = 0.032
LEAF_SCALE = 3.1
BRANCH_RATIO = 0.035
TRUNK_RATIO = 0.1
random.seed(1944)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(SRC))
mesh_objects = [o for o in bpy.context.scene.objects if o.type == "MESH"]
print("IMPORTED", [(o.name, len(o.data.polygons)) for o in mesh_objects])

# The import is one mesh with three material slots; split it by material.
for obj in mesh_objects:
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.separate(type="MATERIAL")
    bpy.ops.object.mode_set(mode="OBJECT")
parts = [o for o in bpy.context.scene.objects if o.type == "MESH"]


def material_name(obj):
    return obj.material_slots[0].material.name.lower() if obj.material_slots and obj.material_slots[0].material else ""


for obj in parts:
    name = material_name(obj)
    if "lea" in name:
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        bm.faces.ensure_lookup_table()
        seen = set()
        doomed = []
        for face in bm.faces:
            if face.index in seen:
                continue
            island = []
            stack = [face]
            seen.add(face.index)
            while stack:
                f = stack.pop()
                island.append(f)
                for edge in f.edges:
                    for other in edge.link_faces:
                        if other.index not in seen:
                            seen.add(other.index)
                            stack.append(other)
            if random.random() > KEEP_LEAVES:
                doomed.extend(island)
            else:
                verts = {v for f in island for v in f.verts}
                center = sum((v.co for v in verts), Vector()) / len(verts)
                for v in verts:
                    v.co = center + (v.co - center) * LEAF_SCALE
        bmesh.ops.delete(bm, geom=doomed, context="FACES")
        bm.to_mesh(obj.data)
        bm.free()
    else:
        ratio = TRUNK_RATIO if "trunk" in name else BRANCH_RATIO
        mod = obj.modifiers.new("Decimate", "DECIMATE")
        mod.ratio = ratio
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    print("PART", obj.name, name, len(obj.data.polygons))

bpy.ops.object.select_all(action="SELECT")
bpy.context.view_layer.objects.active = parts[0]
bpy.ops.object.join()
tree = bpy.context.view_layer.objects.active
tree.name = "TownTree"
print("FINAL_TRIS", sum(len(p.vertices) - 2 for p in tree.data.polygons))
bpy.ops.export_scene.gltf(filepath=str(OUT_DIR / "town_tree.glb"), export_format="GLB",
                          use_selection=True, export_apply=True, export_image_format="JPEG")

# Transparent side-view card for distant treelines.
scene = bpy.context.scene
bounds = [tree.matrix_world @ Vector(c) for c in tree.bound_box]
low = Vector((min(b.x for b in bounds), min(b.y for b in bounds), min(b.z for b in bounds)))
high = Vector((max(b.x for b in bounds), max(b.y for b in bounds), max(b.z for b in bounds)))
size = high - low
cam_data = bpy.data.cameras.new("CardCam")
cam_data.type = "ORTHO"
cam_data.ortho_scale = max(size.x, size.z) * 1.04
cam = bpy.data.objects.new("CardCam", cam_data)
scene.collection.objects.link(cam)
center = (low + high) / 2
cam.location = (center.x, low.y - 30.0, center.z)
cam.rotation_euler = (1.5708, 0.0, 0.0)
scene.camera = cam
sun_data = bpy.data.lights.new("CardSun", "SUN")
sun_data.energy = 3.5
sun = bpy.data.objects.new("CardSun", sun_data)
sun.rotation_euler = (0.9, 0.2, -0.6)
scene.collection.objects.link(sun)
world = bpy.data.worlds.new("CardWorld")
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.55, 0.6, 0.66, 1.0)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.9
scene.world = world
scene.render.engine = "BLENDER_EEVEE"
scene.render.film_transparent = True
scene.render.resolution_x = 512
scene.render.resolution_y = int(512 * size.z / max(size.x, size.z))
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.render.filepath = str(OUT_DIR / "town_tree_card.png")
bpy.ops.render.render(write_still=True)
print("CARD", scene.render.resolution_x, scene.render.resolution_y, "SIZE", tuple(round(v, 2) for v in size))
