"""Re-export or rebuild the neutral scout's static khaki workwear visual.

Run with /Applications/Blender.app/Contents/MacOS/Blender --background
--factory-startup --python tools/art/scout_visual.py. Default mode exports from
the retained, texture-packed scout_idle.blend and works in a fresh checkout.
The optional --rebuild-from-local-prototype mode documents the first creation
from a now-untracked relaxed-arm candidate; it is not needed for re-export.
No original guard file or live Blender scene is modified.
"""

from pathlib import Path
import argparse
import bpy
import numpy as np


ROOT = Path(__file__).resolve().parents[2]
CHAR = ROOT / "assets/vendor/character_visual/makehuman"
SOURCE = CHAR / "previews/guard_workwear_idle.glb"
SOURCE_CLOTH = CHAR / "source/guard_field_cloth.png"
OUT_CLOTH = CHAR / "source/scout_cloth_khaki.png"
OUT_BLEND = CHAR / "source/scout_idle.blend"
OUT_GLB = CHAR / "runtime/scout_idle.glb"


def recolor_cloth() -> bpy.types.Image:
    original = bpy.data.images.load(str(SOURCE_CLOTH), check_existing=True)
    width, height = original.size
    pixels = np.empty(width * height * 4, dtype=np.float32)
    original.pixels.foreach_get(pixels)
    rgba = pixels.reshape((-1, 4))
    # Change only the garment's green-grey fabric map. Preserve luminance,
    # seams, pockets and buttons while warming it to low-saturation khaki.
    luminance = rgba[:, :3] @ np.array([0.30, 0.59, 0.11], dtype=np.float32)
    base = luminance * 1.42 + 0.035
    rgba[:, :3] = np.clip(base[:, None] * np.array([1.20, 1.09, 0.86], dtype=np.float32), 0, 1)
    converted = bpy.data.images.new("scout_cloth_khaki", width=width, height=height, alpha=True)
    converted.pixels.foreach_set(pixels)
    converted.filepath_raw = str(OUT_CLOTH)
    converted.file_format = "PNG"
    converted.save()
    return converted


def export_meshes(meshes: list[bpy.types.Object]) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.export_scene.gltf(
        filepath=str(OUT_GLB), export_format="GLB", use_selection=True,
        use_active_scene=True, export_materials="EXPORT",
    )
    print("SCOUT_EXPORTED", OUT_GLB, "meshes", len(meshes))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--rebuild-from-local-prototype", action="store_true")
    args = parser.parse_args([arg for arg in __import__("sys").argv if arg == "--rebuild-from-local-prototype"])
    if not args.rebuild_from_local_prototype:
        assert OUT_BLEND.is_file(), "Retained scout_idle.blend is required for the default portable re-export"
        bpy.ops.wm.open_mainfile(filepath=str(OUT_BLEND))
        meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
        assert len(meshes) == 8 and all(obj.data.shape_keys is None for obj in meshes)
        export_meshes(meshes)
        return

    # Initial construction only: this reviewed prototype is local evidence,
    # not a dependency of the portable retained-source re-export path.
    assert SOURCE.is_file() and SOURCE_CLOTH.is_file()
    OUT_CLOTH.parent.mkdir(parents=True, exist_ok=True)
    OUT_GLB.parent.mkdir(parents=True, exist_ok=True)

    # This factory-startup subprocess owns its scene, so clearing its default
    # Cube/Camera/Light cannot affect the user's open Blender workspace.
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(SOURCE))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    assert len(meshes) == 8, f"Unexpected scout base mesh count: {len(meshes)}"
    assert not bpy.data.actions, "Scout must be static, without guard animation"
    for obj in meshes:
        assert obj.data.shape_keys is None, f"Unused morph survived on {obj.name}"
        obj.name = obj.name.replace("GuardIdle_", "ScoutIdle_")

    cloth = recolor_cloth()
    clothing_materials = [m for m in bpy.data.materials if "male_casualsuit02" in m.name]
    assert len(clothing_materials) == 1, "Expected one selected workwear material"
    clothing = clothing_materials[0]
    image_nodes = [n for n in clothing.node_tree.nodes if n.type == "TEX_IMAGE" and n.image is not None]
    changed = 0
    for node in image_nodes:
        if "guard_field_cloth" in node.image.name:
            node.image = cloth
            changed += 1
    assert changed == 1, f"Expected one garment color map, found {changed}"
    clothing.name = "Scout low-saturation khaki workwear"
    for image in list(bpy.data.images):
        if image.users == 0:
            bpy.data.images.remove(image)

    points = [obj.matrix_world @ vert.co for obj in meshes for vert in obj.data.vertices]
    low_z = min(p.z for p in points)  # Blender Z-up; Godot imports to Y-up.
    high_z = max(p.z for p in points)
    assert -0.06 < low_z < 0.06, f"Scout shoe sole origin shifted: {low_z}"
    assert 1.55 < high_z < 1.85, f"Unexpected human height: {high_z}"

    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT_BLEND), compress=True)
    export_meshes(meshes)
    print("SCOUT_READY", OUT_GLB, "meshes", len(meshes), "height", round(high_z - low_z, 4))


if __name__ == "__main__":
    main()
