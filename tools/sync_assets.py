"""Copy finished art into the Godot project (Godot only loads files under res://).

  python tools/sync_assets.py            # everything with a usable output
  python tools/sync_assets.py --phase M1

Per category, the deliverable is:
  character/boss -> animated.glb (or humanoid.glb if no clips)  => game/assets/characters/<id>.glb
  prop/piece/decor -> prepped.glb                               => game/assets/<category>s/<id>.glb
  icon/portrait/texture -> concept.png                          => game/assets/<category>s/<id>.png
"""
import argparse
import csv
import pathlib
import shutil

ROOT = pathlib.Path(__file__).resolve().parent.parent
ART, GAME = ROOT / "art", ROOT / "game" / "assets"
SRC = {"character": ["animated.glb", "humanoid.glb"], "boss": ["animated.glb", "humanoid.glb"],
       "prop": ["prepped.glb"], "piece": ["prepped.glb"], "decor": ["prepped.glb"],
       "icon": ["concept.png"], "portrait": ["concept.png"], "texture": ["concept.png"]}
DEST = {"boss": "characters"}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--phase")
    args = ap.parse_args()
    rows = list(csv.DictReader(open(ROOT / "assets" / "manifest.csv", encoding="utf-8")))
    copied, missing = 0, []
    for r in rows:
        if args.phase and r["phase"] != args.phase:
            continue
        cat = r["category"]
        d = ART / (cat + "s") / r["id"]
        src = next((d / f for f in SRC[cat] if (d / f).exists()), None)
        if src is None:
            missing.append(r["id"])
            continue
        out_dir = GAME / DEST.get(cat, cat + "s")
        out_dir.mkdir(parents=True, exist_ok=True)
        dst = out_dir / (r["id"] + src.suffix)
        if not dst.exists() or dst.stat().st_mtime < src.stat().st_mtime or dst.stat().st_size != src.stat().st_size:
            shutil.copy2(src, dst)
            copied += 1
    print(f"synced {copied} file(s); not ready: {', '.join(missing) if missing else 'none'}")


if __name__ == "__main__":
    main()
