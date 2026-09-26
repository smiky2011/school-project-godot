"""Add grounded crouch clips to the existing CC0 skinned field body.

Run with Blender 5.2.2 in background mode. The guard source is never modified;
the player-specific editable .blend and runtime .glb stay together in the
MakeHuman asset directory.
"""

from math import radians
from pathlib import Path

import bpy
from mathutils import Quaternion, Vector


ROOT = Path(__file__).resolve().parents[2] / "assets/vendor/character_visual/makehuman"
SOURCE = ROOT / "source/guard_field_locomotion.blend"
WORKING = ROOT / "source/player_shadow_locomotion.blend"
RUNTIME = ROOT / "runtime/player_shadow_animated.glb"

bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
scene = bpy.context.scene
rig = bpy.data.objects["ContactRig"]
idle = bpy.data.actions["GuardIdle"]
walk = bpy.data.actions["GuardWalk"]
rig.animation_data.action = idle
scene.frame_set(1)


def sample(action, frame):
    rig.animation_data.action = action
    scene.frame_set(frame)
    return {
        bone.name: (bone.rotation_quaternion.copy(), bone.location.copy())
        for bone in rig.pose.bones
    }


base = sample(idle, 1)
walk_samples = {frame: sample(walk, frame) for frame in (1, 7, 13, 19, 25)}


def local_axis_delta(name, axis, degrees):
    rest = rig.pose.bones[name].bone.matrix_local.to_quaternion()
    return rest.inverted() @ Quaternion(axis, radians(degrees)) @ rest


def key_pose(frame, *, crouched=False, walk_frame=None, strafe=0):
    # The measured idle pose puts the pelvis at 0.93 m and each ankle at
    # 0.07 m. The bent pose lowers the pelvis 0.64 m; a +50/-80 degree
    # thigh/knee fold brings the ankle back to 0.015 m above the ground.
    sample_pose = walk_samples[walk_frame] if walk_frame is not None else base
    leg_blend = 0.35 if crouched and walk_frame is not None else (1.0 if walk_frame is not None else 0.0)
    strafe_angles = {1: (-22, 8), 7: (-8, -8), 13: (8, -22), 19: (-8, -8), 25: (-22, 8)}
    for bone in rig.pose.bones:
        base_rotation, base_location = base[bone.name]
        walk_rotation, walk_location = sample_pose[bone.name]
        bone.rotation_quaternion = base_rotation.slerp(walk_rotation, leg_blend)
        bone.location = base_location.lerp(walk_location, leg_blend)
        if crouched and bone.name == "pelvis":
            bone.location.z -= 0.64
        crouch_angles = {
            "spine_01": 22, "spine_02": 15,
            "thigh_l": 50, "thigh_r": 50,
            "calf_l": -80, "calf_r": -80,
            "foot_l": 30, "foot_r": 30,
        }
        if crouched and bone.name in crouch_angles:
            bone.rotation_quaternion = bone.rotation_quaternion @ local_axis_delta(
                bone.name, Vector((1, 0, 0)), crouch_angles[bone.name]
            )
        if strafe:
            left, right = strafe_angles[frame]
            side_angles = {
                "thigh_l": left * strafe,
                "thigh_r": right * strafe,
                "foot_l": -left * strafe,
                "foot_r": -right * strafe,
            }
            if bone.name in side_angles:
                bone.rotation_quaternion = bone.rotation_quaternion @ local_axis_delta(
                    bone.name, Vector((0, 1, 0)), side_angles[bone.name]
                )
        bone.keyframe_insert(data_path="rotation_quaternion", frame=frame, group=bone.name)
        if bone.name == "pelvis":
            bone.keyframe_insert(data_path="location", frame=frame, group=bone.name)


for clip_name, crouched, frames, walk_frames, strafe in (
    ("PlayerCrouchIdle", True, (1, 25), None, 0),
    ("PlayerCrouchWalk", True, (1, 7, 13, 19, 25), (1, 7, 13, 19, 25), 0),
    ("PlayerWalkBack", False, (1, 7, 13, 19, 25), (1, 19, 13, 7, 25), 0),
    ("PlayerCrouchBack", True, (1, 7, 13, 19, 25), (1, 19, 13, 7, 25), 0),
    ("PlayerStrafeLeft", False, (1, 7, 13, 19, 25), None, 1),
    ("PlayerStrafeRight", False, (1, 7, 13, 19, 25), None, -1),
    ("PlayerCrouchStrafeLeft", True, (1, 7, 13, 19, 25), None, 1),
    ("PlayerCrouchStrafeRight", True, (1, 7, 13, 19, 25), None, -1),
):
    rig.animation_data.action = None
    for index, frame in enumerate(frames):
        key_pose(frame, crouched=crouched, walk_frame=walk_frames[index] if walk_frames else None, strafe=strafe)
    action = rig.animation_data.action
    if action is None:
        raise RuntimeError(f"Failed to author {clip_name}")
    action.name = clip_name
    action.use_fake_user = True

rig.animation_data.action = idle
scene.frame_set(1)
bpy.context.view_layer.update()
bpy.ops.object.select_all(action="DESELECT")
rig.select_set(True)
for obj in scene.objects:
    if obj.type == "MESH":
        obj.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(WORKING), compress=True)
# Runtime geometry is only a shadow caster: opaque PBR color/normal textures
# are wasted here. The editable source above keeps every original material.
# Small eye/eyebrow/eyelash meshes cannot affect the silhouette usefully.
flat = bpy.data.materials.new("Player shadow opaque")
flat.diffuse_color = (0.3, 0.3, 0.3, 1.0)
for obj in scene.objects:
    if obj.type != "MESH":
        continue
    if obj.name in ("ContactBody.eyebrow001", "ContactBody.eyelashes01", "ContactBody.high-poly"):
        obj.select_set(False)
        continue
    obj.data.materials.clear()
    obj.data.materials.append(flat)
bpy.ops.export_scene.gltf(
    filepath=str(RUNTIME),
    export_format="GLB",
    use_selection=True,
    export_skins=True,
    export_animations=True,
    export_animation_mode="ACTIONS",
    export_force_sampling=True,
)
print("PLAYER_SHADOW_SOURCE", WORKING, flush=True)
print("PLAYER_SHADOW_RUNTIME", RUNTIME, flush=True)
