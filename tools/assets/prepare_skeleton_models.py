"""Skeleton enemies from the CC0 KayKit Character Pack: Skeletons 1.0.

Source: https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0 cloned into
C:/Dev/Tools/AssetCache/kaykit-skeletons. Each character keeps only the clips the game plays,
renamed to the project's names, and the binary is compacted to the data those clips and meshes use.
"""
from pathlib import Path
import json, hashlib, shutil
import prepare_3d as pipeline

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "art/models"
CLIPS = {"Walking_A": "walk", "Running_A": "run", "Idle": "idle", "Hit_A": "hit", "Death_C_Skeletons": "death", "Cheer": "rally"}
CHARACTERS = {"Warrior": "skeleton_warrior", "Mage": "skeleton_mage", "Rogue": "skeleton_rogue", "Minion": "skeleton_minion"}
ITEMS = {"Skeleton_Blade": "skeleton_blade", "Skeleton_Shield_Small_A": "skeleton_shield", "Skeleton_Shield_Large_A": "skeleton_shield_large", "Skeleton_Staff": "skeleton_staff", "Skeleton_Axe": "skeleton_axe"}


def compact(data, binary):
    """Keep only bufferViews reachable from accessors/images still referenced, then rebuild the blob."""
    used_accessors = set()
    for mesh in data.get("meshes", []):
        for primitive in mesh["primitives"]:
            used_accessors.update(primitive["attributes"].values())
            if "indices" in primitive: used_accessors.add(primitive["indices"])
            for target in primitive.get("targets", []): used_accessors.update(target.values())
    for skin in data.get("skins", []):
        if "inverseBindMatrices" in skin: used_accessors.add(skin["inverseBindMatrices"])
    for animation in data.get("animations", []):
        for sampler in animation["samplers"]: used_accessors.update((sampler["input"], sampler["output"]))
    accessor_map = {old: new for new, old in enumerate(sorted(used_accessors))}
    accessors = [data["accessors"][old] for old in sorted(used_accessors)]
    used_views = {a["bufferView"] for a in accessors if "bufferView" in a}
    used_views.update(image["bufferView"] for image in data.get("images", []) if "bufferView" in image)
    view_map = {}
    blob = bytearray()
    views = []
    for old in sorted(used_views):
        view = dict(data["bufferViews"][old])
        start = view.get("byteOffset", 0)
        while len(blob) % 4: blob.append(0)
        view["byteOffset"] = len(blob)
        view["buffer"] = 0
        blob.extend(binary[start:start + view["byteLength"]])
        view_map[old] = len(views)
        views.append(view)
    for accessor in accessors:
        if "bufferView" in accessor: accessor["bufferView"] = view_map[accessor["bufferView"]]
    for image in data.get("images", []):
        if "bufferView" in image: image["bufferView"] = view_map[image["bufferView"]]
    for mesh in data.get("meshes", []):
        for primitive in mesh["primitives"]:
            primitive["attributes"] = {k: accessor_map[v] for k, v in primitive["attributes"].items()}
            if "indices" in primitive: primitive["indices"] = accessor_map[primitive["indices"]]
            primitive["targets"] = [{k: accessor_map[v] for k, v in t.items()} for t in primitive.get("targets", [])]
            if not primitive["targets"]: primitive.pop("targets")
    for skin in data.get("skins", []):
        if "inverseBindMatrices" in skin: skin["inverseBindMatrices"] = accessor_map[skin["inverseBindMatrices"]]
    for animation in data.get("animations", []):
        for sampler in animation["samplers"]:
            sampler["input"] = accessor_map[sampler["input"]]
            sampler["output"] = accessor_map[sampler["output"]]
    data["accessors"] = accessors
    data["bufferViews"] = views
    return blob


def character(source, name):
    data, binary = pipeline.read(pipeline.locate("kaykit-skeletons", "Characters/gltf/Skeleton_%s.glb" % source))
    kept = []
    for animation in data["animations"]:
        if animation["name"] in CLIPS:
            animation["name"] = CLIPS[animation["name"]]
            kept.append(animation)
    missing = set(CLIPS.values()) - {a["name"] for a in kept}
    if missing: raise RuntimeError("Missing clips %s in %s" % (missing, source))
    data["animations"] = kept
    blob = compact(data, binary)
    pipeline.write(OUT / (name + ".glb"), data, blob)
    return {"file": name + ".glb", "source": "Skeleton_%s.glb" % source, "clips": [a["name"] for a in kept]}


def main():
    report = [character(source, name) for source, name in CHARACTERS.items()]
    for source, name in ITEMS.items():
        data, binary = pipeline.read(pipeline.locate("kaykit-skeletons", "Assets/gltf/%s.gltf" % source))
        pipeline.write(OUT / (name + ".glb"), data, binary)
    shutil.copyfile(pipeline.locate("kaykit-skeletons", "addons/kaykit_character_pack_skeletons/LICENSE.txt"), ROOT / "art/licenses/kaykit-skeletons.txt")
    manifest_path = OUT / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8-sig"))
    names = {entry["file"] for entry in report}
    manifest["characters"] = [c for c in manifest.get("characters", []) if c["file"] not in names] + report
    manifest["files"] = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(OUT.glob("*.glb"))}
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
