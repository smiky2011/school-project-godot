"""Turn the isolated Sten scene library into a normal portable .blend project.

Run only in a separate Blender --background --factory-startup subprocess with
sten_mk2_working.blend as the input file. Never use inside the live shared scene.
"""

from pathlib import Path

import bpy


if not bpy.app.background:
    raise RuntimeError("This script requires an isolated background Blender")

root = Path(__file__).resolve().parents[2]
source = root / "assets/vendor/weapon_visual/sten_mk2/source/sten_mk2_working.blend"
if Path(bpy.data.filepath).resolve() != source.resolve():
    raise RuntimeError("Open the isolated Sten .blend before using this script")
if {item.name for item in bpy.data.scenes} not in (
    {"StenWeaponProduction"},
    {"Scene", "StenWeaponProduction"},
):
    raise RuntimeError("Other scenes are present; refusing to save")
scene = bpy.data.scenes.get("StenWeaponProduction")
if scene is None or {obj.name for obj in scene.objects} != {
    "Sten Mk II source mesh",
    "StenBody",
    "StenMagazine",
}:
    raise RuntimeError("Unexpected scene; refusing to save")
for other in list(bpy.data.scenes):
    if other != scene:
        bpy.data.scenes.remove(other)
for image in bpy.data.images:
    if image.source == "FILE" and not Path(bpy.path.abspath(image.filepath)).is_file():
        raise FileNotFoundError(image.filepath)
result = bpy.ops.wm.save_as_mainfile(filepath=str(source), relative_remap=True)
print("SAVED_PORTABLE_STEN", result, source)
