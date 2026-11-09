#!/usr/bin/env python3
"""Merge overlay_captures.json and overlay_captures.json.d/*.json into one list.

Usage: merge_captures.py <build_dir> <out.json>
Records are deduplicated by (load_addr, bytes). The output holds game code bytes:
keep it local, never publish it.
"""
import glob, json, os, sys

build, out = sys.argv[1], sys.argv[2]
paths = [os.path.join(build, "overlay_captures.json")]
paths += sorted(glob.glob(os.path.join(build, "overlay_captures.json.d", "*.json")))
seen, merged = set(), []
for p in paths:
    if not os.path.exists(p):
        continue
    data = json.load(open(p))
    for rec in data if isinstance(data, list) else [data]:
        key = (rec.get("load_addr"), rec.get("bytes_b64"))
        if key not in seen:
            seen.add(key)
            merged.append(rec)
json.dump(merged, open(out, "w"))
print(f"{len(merged)} captures from {len(paths)} files")
