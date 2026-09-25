"""Fetch the three 1K CC0 Poly Haven cobblestone maps used by the town road."""

from pathlib import Path
from hashlib import md5
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/vendor/environment_visual/polyhaven/cobblestone_floor_001"
OUT.mkdir(parents=True, exist_ok=True)
BASE = "https://dl.polyhaven.org/file/ph-assets/Textures"
MAPS = {
    "diff_1k.jpg": ("jpg", "ce056f65334ad835deef495c35e0b3c4"),
    "rough_1k.png": ("png", "cde429b824281ddf596af925bdc2af52"),
    "nor_gl_1k.png": ("png", "36510d340777f7827a2a816abab8fe97"),
}

for suffix, (extension, expected) in MAPS.items():
    name = f"cobblestone_floor_001_{suffix}"
    destination = OUT / name
    if not destination.exists():
        url = f"{BASE}/{extension}/1k/cobblestone_floor_001/{name}"
        with urlopen(url, timeout=30) as stream:
            destination.write_bytes(stream.read())
    actual = md5(destination.read_bytes()).hexdigest()
    if actual != expected:
        raise ValueError(f"Checksum mismatch: {name}: {actual}")
    print(name, destination.stat().st_size, actual)
