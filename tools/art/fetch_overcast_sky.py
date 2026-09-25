"""Fetch the selected CC0 1K pure-sky HDRI from Poly Haven with checksum."""

from pathlib import Path
from hashlib import md5
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/vendor/environment_visual/polyhaven/overcast_soil_puresky"
OUT.mkdir(parents=True, exist_ok=True)
NAME = "overcast_soil_puresky_1k.hdr"
URL = f"https://dl.polyhaven.org/file/ph-assets/HDRIs/hdr/1k/{NAME}"
EXPECTED_MD5 = "7fbca6264f4618a787092b9e1679a578"
target = OUT / NAME
if not target.exists():
    with urlopen(URL, timeout=45) as stream:
        target.write_bytes(stream.read())
actual = md5(target.read_bytes()).hexdigest()
if actual != EXPECTED_MD5:
    raise ValueError(f"Checksum mismatch: {actual}")
print(target.name, target.stat().st_size, actual)
