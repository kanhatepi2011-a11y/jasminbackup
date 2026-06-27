from pathlib import Path
import shutil
import sys
import re

ROOT = Path.cwd()
PACK = Path(__file__).resolve().parents[1]

if not (ROOT / "pubspec.yaml").exists():
    print("ERROR: Run this script from the Flutter project root where pubspec.yaml exists.")
    sys.exit(1)

def copy_tree(src: Path, dst: Path):
    if not src.exists():
        print(f"Missing source: {src}")
        return
    for item in src.rglob("*"):
        rel = item.relative_to(src)
        target = dst / rel
        if item.is_dir():
            target.mkdir(parents=True, exist_ok=True)
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(item, target)

# Copy visible logo assets
copy_tree(PACK / "assets", ROOT / "assets")

# Copy Android real launcher icon files
copy_tree(PACK / "android/app/src/main/res", ROOT / "android/app/src/main/res")

# Copy iOS real launcher icon files
copy_tree(PACK / "ios/Runner/Assets.xcassets/AppIcon.appiconset", ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset")

# Copy optional reusable logo widget
copy_tree(PACK / "lib", ROOT / "lib")

pubspec = ROOT / "pubspec.yaml"
text = pubspec.read_text(encoding="utf-8")

# Ensure assets/images/ is registered under flutter:
if "assets/images/" not in text:
    if re.search(r"(?m)^flutter:\s*$", text):
        if "uses-material-design:" in text:
            text = re.sub(
                r"(?m)^(\s*uses-material-design:\s*true\s*)$",
                r"\1\n  assets:\n    - assets/images/",
                text,
                count=1,
            )
        else:
            text = re.sub(
                r"(?m)^flutter:\s*$",
                "flutter:\n  uses-material-design: true\n  assets:\n    - assets/images/",
                text,
                count=1,
            )
    else:
        text += "\nflutter:\n  uses-material-design: true\n  assets:\n    - assets/images/\n"

# Add flutter_launcher_icons if missing
if "flutter_launcher_icons:" not in text:
    if "dev_dependencies:" not in text:
        text += "\ndev_dependencies:\n  flutter_launcher_icons: ^0.14.3\n"
    elif "flutter_launcher_icons:" not in text.split("flutter:")[0]:
        if "flutter_launcher_icons: ^" not in text:
            text = re.sub(r"(?m)^dev_dependencies:\s*$", "dev_dependencies:\n  flutter_launcher_icons: ^0.14.3", text, count=1)
    text += """

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/jasmin_logo_icon_opaque.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/images/jasmin_logo_icon_opaque.png"
  remove_alpha_ios: true
"""

pubspec.write_text(text, encoding="utf-8")

print("DONE: JASMIN logo files installed.")
print("Next commands:")
print("  flutter pub get")
print("  dart run flutter_launcher_icons")
print("  flutter clean")
print("  flutter pub get")
print("  flutter run")
