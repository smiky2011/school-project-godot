"""Prepare repeatable PBR maps for the town architecture models.

The stone/plaster EXRs are extracted from the CC0 Poly Haven source ZIPs already
tracked in this project. Slate and painted timber are original procedural maps.
"""

from pathlib import Path
import os
import zipfile

os.environ["OPENCV_IO_ENABLE_OPENEXR"] = "1"
import cv2
import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/environment/textures"
OUT.mkdir(parents=True, exist_ok=True)
WORLD_OUT = ROOT / "assets/world_materials"
WORLD_OUT.mkdir(parents=True, exist_ok=True)


def source_map(asset: str, kind: str, output: str) -> None:
    archive = ROOT / f"assets/vendor/polyhaven/source/{asset}_1k.blend.zip"
    ext = "jpg" if kind == "diff" else "exr"
    with zipfile.ZipFile(archive) as zf:
        data = zf.read(f"textures/{asset}_{kind}_1k.{ext}")
    if kind == "diff":
        (OUT / output).write_bytes(data)
        return
    image = cv2.imdecode(np.frombuffer(data, np.uint8), cv2.IMREAD_UNCHANGED)
    if image is None:
        raise RuntimeError(f"Could not decode {asset} {kind}")
    if image.ndim == 2:
        image = np.repeat(image[:, :, None], 3, axis=2)
    image = np.clip(image, 0, 1)
    cv2.imwrite(str(OUT / output), (image * 255).astype(np.uint8))


for asset, label in (("stone_wall", "stone"), ("plastered_stone_wall", "plaster")):
    source_map(asset, "diff", f"{label}_base.jpg")
    source_map(asset, "rough", f"{label}_rough.png")
    source_map(asset, "nor_gl", f"{label}_normal.png")

with zipfile.ZipFile(ROOT / "assets/vendor/polyhaven/source/muddy_tracks_1k.blend.zip") as zf:
    for kind, output in (("rough", "muddy_tracks_rough.png"), ("nor_gl", "muddy_tracks_normal.png")):
        data = zf.read(f"textures/muddy_tracks_{kind}_1k.exr")
        image = cv2.imdecode(np.frombuffer(data, np.uint8), cv2.IMREAD_UNCHANGED)
        if image.ndim == 2:
            image = np.repeat(image[:, :, None], 3, axis=2)
        cv2.imwrite(str(WORLD_OUT / output), (np.clip(image, 0, 1) * 255).astype(np.uint8))


def normal_from_height(height: np.ndarray, strength: float) -> Image.Image:
    dx = np.roll(height, 1, 1) - np.roll(height, -1, 1)
    dy = np.roll(height, 1, 0) - np.roll(height, -1, 0)
    vec = np.stack((dx * strength, dy * strength, np.ones_like(height)), axis=-1)
    vec /= np.maximum(np.linalg.norm(vec, axis=2, keepdims=True), 0.0001)
    return Image.fromarray(((vec * 0.5 + 0.5) * 255).astype(np.uint8), "RGB")


rng = np.random.default_rng(1944)
size = 1024
ys, xs = np.indices((size, size))
row = ys // 70
col = (xs + (row % 2) * 96) // 192
grain = rng.normal(0, 5.2, (size, size))
base = np.empty((size, size, 3), np.float32)
height = np.zeros((size, size), np.float32)
rough = np.empty((size, size), np.uint8)
for rr in range(16):
    for cc in range(-1, 8):
        mask = (row == rr) & (col == cc)
        shade = rng.normal(0, 10)
        base[mask] = np.array([76, 84, 88]) + shade
        rough[mask] = np.clip(212 + rng.normal(0, 9), 0, 255)
        height[mask] = rng.normal(0, 0.08)
edge_h = ys % 70
edge_v = (xs + (row % 2) * 96) % 192
border = (edge_h < 3) | (edge_v < 3)
base[border] *= 0.60
height[border] -= 0.32
base += grain[:, :, None]
base += (ys % 70)[:, :, None] * 0.10
Image.fromarray(np.clip(base, 0, 255).astype(np.uint8), "RGB").save(OUT / "slate_base.png")
Image.fromarray(rough, "L").save(OUT / "slate_rough.png")
normal_from_height(height, 0.9).save(OUT / "slate_normal.png")

for label, rgb in (("oak", (89, 66, 48)), ("shutter", (75, 85, 80))):
    ridges = np.sin(xs * 0.16 + np.sin(ys * 0.027) * 3.0) * 4.0
    noise = rng.normal(0, 5, (size, size))
    tone = ridges + noise
    texture = np.clip(np.array(rgb)[None, None, :] + tone[:, :, None], 0, 255).astype(np.uint8)
    Image.fromarray(texture, "RGB").save(OUT / f"{label}_base.jpg", quality=88)
    Image.fromarray(np.full((size, size), 211 if label == "oak" else 223, np.uint8), "L").save(OUT / f"{label}_rough.png")
    normal_from_height(ridges / 20, 0.5).save(OUT / f"{label}_normal.png")

print(f"Wrote environment maps to {OUT}")
