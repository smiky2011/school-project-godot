"""Build the masked, rigged guard and an in-place patrol walk from CC0 source.

Run with Blender 5.2.2 in background mode and ``--python``. The original
guard_field_grip.blend and the earlier morph GLB remain untouched.
"""

from math import radians
from pathlib import Path

import bpy
from mathutils import Quaternion, Vector


PROJECT = Path(__file__).resolve().parents[2]
ROOT = PROJECT / "assets/vendor/character_visual/makehuman"
SOURCE = ROOT / "source/guard_field_grip.blend"
WORKING = ROOT / "source/guard_field_locomotion.blend"
RUNTIME = ROOT / "runtime/guard_field_animated.glb"

bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
scene = bpy.context.scene
rig = bpy.data.objects["ContactRig"]
meshes = [obj for obj in scene.objects if obj.type == "MESH"]
assert len(meshes) == 8, "Unexpected source mesh count"

# MakeHuman's body contains concealed helper and under-clothing faces. Apply
# only its MASK modifiers in rest space; leave vertex groups and the armature
# deform modifier in the editable file and in the glTF skin.
for obj in meshes:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    if obj.data.shape_keys is not None:
        # Freeze the selected MakeHuman body proportions before applying masks.
        # The source file still retains the original editable proportions.
        bpy.ops.object.shape_key_remove(all=True, apply_mix=True)
    deform = next((mod for mod in obj.modifiers if mod.type == "ARMATURE"), None)
    if deform is None:
        raise RuntimeError("Missing armature modifier on " + obj.name)
    bpy.ops.object.modifier_move_to_index(modifier=deform.name, index=len(obj.modifiers) - 1)
    for mod in tuple(obj.modifiers):
        if mod.type == "MASK":
            bpy.ops.object.modifier_apply(modifier=mod.name)
    if not obj.vertex_groups:
        raise RuntimeError("Lost skin weights on " + obj.name)
    print("GUARD_SKIN", obj.name, len(obj.data.vertices), len(obj.vertex_groups), flush=True)

baseline_rotations = {}
baseline_locations = {}
for bone in rig.pose.bones:
    # Keep the posed low-ready grip from the source as the animation's base.
    rotation = bone.matrix_basis.to_quaternion()
    location = bone.location.copy()
    bone.rotation_mode = "QUATERNION"
    bone.rotation_quaternion = rotation
    baseline_rotations[bone.name] = rotation.copy()
    baseline_locations[bone.name] = location


def local_x_delta(name: str, degrees: float) -> Quaternion:
    rest = rig.pose.bones[name].bone.matrix_local.to_quaternion()
    return rest.inverted() @ Quaternion(Vector((1, 0, 0)), radians(degrees)) @ rest


# Contact, passing, opposite contact, passing, then the identical first pose.
# The cycle stays in place: the Guard CharacterBody3D remains the sole owner of
# pathfinding, displacement, hit boxes, and death state.
poses = (
    (1, -24, 24, 8, 25, -7, 10, -0.010),
    (7, 0, 0, 5, 17, 0, 5, 0.013),
    (13, 24, -24, 25, 8, 10, -7, -0.010),
    (19, 0, 0, 17, 5, 5, 0, 0.013),
    (25, -24, 24, 8, 25, -7, 10, -0.010),
)
scene.render.fps = 24
scene.frame_start = 1
scene.frame_end = 25
rig.animation_data_clear()
for frame, thigh_l, thigh_r, calf_l, calf_r, foot_l, foot_r, rise in poses:
    scene.frame_set(frame)
    angles = {
        "thigh_l": thigh_l,
        "thigh_r": thigh_r,
        "calf_l": calf_l,
        "calf_r": calf_r,
        "foot_l": foot_l,
        "foot_r": foot_r,
    }
    for bone in rig.pose.bones:
        bone.rotation_quaternion = baseline_rotations[bone.name].copy()
        bone.location = baseline_locations[bone.name].copy()
        if bone.name in angles:
            bone.rotation_quaternion = bone.rotation_quaternion @ local_x_delta(bone.name, angles[bone.name])
        if bone.name == "pelvis":
            bone.location.z += rise
        bone.keyframe_insert(data_path="rotation_quaternion", frame=frame, group=bone.name)
        if bone.name == "pelvis":
            bone.keyframe_insert(data_path="location", frame=frame, group=bone.name)

action = rig.animation_data.action
if action is None:
    raise RuntimeError("No guard walk action was authored")
action.name = "GuardWalk"
action.use_fake_user = True

# A keyed neutral grip gives Godot a real target to blend toward when the
# guard stops. Otherwise stopping mid-cycle leaves one leg raised.
rig.animation_data.action = None
for frame in (1, 25):
    scene.frame_set(frame)
    for bone in rig.pose.bones:
        bone.rotation_quaternion = baseline_rotations[bone.name].copy()
        bone.location = baseline_locations[bone.name].copy()
        bone.keyframe_insert(data_path="rotation_quaternion", frame=frame, group=bone.name)
        if bone.name == "pelvis":
            bone.keyframe_insert(data_path="location", frame=frame, group=bone.name)
idle = rig.animation_data.action
if idle is None or idle == action:
    raise RuntimeError("No separate guard idle action was authored")
idle.name = "GuardIdle"
idle.use_fake_user = True

scene.frame_set(1)
bpy.context.view_layer.update()
bpy.ops.object.select_all(action="DESELECT")
rig.select_set(True)
for obj in meshes:
    obj.select_set(True)
bpy.context.view_layer.objects.active = rig

bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(WORKING), compress=True)
bpy.ops.export_scene.gltf(
    filepath=str(RUNTIME),
    export_format="GLB",
    use_selection=True,
    export_skins=True,
    export_animations=True,
    export_animation_mode="ACTIONS",
    export_force_sampling=True,
)
print("GUARD_WALK_SOURCE", WORKING, flush=True)
print("GUARD_WALK_RUNTIME", RUNTIME, flush=True)
