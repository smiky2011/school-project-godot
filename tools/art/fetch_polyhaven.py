"""Fetch CC0 Poly Haven assets with checksum verification and provenance.

Usage (from the repository root):
    python3 tools/art/fetch_polyhaven.py hdri kloofendal_48d_partly_cloudy_puresky 2k
    python3 tools/art/fetch_polyhaven.py texture red_brick_03 1k
    python3 tools/art/fetch_polyhaven.py model Barrel_01 1k

Files land in assets/vendor/polyhaven_cc0/<kind>/<asset_id>/ next to a
PROVENANCE.json that records the source page, authors, license, download
date, URLs and MD5 values reported by the Poly Haven API. No account is
needed. Poly Haven publishes every asset under CC0.
"""

import json
import sys
from datetime import date
from hashlib import md5
from pathlib import Path
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[2]
API = "https://api.polyhaven.com"
HEADERS = {"User-Agent": "school-project-godot asset fetch"}


def get_json(url):
    with urlopen(Request(url, headers=HEADERS), timeout=60) as stream:
        return json.load(stream)


def download(url, target, expected_md5):
    target.parent.mkdir(parents=True, exist_ok=True)
    if not target.exists() or md5(target.read_bytes()).hexdigest() != expected_md5:
        with urlopen(Request(url, headers=HEADERS), timeout=120) as stream:
            target.write_bytes(stream.read())
    actual = md5(target.read_bytes()).hexdigest()
    if expected_md5 and actual != expected_md5:
        raise ValueError(f"Checksum mismatch for {target.name}: {actual} != {expected_md5}")
    return actual


def main():
    kind, asset_id, res = sys.argv[1], sys.argv[2], (sys.argv[3] if len(sys.argv) > 3 else "1k")
    info = get_json(f"{API}/info/{asset_id}")
    files = get_json(f"{API}/files/{asset_id}")
    out = ROOT / "assets/vendor/polyhaven_cc0" / kind / asset_id
    records = []
    if kind == "hdri":
        entry = files["hdri"][res]["hdr"]
        name = f"{asset_id}_{res}.hdr"
        records.append((entry["url"], out / name, entry["md5"]))
    elif kind == "texture":
        # Only the maps the game's materials read (pbr_library.gd).
        wanted = {"Diffuse": "diff", "nor_gl": "nor_gl", "Rough": "rough", "AO": "ao"}
        for map_name, suffix in wanted.items():
            if map_name not in files:
                continue
            variants = files[map_name].get(res, {})
            entry = variants.get("jpg") or variants.get("png")
            if entry is None:
                continue
            ext = "jpg" if "jpg" in variants else "png"
            records.append((entry["url"], out / f"{asset_id}_{suffix}_{res}.{ext}", entry["md5"]))
    elif kind == "model":
        gltf = files["gltf"][res]["gltf"]
        records.append((gltf["url"], out / Path(gltf["url"]).name, gltf["md5"]))
        for rel, entry in gltf.get("include", {}).items():
            records.append((entry["url"], out / rel, entry["md5"]))
    else:
        raise SystemExit("kind must be hdri, texture or model")
    manifest = []
    for url, target, expected in records:
        actual = download(url, target, expected)
        manifest.append({"file": str(target.relative_to(out)), "url": url, "md5": actual, "bytes": target.stat().st_size})
        print(target.relative_to(ROOT), target.stat().st_size, actual)
    provenance = {
        "asset_id": asset_id,
        "name": info.get("name"),
        "source_page": f"https://polyhaven.com/a/{asset_id}",
        "authors": info.get("authors"),
        "license": "CC0 1.0 (https://polyhaven.com/license)",
        "downloaded": date.today().isoformat(),
        "resolution": res,
        "account_required": False,
        "files": manifest,
    }
    (out / "PROVENANCE.json").write_text(json.dumps(provenance, indent=2) + "\n")


if __name__ == "__main__":
    main()
