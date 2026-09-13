#!/usr/bin/env python3
"""
Generate iOS AppIcon sizes from a source image using macOS native `sips` tool.
"""

import json
import os
import subprocess
import sys

def generate_icons(source_path="Resources/AppIcon-source.png", iconset_dir="Resources/Assets.xcassets/AppIcon.appiconset"):
    if not os.path.exists(source_path):
        print(f"Error: Source image not found at {source_path}", file=sys.stderr)
        sys.exit(1)

    contents_json_path = os.path.join(iconset_dir, "Contents.json")
    if not os.path.exists(contents_json_path):
        print(f"Error: Contents.json not found at {contents_json_path}", file=sys.stderr)
        sys.exit(1)

    with open(contents_json_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    images = data.get("images", [])
    print(f"Processing {len(images)} icon specifications from {contents_json_path}...")

    for item in images:
        filename = item.get("filename")
        if not filename:
            continue

        size_str = item.get("size", "0x0")
        scale_str = item.get("scale", "1x")

        try:
            w_str, h_str = size_str.split("x")
            scale = float(scale_str.rstrip("x"))
            target_w = int(round(float(w_str) * scale))
            target_h = int(round(float(h_str) * scale))
        except Exception as e:
            print(f"Failed to parse size/scale for {filename}: {e}", file=sys.stderr)
            continue

        target_path = os.path.join(iconset_dir, filename)
        cmd = [
            "sips",
            "-s", "format", "png",
            "-z", str(target_h), str(target_w),
            source_path,
            "--out", target_path
        ]
        res = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
        if res.returncode != 0:
            print(f"Failed to generate {filename}: {res.stderr.decode()}", file=sys.stderr)
            sys.exit(1)
        print(f"  Generated {filename} ({target_w}x{target_h})")

    print("AppIcon generation complete.")

if __name__ == "__main__":
    src = sys.argv[1] if len(sys.argv) > 1 else "Resources/AppIcon-source.png"
    dst = sys.argv[2] if len(sys.argv) > 2 else "Resources/Assets.xcassets/AppIcon.appiconset"
    generate_icons(src, dst)
