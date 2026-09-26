"""Make compact, deterministic glTF textures from the attributed StG 44 maps."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/vendor/weapon_visual/stg44/source/original/textures"
DEST = ROOT / "assets/vendor/weapon_visual/stg44/source/converted"
SIZE = (1024, 1024)
PARTS = ("Barrel", "Belt", "Body", "Magazine", "Stock")


def resized(part: str, kind: str) -> Image.Image:
    path = SOURCE / f"STG44_{part}_{kind}.tga.png"
    with Image.open(path) as image:
        return image.convert("RGB").resize(SIZE, Image.Resampling.LANCZOS)


def main() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    for part in PARTS:
        name = part.lower()
        resized(part, "BaseColor").save(DEST / f"{name}_albedo.jpg", quality=92, subsampling=0)
        resized(part, "Normal").save(DEST / f"{name}_normal.png", optimize=True)
        ao = resized(part, "AO").getchannel("R")
        roughness = resized(part, "Roughness").getchannel("R")
        metallic = resized(part, "Metallic").getchannel("R")
        Image.merge("RGB", (ao, roughness, metallic)).save(DEST / f"{name}_orm.png", optimize=True)
        print(name, "albedo/normal/ORM", SIZE)


if __name__ == "__main__":
    main()
