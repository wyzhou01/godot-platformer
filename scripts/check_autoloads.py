#!/usr/bin/env python3
"""验证 project.godot 中的所有 autoload 路径都存在"""
import re, os, sys

content = open("project.godot").read()
# find all autoload entries between [autoload] and next section
m = re.search(r'\[autoload\](.*?)\n\[', content, re.DOTALL)
if not m:
    print("❌ No [autoload] section found")
    sys.exit(1)

block = m.group(1)
# Parse each line: Name="*res://path" or Name="res://path"
entries = re.findall(r'(\w+)="\*?(res://[^"]+)"', block)

if not entries:
    print("❌ No autoload entries parsed")
    sys.exit(1)

print(f"找到 {len(entries)} 个 autoload:")
all_ok = True
for name, path in entries:
    # Strip res:// prefix for local filesystem check
    local = path.replace("res://", "")
    if os.path.exists(local):
        print(f"  ✓ {name}: {local}")
    else:
        print(f"  ❌ {name}: {local} 不存在!")
        all_ok = False

# Also check editor_plugins
print()
m = re.search(r'\[editor_plugins\](.*?)\n\[', content, re.DOTALL)
if m:
    plugins = re.findall(r'"(res://[^"]+plugin\.cfg)"', m.group(1))
    print(f"找到 {len(plugins)} 个 enabled plugin:")
    for p in plugins:
        local = p.replace("res://", "")
        if os.path.exists(local):
            print(f"  ✓ {local}")
        else:
            print(f"  ❌ {local} 不存在!")
            all_ok = False

sys.exit(0 if all_ok else 1)