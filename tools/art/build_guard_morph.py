"""Bake the visible, masked fieldwear into stable idle and two stride morphs."""

from math import radians
import os
from pathlib import Path

import bpy
from mathutils import Quaternion, Vector


PROJECT = Path(__file__).resolve().parents[2]
ROOT = PROJECT / "assets/vendor/character_visual/makehuman"
rig = bpy.data.objects["ContactRig"]
originals = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
bpy.context.view_layer.update()
depsgraph = bpy.context.evaluated_depsgraph_get()

baked = []
for original in originals:
    mesh = bpy.data.meshes.new_from_object(original.evaluated_get(depsgraph), preserve_all_data_layers=True, depsgraph=depsgraph)
    visual = bpy.data.objects.new("Field_" + original.name, mesh)
    bpy.context.scene.collection.objects.link(visual)
    visual.matrix_world = original.matrix_world.copy()
    visual.shape_key_add(name="Basis")
    baked.append((original, visual))


def axis_delta(name, angle):
    rest = rig.pose.bones[name].bone.matrix_local.to_quaternion()
    return rest.inverted() @ Quaternion(Vector((1, 0, 0)), radians(angle)) @ rest


baseline = {name: bone.rotation_quaternion.copy() for name, bone in rig.pose.bones.items()}
for target_name, sign in (("StepLeft", 1.0), ("StepRight", -1.0)):
    for name, rotation in baseline.items():
        rig.pose.bones[name].rotation_quaternion = rotation.copy()
    for name, angle in {"thigh_l": -19.0 * sign, "thigh_r": 19.0 * sign,
                        "calf_l": 9.0 if sign > 0 else 2.0,
                        "calf_r": 2.0 if sign > 0 else 9.0}.items():
        bone = rig.pose.bones[name]
        bone.rotation_mode = "QUATERNION"
        bone.rotation_quaternion = bone.rotation_quaternion @ axis_delta(name, angle)
    bpy.context.view_layer.update()
    depsgraph = bpy.context.evaluated_depsgraph_get()
    for original, visual in baked:
        evaluation = original.evaluated_get(depsgraph)
        deformed = evaluation.to_mesh()
        if len(deformed.vertices) != len(visual.data.vertices):
            raise RuntimeError("Morph topology changed: " + original.name)
        target = visual.shape_key_add(name=target_name)
        greatest = 0.0
        for index, vertex in enumerate(deformed.vertices):
            target.data[index].co = vertex.co
            greatest = max(greatest, (vertex.co - visual.data.vertices[index].co).length)
        evaluation.to_mesh_clear()
        print("GUARD_MORPH_MESH", target_name, original.name, len(visual.data.vertices), round(greatest, 4), flush=True)

bpy.ops.object.select_all(action="DESELECT")
for _, visual in baked:
    visual.select_set(True)
bpy.context.view_layer.objects.active = baked[0][1]
output = Path(os.environ.get("GUARD_OUTPUT", str(ROOT / "runtime/guard_field_morph.glb")))
bpy.ops.export_scene.gltf(filepath=str(output), export_format="GLB", use_selection=True,
                          use_active_scene=True,
                          export_animations=False, export_morph=True)
print("GUARD_MORPH_RUNTIME", output, flush=True)
