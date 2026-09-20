"""Generate Pantoo POS launcher icons from the approved master artwork."""

from __future__ import annotations

import json
import shutil
import sys
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
TEAL = (0, 124, 115, 255)
LANCZOS = Image.Resampling.LANCZOS


def resized(source: Image.Image, size: int, *, opaque: bool = False) -> Image.Image:
    image = source.resize((size, size), LANCZOS)
    if not opaque:
        return image
    background = Image.new("RGBA", image.size, TEAL)
    background.alpha_composite(image)
    return background.convert("RGB")


def save_png(source: Image.Image, target: Path, size: int, *, opaque: bool = False) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    resized(source, size, opaque=opaque).save(target, "PNG", optimize=True)


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("Usage: python scripts/generate_app_icons.py <master-icon.png>")

    master = Path(sys.argv[1]).resolve()
    source = Image.open(master).convert("RGBA")
    if source.width != source.height:
        raise SystemExit("Master icon must be square")

    shutil.copy2(master, ROOT / "assets/images/pantoo_pos_icon.png")

    android_legacy = {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }
    android_adaptive = {
        "mdpi": 108,
        "hdpi": 162,
        "xhdpi": 216,
        "xxhdpi": 324,
        "xxxhdpi": 432,
    }
    for density, size in android_legacy.items():
        save_png(source, ROOT / f"android/app/src/main/res/mipmap-{density}/ic_launcher.png", size)
    for density, size in android_adaptive.items():
        drawable = ROOT / f"android/app/src/main/res/drawable-{density}"
        save_png(source, drawable / "ic_launcher_foreground.png", size)
        Image.new("RGB", (size, size), TEAL[:3]).save(
            drawable / "ic_launcher_background.png", "PNG", optimize=True
        )
    save_png(source, ROOT / "android/app/src/main/res/drawable/app_icon.png", 512)

    ios_dir = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    ios_manifest = json.loads((ios_dir / "Contents.json").read_text(encoding="utf-8"))
    for entry in ios_manifest["images"]:
        filename = entry.get("filename")
        if not filename:
            continue
        points = float(entry["size"].split("x")[0])
        scale = int(entry["scale"].removesuffix("x"))
        save_png(source, ios_dir / filename, round(points * scale), opaque=True)

    mac_dir = ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    for size in (16, 32, 64, 128, 256, 512, 1024):
        save_png(source, mac_dir / f"app_icon_{size}.png", size)

    save_png(source, ROOT / "web/favicon.png", 64)
    save_png(source, ROOT / "web/icons/Icon-192.png", 192)
    save_png(source, ROOT / "web/icons/Icon-512.png", 512)
    save_png(source, ROOT / "web/icons/Icon-maskable-192.png", 192, opaque=True)
    save_png(source, ROOT / "web/icons/Icon-maskable-512.png", 512, opaque=True)

    resized(source, 256, opaque=True).save(
        ROOT / "windows/runner/resources/app_icon.ico",
        format="ICO",
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )


if __name__ == "__main__":
    main()
