"""Attach the packed red AO channels to the StG 44 glTF materials."""

import json
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
GLB = ROOT / "assets/vendor/weapon_visual/stg44/runtime/stg44.glb"


def main() -> None:
    contents = GLB.read_bytes()
    magic, version, _ = struct.unpack_from("<4sII", contents)
    if magic != b"glTF" or version != 2:
        raise ValueError("Expected glTF 2.0 binary")
    chunks = []
    offset = 12
    while offset < len(contents):
        length, kind = struct.unpack_from("<I4s", contents, offset)
        offset += 8
        chunks.append((kind, contents[offset:offset + length]))
        offset += length
    if chunks[0][0] != b"JSON":
        raise ValueError("Missing GLB JSON")
    document = json.loads(chunks[0][1])
    expected = {"Barrel", "Belt", "Body", "Magazine", "Stock"}
    if {item["name"] for item in document["materials"]} != expected:
        raise ValueError("Unexpected StG 44 materials")
    if "Magazine" not in {node.get("name") for node in document["nodes"]}:
        raise ValueError("Missing independent magazine")
    for material in document["materials"]:
        orm = material["pbrMetallicRoughness"]["metallicRoughnessTexture"]
        material["occlusionTexture"] = {"index": orm["index"], "strength": 1.0}
    data = json.dumps(document, separators=(",", ":")).encode()
    data += b" " * (-len(data) % 4)
    chunks[0] = (b"JSON", data)
    body = b"".join(struct.pack("<I4s", len(chunk), kind) + chunk for kind, chunk in chunks)
    GLB.write_bytes(struct.pack("<4sII", b"glTF", 2, 12 + len(body)) + body)
    print(GLB)


if __name__ == "__main__":
    main()
