"""Convert Lotnik's Unity Sten maps into a glTF occlusion/roughness/metal map.

The original files are retained unchanged under source/original. Unity's
metalness RGB and smoothness alpha become glTF's B and inverted G channels;
the separate occlusion map supplies R. This is a deterministic channel pack,
not a repaint of the author's texture.
"""

from pathlib import Path

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[2]
ASSET = ROOT / "assets/vendor/weapon_visual/sten_mk2"
SOURCE = ASSET / "source/original"
OUTPUT = ASSET / "source/converted/sten_orm.png"


def main() -> None:
    metal = Image.open(SOURCE / "sten_metalness.tga").convert("RGBA")
    occlusion = Image.open(SOURCE / "sten_occlusion.png").convert("RGB")
    if metal.size != (2048, 2048) or occlusion.size != metal.size:
        raise ValueError("Unexpected Sten map dimensions")
    metallic = metal.getchannel("R")
    roughness = ImageChops.invert(metal.getchannel("A"))
    ambient_occlusion = occlusion.getchannel("R")
    packed = Image.merge("RGB", (ambient_occlusion, roughness, metallic))
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    packed.save(OUTPUT, optimize=True)
    print(OUTPUT)


if __name__ == "__main__":
    main()
