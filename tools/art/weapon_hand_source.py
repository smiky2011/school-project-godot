"""Save a self-contained editable .blend from the two posed CC0 hand GLBs.

Run only as Blender --background --factory-startup with no .blend input. It
never edits the upstream MakeHuman character source or the live shared scene.
"""

from pathlib import Path

import bpy


if not bpy.app.background or bpy.data.filepath:
    raise RuntimeError("Use a fresh isolated background Blender process")
if {o.name for o in bpy.context.scene.objects} != {"Cube", "Camera", "Light"}:
    raise RuntimeError("Unexpected startup scene; refusing to alter it")
root = Path(__file__).resolve().parents[2]
folder = root / "assets/player/hands"
scene = bpy.data.scenes.new("StenGripHandsAuthoring")
bpy.context.window.scene = scene
for side, offset in (("left", -0.18), ("right", 0.18)):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(folder / f"hand_{side}_grip.glb"))
    imported = set(bpy.data.objects) - before
    meshes = [obj for obj in imported if obj.type == "MESH"]
    if len(meshes) != 1:
        raise RuntimeError(f"Expected one mesh in {side} hand")
    meshes[0].location.x = offset
    meshes[0].name = f"GripHand{side.title()}"
startup = bpy.data.scenes.get("Scene")
if startup is not None:
    bpy.data.scenes.remove(startup)
bpy.ops.file.pack_all()
out = folder / "source/grip_hands_working.blend"
out.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(out), relative_remap=True)
print("HAND_SOURCE", out, len(scene.objects), [(image.name, image.packed_file is not None) for image in bpy.data.images])
