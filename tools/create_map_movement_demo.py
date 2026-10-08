#!/usr/bin/env python3
"""Materialize the independent town movement project from existing project assets.

The tracked demo contains its authored scene and gameplay scripts. This script
copies unchanged shared visuals into its own asset tree, so the completed demo
can be opened or copied without linking back to the mission project.
"""

from pathlib import Path
import shutil


ROOT = Path(__file__).resolve().parents[1]
DEMO = ROOT / "demos" / "map_movement"
WORLD_SCRIPTS = (
    "facade_variation.gd",
    "pbr_library.gd",
    "service_wing_visual.gd",
    "town_atmosphere.gd",
    "town_backdrop.gd",
    "town_dressing.gd",
    "town_ground.gd",
    "town_ground.gdshader",
    "town_presentation.gd",
)
MODEL_NAMES = (
    "jacaranda_tree",
    "metal_jerrycan_green",
    "old_military_crate",
    "painted_wooden_bench",
    "shrub_02",
    "street_lamp_01",
    "street_lamp_02",
    "vintage_oil_lamp",
    "vintage_radio_transceiver",
    "weed_plant_02",
    "wooden_bookshelf_worn",
    "wooden_bucket_01",
    "wooden_crate_01",
    "wooden_military_crate",
    "wicker_basket_01",
    "nettle_plant",
)


def copy_file(relative: str) -> None:
    source = ROOT / relative
    if not source.is_file():
        raise FileNotFoundError(source)
    target = DEMO / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)


def copy_tree(relative: str) -> None:
    source = ROOT / relative
    if not source.is_dir():
        raise FileNotFoundError(source)
    for path in source.rglob("*"):
        if not path.is_file():
            continue
        if path.name in {".DS_Store", ".gdignore"} or path.suffix == ".import":
            continue
        copy_file(path.relative_to(ROOT).as_posix())


def main() -> None:
    for name in WORLD_SCRIPTS:
        copy_file(f"scripts/world/{name}")
    copy_file("scripts/fx/fx_textures.gd")
    for relative in (
        "assets/environment",
        "assets/world_materials",
        "assets/vendor/environment_visual",
        "assets/vendor/polyhaven/materials",
        "assets/vendor/polyhaven/wooden_crate_02",
        "assets/vendor/polyhaven_cc0/texture",
        "assets/vendor/polyhaven_cc0/hdri",
    ):
        copy_tree(relative)
    copy_file("assets/vendor/polyhaven/LICENSE.txt")
    for name in MODEL_NAMES:
        copy_tree(f"assets/vendor/polyhaven_cc0/model/{name}")
    # Keep the Blender source beside its exported townhouses, but do not ask
    # Godot to re-import it while opening the ready-to-use GLB files.
    (DEMO / "assets" / "environment" / "source" / ".gdignore").touch()
    print(f"Standalone demo ready: {DEMO}")


if __name__ == "__main__":
    main()
