"""Attach the Sten's packed occlusion channel to Blender's exported GLB.

Blender exports the packed image for roughness/metallic but does not infer an
occlusionTexture from the same image. glTF permits the same texture to serve
both roles, with R for occlusion, G for roughness and B for metallic.
"""

import json
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
GLB = ROOT / "assets/vendor/weapon_visual/sten_mk2/runtime/sten_mk2.glb"


def main() -> None:
    contents = GLB.read_bytes()
    magic, version, _ = struct.unpack_from("<4sII", contents)
    if magic != b"glTF" or version != 2:
        raise ValueError("Expected a glTF 2.0 binary")
    offset = 12
    chunks: list[tuple[bytes, bytes]] = []
    while offset < len(contents):
        length, kind = struct.unpack_from("<I4s", contents, offset)
        offset += 8
        chunks.append((kind, contents[offset : offset + length]))
        offset += length
    if not chunks or chunks[0][0] != b"JSON":
        raise ValueError("Missing GLB JSON chunk")
    document = json.loads(chunks[0][1])
    if {node.get("name") for node in document["nodes"]} != {"StenBody", "StenMagazine"}:
        raise ValueError("GLB contains unexpected meshes or scenes")
    for material in document["materials"]:
        texture = material["pbrMetallicRoughness"]["metallicRoughnessTexture"]
        material["occlusionTexture"] = {"index": texture["index"], "strength": 1.0}
    json_bytes = json.dumps(document, separators=(",", ":"), ensure_ascii=False).encode()
    json_bytes += b" " * (-len(json_bytes) % 4)
    chunks[0] = (b"JSON", json_bytes)
    body = b"".join(struct.pack("<I4s", len(data), kind) + data for kind, data in chunks)
    GLB.write_bytes(struct.pack("<4sII", b"glTF", 2, 12 + len(body)) + body)
    print(GLB)


if __name__ == "__main__":
    main()
