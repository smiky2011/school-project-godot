"""Pose and extract CC0 MakeHuman hands for the Sten first-person trial.

Run only as Blender --background --factory-startup with the reviewed MakeHuman
source .blend as input. It changes evaluated rig pose in memory, never saves
that upstream character project, and writes hand-only GLB trial files.
"""

import json
import math
from pathlib import Path

import bpy


if not bpy.app.background:
    raise RuntimeError("Use an isolated Blender background process")
root = Path(__file__).resolve().parents[2]
source = root / "assets/vendor/character_visual/makehuman/source/contact_candidate.blend"
if Path(bpy.data.filepath).resolve() != source.resolve():
    raise RuntimeError("Open the reviewed MakeHuman character source")
output_dir = root / "reference/authoring/makehuman"
body = bpy.data.objects["ContactBody"]
rig = bpy.data.objects["ContactRig"]

# Local X is the flexion axis in this rig. Three joints produce rounded
# knuckles and a closed grip without deleting or repainting the human mesh.
flexion = {
    "index": (28, 36, 22),
    "middle": (35, 42, 25),
    "ring": (42, 48, 27),
    "pinky": (46, 50, 28),
    "thumb": (12, 27, 17),
}
for side in ("l", "r"):
    for digit, angles in flexion.items():
        for segment, angle in zip(("01", "02", "03"), angles):
            bone = rig.pose.bones[f"{digit}_{segment}_{side}"]
            bone.rotation_mode = "XYZ"
            bone.rotation_euler.x = math.radians(angle)
bpy.context.view_layer.update()

degraph = bpy.context.evaluated_depsgraph_get()
evaluated = body.evaluated_get(degraph)
mesh = evaluated.to_mesh(preserve_all_data_layers=True, depsgraph=degraph)
uv_layer = mesh.uv_layers.active
if uv_layer is None:
    raise RuntimeError("MakeHuman source UV map missing")

for side, sign, suffix in (("left", 1, "l"), ("right", -1, "r")):
    wrist = rig.data.bones[f"hand_{suffix}"].head_local.copy()
    selected = {}
    faces = []
    face_uvs = []
    material_indices = []
    for polygon in mesh.polygons:
        original_indices = list(polygon.vertices)
        points = [body.matrix_world @ mesh.vertices[index].co for index in original_indices]
        if not all(sign * p.x >= 0.355 and 0.90 <= p.z <= 1.17 for p in points):
            continue
        new_indices = []
        for index in original_indices:
            if index not in selected:
                selected[index] = len(selected)
            new_indices.append(selected[index])
        faces.append(new_indices)
        face_uvs.append([tuple(uv_layer.data[index].uv) for index in polygon.loop_indices])
        material_indices.append(polygon.material_index)
    if len(faces) < 100:
        raise RuntimeError(f"Hand {side} has too few faces: {len(faces)}")
    vertices = [None] * len(selected)
    for source_index, output_index in selected.items():
        point = body.matrix_world @ mesh.vertices[source_index].co
        vertices[output_index] = tuple(point - wrist)
    hand_mesh = bpy.data.meshes.new("MakeHumanGrip" + side.title())
    hand_mesh.from_pydata(vertices, [], faces)
    hand_mesh.update()
    for material in mesh.materials:
        hand_mesh.materials.append(material)
    output_uv = hand_mesh.uv_layers.new(name="UVMap")
    for polygon, uvs, material_index in zip(hand_mesh.polygons, face_uvs, material_indices):
        polygon.material_index = material_index
        polygon.use_smooth = True
        for index, uv in zip(polygon.loop_indices, uvs):
            output_uv.data[index].uv = uv
    obj = bpy.data.objects.new("MakeHumanGrip" + side.title(), hand_mesh)
    bpy.context.collection.objects.link(obj)
    for other in bpy.context.scene.objects:
        other.select_set(other == obj)
    bpy.context.view_layer.objects.active = obj
    path = output_dir / f"hand_{side}_grip.glb"
    bpy.ops.export_scene.gltf(
        filepath=str(path), export_format="GLB", use_selection=True,
        use_active_scene=True, export_animations=False,
    )
    print("GRIP_HAND " + json.dumps({
        "side": side, "vertices": len(vertices), "faces": len(faces),
        "wrist_world": list(wrist), "glb": str(path),
    }), flush=True)
    bpy.data.objects.remove(obj, do_unlink=True)

evaluated.to_mesh_clear()
