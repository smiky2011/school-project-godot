"""Build two reusable 9 x 16 m occupied-European-town exterior shells.

Run from the connected Blender MCP with:
    exec(compile(open(PATH).read(), PATH, 'exec'))

All geometry is created in a dedicated scene. The original active scene and
its objects are never deleted or edited. The output .blend is a Blender library
containing only TownArchitectureProduction, and GLBs contain only model meshes.
"""

from pathlib import Path
import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/environment"
SOURCE = OUT / "source"
TEXTURES = OUT / "textures"
OUT.mkdir(parents=True, exist_ok=True)
SOURCE.mkdir(parents=True, exist_ok=True)
(SOURCE / ".gdignore").touch()

SCENE_NAME = "TownArchitectureProduction"
scene = bpy.data.scenes.get(SCENE_NAME)
if scene is None:
    scene = bpy.data.scenes.new(SCENE_NAME)


def material(label, base, rough=None, normal=None, tint=(1, 1, 1, 1)):
    name = "Town_" + label
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    nodes.clear()
    output = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    mat.node_tree.links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
    bsdf.inputs["Base Color"].default_value = tint
    bsdf.inputs["Roughness"].default_value = 0.82
    if base:
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(str(TEXTURES / base), check_existing=True)
        mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    if rough:
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(str(TEXTURES / rough), check_existing=True)
        tex.image.colorspace_settings.name = "Non-Color"
        mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Roughness"])
    if normal:
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(str(TEXTURES / normal), check_existing=True)
        tex.image.colorspace_settings.name = "Non-Color"
        normal_node = nodes.new("ShaderNodeNormalMap")
        normal_node.inputs["Strength"].default_value = 0.65
        mat.node_tree.links.new(tex.outputs["Color"], normal_node.inputs["Color"])
        mat.node_tree.links.new(normal_node.outputs["Normal"], bsdf.inputs["Normal"])
    mat.diffuse_color = tint
    return mat


MATERIALS = [
    material("stone", "stone_base.jpg", "stone_rough.png", "stone_normal.png"),
    material("plaster", "plaster_base.jpg", "plaster_rough.png", "plaster_normal.png"),
    material("slate", "slate_base.png", "slate_rough.png", "slate_normal.png"),
    material("oak", "oak_base.jpg", "oak_rough.png", "oak_normal.png"),
    material("shutter", "shutter_base.jpg", "shutter_rough.png", "shutter_normal.png"),
    material("glass", None, tint=(0.13, 0.16, 0.17, 1)),
    material("metal", None, tint=(0.12, 0.13, 0.13, 1)),
]
for node in MATERIALS[5].node_tree.nodes:
    if node.type == "BSDF_PRINCIPLED":
        node.inputs["Roughness"].default_value = 0.26
for node in MATERIALS[6].node_tree.nodes:
    if node.type == "BSDF_PRINCIPLED":
        node.inputs["Metallic"].default_value = 0.65


class Geometry:
    def __init__(self):
        self.vertices = []
        self.faces = []
        self.uvs = []
        self.materials = []

    def poly(self, points, material_id, uv=None):
        start = len(self.vertices)
        self.vertices.extend(points)
        self.faces.append(tuple(range(start, start + len(points))))
        if uv is None:
            uv = [(p[0] / 2.4, p[2] / 2.4) for p in points]
        self.uvs.append(uv)
        self.materials.append(material_id)

    def box(self, name, cx, cy, cz, sx, sy, sz, mat):
        x0, x1 = cx-sx/2, cx+sx/2
        y0, y1 = cy-sy/2, cy+sy/2
        z0, z1 = cz-sz/2, cz+sz/2
        v = [(x0,y0,z0),(x1,y0,z0),(x1,y1,z0),(x0,y1,z0),
             (x0,y0,z1),(x1,y0,z1),(x1,y1,z1),(x0,y1,z1)]
        for face in ((0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)):
            p = [v[i] for i in face]
            span = [(abs(p[1][k]-p[0][k]) + abs(p[2][k]-p[1][k]), k) for k in range(3)]
            axes = [a for _,a in sorted(span, reverse=True)[:2]]
            uv = [(q[axes[0]] / 2.4, q[axes[1]] / 2.4) for q in p]
            self.poly(p, mat, uv)

    def roof_face(self, points, mat=2, across="x"):
        # One shared textured roof surface, not individual tile objects.
        if across == "x":
            self.poly(points, mat, [(p[1] / 4, p[0] / 4) for p in points])
        else:
            self.poly(points, mat, [(p[0] / 4, p[1] / 4) for p in points])

    def finish(self, name, collection):
        mesh = bpy.data.meshes.new(name + "Mesh")
        mesh.from_pydata(self.vertices, [], self.faces)
        mesh.update()
        uv_layer = mesh.uv_layers.new(name="UVMap")
        for i, polygon in enumerate(mesh.polygons):
            polygon.material_index = self.materials[i]
            for loop, uv in zip(polygon.loop_indices, self.uvs[i]):
                uv_layer.data[loop].uv = uv
        for mat in MATERIALS:
            mesh.materials.append(mat)
        obj = bpy.data.objects.new(name, mesh)
        collection.objects.link(obj)
        return obj


def add_wall(grid, axis, plane, coord_min, coord_max, height, openings, mat):
    # Segmented masonry gives a real 0.32 m recess at every window and door.
    cuts_x = sorted(set([coord_min, coord_max] + [v for opening in openings for v in (opening[0], opening[1])]))
    cuts_z = sorted(set([0.0, height] + [v for opening in openings for v in (opening[2], opening[3])]))
    for low, high in zip(cuts_x[:-1], cuts_x[1:]):
        for z0, z1 in zip(cuts_z[:-1], cuts_z[1:]):
            center, z_mid = (low+high)/2, (z0+z1)/2
            if any(a <= center <= b and c <= z_mid <= d for a,b,c,d in openings):
                continue
            if axis == "x":
                grid.box("wall", plane, center, z_mid, 0.34, high-low, z1-z0, mat)
            else:
                grid.box("wall", center, plane, z_mid, high-low, 0.34, z1-z0, mat)


def trim_opening(g, axis, plane, center, low, high, width, is_door=False, shutters=False):
    stone = 0
    wood = 3
    shutter = 4
    glass = 5
    metal = 6
    # Wall blocks are 0.34 m thick. Trim must begin beyond their outer face
    # (plane +/- 0.17), otherwise the shutter panels vanish inside masonry.
    outward = -1 if plane < 0 else 1
    edge = plane + outward * 0.19
    inner = plane + (0.27 if plane < 0 else -0.27)
    h = high - low
    if axis == "y":
        g.box("lintel", center, edge, high+0.08, width+0.32, 0.18, 0.18, stone)
        g.box("sill", center, edge+outward*0.055, low-0.06, width+0.34, 0.28, 0.12, stone)
        for x in (center-width/2-0.055, center+width/2+0.055):
            g.box("jamb", x, edge, (low+high)/2, 0.11, 0.16, h+0.11, stone)
        g.box("leaf", center, inner, (low+high)/2, width-0.08, 0.05, h-0.10, wood if is_door else glass)
        if is_door:
            for i in range(3):
                g.box("door field", center, inner+outward*0.035, low+0.38+i*0.56, width-0.28, 0.035, 0.41, wood)
            g.box("door knob", center+0.38, inner+outward*0.085, low+1.05, 0.08, 0.08, 0.08, metal)
        else:
            for x in (center-width/2+0.045, center+width/2-0.045, center):
                g.box("window frame", x, inner+outward*0.045, (low+high)/2, 0.075, 0.075, h, wood)
            for z in (low+0.03, (low+high)/2, high-0.03):
                g.box("window frame", center, inner+outward*0.045, z, width, 0.075, 0.07, wood)
            if shutters:
                for sign in (-1, 1):
                    sx = center+sign*(width/2+0.28)
                    g.box("shutter panel", sx, edge+outward*0.06, (low+high)/2, 0.45, 0.11, h, shutter)
                    for j in range(7):
                        g.box("shutter louver", sx, edge+outward*0.13, low+0.14+j*(h-0.28)/6, 0.4, 0.04, 0.045, wood)
    else:
        frame_x = edge + (0.03 if edge > 0 else -0.03)
        inset_x = plane + (0.27 if plane < 0 else -0.27)
        if is_door:
            # Shut, paneled leaf; the solid plot collider is truthful here.
            g.box("closed side leaf", inset_x, center, (low+high)/2, 0.06, width-0.08, h-0.08, wood)
            for i in range(3):
                g.box("side door field", frame_x, center, low+0.4+i*0.56, 0.045, width-0.25, 0.42, wood)
            g.box("side door knob", frame_x+(0.08 if frame_x>0 else -0.08), center+0.31, low+1.06, 0.06, 0.07, 0.07, metal)
        else:
            g.box("side pane", inset_x, center, (low+high)/2, 0.02, width-0.08, h-0.08, glass)
            for yy in (center-width/2, center, center+width/2):
                g.box("side frame", frame_x, yy, (low+high)/2, 0.09, 0.075, h, wood)
            for zz in (low, (low+high)/2, high):
                g.box("side frame", frame_x, center, zz, 0.09, width, 0.075, wood)
            if shutters:
                for sign in (-1, 1):
                    sy = center+sign*(width/2+0.26)
                    g.box("side shutter", frame_x, sy, (low+high)/2, 0.10, 0.42, h, shutter)
                    for j in range(6):
                        g.box("side shutter louver", frame_x+(0.075 if frame_x>0 else -0.075), sy,
                              low+0.16+j*(h-0.32)/5, 0.05, 0.38, 0.045, wood)
        g.box("side sill", frame_x, center, low-0.06, 0.29, width+0.26, 0.12, stone)
        g.box("side lintel", frame_x, center, high+0.07, 0.19, width+0.2, 0.18, stone)
        for yy in (center-width/2-0.05, center+width/2+0.05):
            g.box("side jamb", frame_x, yy, (low+high)/2, 0.16, 0.11, h, stone)


def make_house(name, style):
    collection = bpy.data.collections.get(name)
    if collection is None:
        collection = bpy.data.collections.new(name)
        scene.collection.children.link(collection)
    # Safe rerun removes only our own collection's objects.
    for obj in list(collection.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    g = Geometry()
    wall_mat = 0 if style == "stone_gable" else 1
    front = -8.0
    back = 8.0
    eaves = 5.85 if style == "stone_gable" else 5.55
    door_x = -2.35 if style == "stone_gable" else 2.25
    window_xs = (0.6, 2.85) if style == "stone_gable" else (-2.8, -0.45)
    front_openings = [(door_x-0.61, door_x+0.61, 0, 2.26)]
    front_openings += [(x-0.57, x+0.57, 0.93, 2.33) for x in window_xs]
    front_openings += [(x-0.56, x+0.56, 3.46, 4.88) for x in (-2.7, 0, 2.7)]
    add_wall(g, "y", front, -4.5, 4.5, eaves, front_openings, wall_mat)
    add_wall(g, "y", back, -4.5, 4.5, eaves, [], wall_mat)
    for sign in (-1, 1):
        ys = (-5.65, -2.05, 1.55, 5.15)
        side_openings = []
        for y in ys:
            if y == -2.05 and sign == 1:
                side_openings.append((y-0.60, y+0.60, 0, 2.26))
            else:
                side_openings.append((y-0.53, y+0.53, 0.93, 2.30))
            side_openings.append((y-0.53, y+0.53, 3.43, 4.82))
        add_wall(g, "x", sign*4.5, -8.0, 8.0, eaves, side_openings, wall_mat)
        for y0,y1,z0,z1 in side_openings:
            trim_opening(g, "x", sign*4.5, (y0+y1)/2, z0, z1, y1-y0,
                         is_door=(z0 == 0), shutters=(z0 > 0 and (style == "plaster_hip" or z0 > 3)))
    for x0,x1,z0,z1 in front_openings:
        trim_opening(g, "y", front, (x0+x1)/2, z0, z1, x1-x0,
                     is_door=(z0 == 0), shutters=(z0 > 0 and (style == "plaster_hip" or z0 > 3)))
    # Dressed stone base, corner quoins, band course and projecting cornice.
    for y in (front-0.04, back+0.04):
        g.box("stone plinth", 0, y, 0.21, 9.1, 0.46, 0.42, 0)
        g.box("string course", 0, y, 2.88, 9.15, 0.19, 0.16, 0)
        g.box("cornice", 0, y, eaves-0.13, 9.45, 0.32, 0.25, 0)
    for x in (-4.51, 4.51):
        g.box("side plinth", x, 0, 0.21, 0.46, 16, 0.42, 0)
        g.box("side course", x, 0, 2.88, 0.19, 16, 0.16, 0)
        g.box("eaves", x, 0, eaves-0.10, 0.4, 16.35, 0.22, 3)
        for y in (-8.0, 8.0):
            for z in (0.72, 1.55, 2.38, 3.35, 4.25, 5.1):
                g.box("quoin", x, y, z, 0.38, 0.43, 0.34, 0)
    # Drainage detail reads from street level.
    g.box("gutter", -4.8, 0, eaves-0.06, 0.12, 16.6, 0.15, 6)
    g.box("downpipe", -4.76, front-0.1, 2.55, 0.10, 0.12, 5.05, 6)
    g.box("downpipe elbow", -4.72, front-0.1, 0.22, 0.18, 0.12, 0.12, 6)
    ridge = eaves + (2.15 if style == "stone_gable" else 1.9)
    if style == "stone_gable":
        g.poly([(-4.5,-8.0,eaves),(4.5,-8.0,eaves),(0,-8.0,ridge)], 0,
               [(0,0),(3.75,0),(1.875,0.9)])
        g.poly([(4.5,8.0,eaves),(-4.5,8.0,eaves),(0,8.0,ridge)], 0,
               [(0,0),(3.75,0),(1.875,0.9)])
        g.roof_face([(-4.9,-8.4,eaves-0.02),(0,-8.4,ridge),(0,8.4,ridge),(-4.9,8.4,eaves-0.02)])
        g.roof_face([(0,-8.4,ridge),(4.9,-8.4,eaves-0.02),(4.9,8.4,eaves-0.02),(0,8.4,ridge)])
        for y in (-8.4,8.4):
            for sign in (-1,1):
                # A full-length 11 cm rake board closes each visible roof edge.
                x0 = sign*4.9
                x1 = 0
                board = [(x0,y,eaves-0.10),(x0,y,eaves+0.03),
                         (x1,y,ridge+0.03),(x1,y,ridge-0.10)]
                g.poly(board, 3, [(0,0),(0,0.06),(2.25,0.06),(2.25,0)])
    else:
        # Four sloping planes and a shortened ridge change the street silhouette.
        g.roof_face([(-4.9,-8.4,eaves),(0,-5.75,ridge),(0,5.75,ridge),(-4.9,8.4,eaves)])
        g.roof_face([(0,-5.75,ridge),(4.9,-8.4,eaves),(4.9,8.4,eaves),(0,5.75,ridge)])
        g.roof_face([(-4.9,-8.4,eaves),(4.9,-8.4,eaves),(0,-5.75,ridge)], across="y")
        g.roof_face([(0,5.75,ridge),(4.9,8.4,eaves),(-4.9,8.4,eaves)], across="y")
    g.box("ridge cap", 0,0 if style == "stone_gable" else 0, ridge+0.02,
          0.27, 16.8 if style == "stone_gable" else 11.5, 0.15, 6)
    for x in (-4.9, 4.9):
        g.box("roof edge fascia", x, 0, eaves-0.035, 0.11, 16.8, 0.17, 3)
    # Lipped brick chimney rather than an anonymous vertical box.
    chimney_x = 2.75 if style == "stone_gable" else -2.8
    chimney_y = 4.75 if style == "stone_gable" else -3.55
    chimney_bottom = eaves + 0.18
    chimney_top = ridge + 1.27
    g.box("chimney shaft", chimney_x, chimney_y, (chimney_bottom+chimney_top)/2,
          0.95, 0.8, chimney_top-chimney_bottom, 0)
    g.box("chimney cap", chimney_x, chimney_y, ridge+1.39, 1.18, 1.02, 0.25, 0)
    g.box("chimney hollow", chimney_x, chimney_y, ridge+1.525, 0.52, 0.42, 0.03, 6)
    if style == "plaster_hip":
        # A small dormer gives a second roof-line punctuation without changing footprint.
        g.box("dormer body", -1.4, -3.8, ridge-0.48, 1.58, 0.85, 0.90, 1)
        g.box("dormer pane", -1.4, -4.255, ridge-0.45, 0.94, 0.04, 0.64, 5)
        g.box("dormer cap", -1.4, -3.8, ridge+0.03, 1.84, 1.05, 0.12, 2)
    return g.finish(name, collection)


models = [make_house("TownhouseStoneGable", "stone_gable"),
          make_house("TownhousePlasterHip", "plaster_hip")]

# A stand-alone editable native source. Library write avoids changing the
# open user's blend filepath, active scene, or default-scene objects.
bpy.data.libraries.write(str(SOURCE / "townhouses_9x16.blend"), {scene}, path_remap="RELATIVE")

old_scene = bpy.context.window.scene
try:
    bpy.context.window.scene = scene
    for obj in models:
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        filepath = OUT / ("townhouse_stone_gable_9x16.glb" if "Stone" in obj.name else "townhouse_plaster_hip_9x16.glb")
        bpy.ops.export_scene.gltf(filepath=str(filepath), export_format="GLB", use_selection=True,
                                  use_active_scene=True,
                                  export_apply=True, export_texcoords=True, export_normals=True,
                                  export_materials="EXPORT")
finally:
    bpy.context.window.scene = old_scene

print("ARCHITECTURE_OUTPUT", [(m.name, len(m.data.vertices), len(m.data.polygons)) for m in models])
