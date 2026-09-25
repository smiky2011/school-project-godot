"""Inspect the original Sten FBX in an isolated Blender subprocess.

Usage: Blender --background --factory-startup --python tools/art/weapon_inspect.py
"""

from collections import defaultdict
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
FBX = ROOT / "assets/vendor/weapon_visual/sten_mk2/source/original/sten_low.fbx"

before_import = set(bpy.data.objects)
bpy.ops.import_scene.fbx(filepath=str(FBX), use_image_search=False)

for obj in set(bpy.data.objects) - before_import:
    if obj.type != "MESH":
        print("OBJECT", obj.name, obj.type)
        continue
    mesh = obj.data
    print(
        "MESH",
        obj.name,
        "vertices",
        len(mesh.vertices),
        "polygons",
        len(mesh.polygons),
        "dimensions",
        tuple(round(v, 5) for v in obj.dimensions),
        "scale",
        tuple(round(v, 5) for v in obj.scale),
        "materials",
        [material.name for material in mesh.materials],
        "uv_layers",
        [layer.name for layer in mesh.uv_layers],
    )

    parent = list(range(len(mesh.vertices)))

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    def union(a, b):
        parent[find(a)] = find(b)

    for edge in mesh.edges:
        union(edge.vertices[0], edge.vertices[1])

    components = defaultdict(list)
    for vertex in mesh.vertices:
        components[find(vertex.index)].append(vertex.index)

    ranked = sorted(components.values(), key=len, reverse=True)
    print("COMPONENTS", len(ranked))
    for index, group in enumerate(ranked[:30]):
        if len(group) < 10:
            break
        points = [obj.matrix_world @ mesh.vertices[v].co for v in group]
        lo = Vector(min(p[axis] for p in points) for axis in range(3))
        hi = Vector(max(p[axis] for p in points) for axis in range(3))
        print(
            "COMPONENT",
            index,
            "vertices",
            len(group),
            "min",
            tuple(round(v, 5) for v in lo),
            "max",
            tuple(round(v, 5) for v in hi),
        )
