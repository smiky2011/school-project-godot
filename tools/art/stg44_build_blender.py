"""Build the isolated editable StG 44 project and runtime GLB.

Run with Blender --background --factory-startup --python this_file. Never run
inside a user's live Blender scene. The original FBX and maps stay unchanged.
"""

from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parents[2]
ASSET = ROOT / "assets/vendor/weapon_visual/stg44"
FBX = ASSET / "source/original/source/STG44_Full.fbx"
CONVERTED = ASSET / "source/converted"
BLEND = ASSET / "source/stg44_working.blend"
GLB = ASSET / "runtime/stg44.glb"
PARTS = {"Barrel", "Belt", "Body", "Magazine", "Stock"}


def texture(path: Path, data: bool = False):
    image = bpy.data.images.load(str(path), check_existing=True)
    if data:
        image.colorspace_settings.name = "Non-Color"
    return image


def material_for(part: str):
    material = bpy.data.materials.get(part)
    if material is None:
        raise RuntimeError(f"Missing source material {part}")
    material.use_nodes = True
    nodes = material.node_tree.nodes
    nodes.clear()
    links = material.node_tree.links
    output = nodes.new("ShaderNodeOutputMaterial")
    output.location = (680, 100)
    shader = nodes.new("ShaderNodeBsdfPrincipled")
    shader.location = (400, 100)
    links.new(shader.outputs["BSDF"], output.inputs["Surface"])
    base = nodes.new("ShaderNodeTexImage")
    base.name = "Base Color"
    base.location = (-620, 320)
    base.image = texture(CONVERTED / f"{part.lower()}_albedo.jpg")
    links.new(base.outputs["Color"], shader.inputs["Base Color"])
    normal_image = nodes.new("ShaderNodeTexImage")
    normal_image.name = "Normal"
    normal_image.location = (-620, 40)
    normal_image.image = texture(CONVERTED / f"{part.lower()}_normal.png", True)
    normal = nodes.new("ShaderNodeNormalMap")
    normal.location = (90, -100)
    links.new(normal_image.outputs["Color"], normal.inputs["Color"])
    links.new(normal.outputs["Normal"], shader.inputs["Normal"])
    orm = nodes.new("ShaderNodeTexImage")
    orm.name = "Occlusion Roughness Metallic"
    orm.location = (-620, -250)
    orm.image = texture(CONVERTED / f"{part.lower()}_orm.png", True)
    channels = nodes.new("ShaderNodeSeparateColor")
    channels.location = (-300, -240)
    links.new(orm.outputs["Color"], channels.inputs["Color"])
    links.new(channels.outputs["Green"], shader.inputs["Roughness"])
    links.new(channels.outputs["Blue"], shader.inputs["Metallic"])
    return material


def main():
    if not bpy.app.background or bpy.data.filepath:
        raise RuntimeError("Use a fresh isolated background Blender process")
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.fbx(filepath=str(FBX), use_image_search=False)
    meshes = {o.name for o in bpy.data.objects if o.type == "MESH"}
    expected = {"Barrel", "Belt", "Magazine", "Stock", "Body_Bolt", "Body_FiremodeButton_D",
                "Body_FiremodeButton_E", "Body_Piston", "Body_Recievers", "Body_Safety", "Body_Sight",
                "Body_Sight_Distance", "Body_Trigger"}
    if meshes != expected:
        raise RuntimeError(f"Unexpected FBX meshes: {meshes ^ expected}")
    for obj in list(bpy.data.objects):
        if obj.type not in {"MESH", "EMPTY"}:
            bpy.data.objects.remove(obj, do_unlink=True)
    for part in PARTS:
        material_for(part)
    # Keep the original scale, pivots and axis. Blender's glTF exporter maps
    # source +Y forward and Z up to Godot -Z forward and Y up.
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND), relative_remap=True)
    for image in bpy.data.images:
        if image.source == "FILE" and not Path(bpy.path.abspath(image.filepath)).is_file():
            raise FileNotFoundError(image.filepath)
        if image.source == "FILE" and not image.filepath.startswith("//"):
            image.filepath = bpy.path.relpath(image.filepath, start=str(BLEND.parent))
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND), relative_remap=True)
    bpy.ops.export_scene.gltf(filepath=str(GLB), export_format="GLB", export_yup=True,
                              export_texcoords=True, export_normals=True, export_materials="EXPORT",
                              export_image_format="AUTO", export_apply=False)
    print("STG44", BLEND, GLB, "meshes", len(meshes))


main()
