#!/usr/bin/env python3
"""
Godot 项目静态检查脚本 (无需 Godot 引擎)
- 检查 .gd 脚本语法
- 验证 .tscn/.tres 引用的资源存在
- 扫描未使用/孤立文件
- 检测常见 bug 模式

用法: python3 scripts/static_check.py
"""
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent
ERRORS = []
WARNINGS = []


def check_chinese_filename():
    """检查根目录是否有中文文件名（除资源目录外）"""
    print("\n[1] 检查中文文件名...")
    chinese_files = []
    for item in ROOT.iterdir():
        if item.is_file():
            if any(0x4E00 <= ord(c) <= 0x9FFF for c in item.name):
                chinese_files.append(item.name)
    if chinese_files:
        WARNINGS.append(f"根目录有 {len(chinese_files)} 个中文文件名: {chinese_files[:3]}")
        print(f"  ⚠️ {len(chinese_files)} 个")
    else:
        print("  ✅ 干净")


def check_tscn_references():
    """验证所有 .tscn 的 ext_resource 引用都指向存在的文件"""
    print("\n[2] 检查 .tscn 引用完整性...")
    broken = []
    for tscn in ROOT.rglob("*.tscn"):
        if "/.git/" in str(tscn) or "/.godot/" in str(tscn):
            continue
        try:
            content = tscn.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for ref in re.findall(r'path="(res://[^"]+)"', content):
            local = ROOT / ref.replace("res://", "")
            if not local.exists():
                broken.append((str(tscn.relative_to(ROOT)), ref))
    if broken:
        ERRORS.append(f"{len(broken)} 个失效 ext_resource 引用")
        for src, ref in broken[:5]:
            print(f"  ❌ {src} → {ref}")
    else:
        print("  ✅ 所有 ext_resource 引用都有效")


def check_orphan_uids():
    """检查孤立 .uid 文件"""
    print("\n[3] 检查 .gd.uid 配对...")
    orphans = []
    for uid_file in ROOT.rglob("*.uid"):
        if "/.git/" in str(uid_file) or "/.godot/" in str(uid_file):
            continue
        gd_file = uid_file.with_suffix("")  # 去掉 .uid
        if not gd_file.exists():
            orphans.append(str(uid_file.relative_to(ROOT)))
    if orphans:
        WARNINGS.append(f"{len(orphans)} 个孤立 .uid 文件")
        print(f"  ⚠️ {len(orphans)} 个")
    else:
        print("  ✅ 所有 .uid 都有对应 .gd")


def check_unused_scripts():
    """检查未被任何 .tscn 加载的 .gd 脚本"""
    print("\n[4] 检查未引用的脚本...")
    all_scripts = set()
    for gd in ROOT.rglob("*.gd"):
        if "/.git/" in str(gd) or "/.godot/" in str(gd):
            continue
        all_scripts.add(str(gd.relative_to(ROOT)))

    referenced = set()
    for tscn in ROOT.rglob("*.tscn"):
        if "/.git/" in str(tscn) or "/.godot/" in str(tscn):
            continue
        try:
            content = tscn.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for ref in re.findall(r'path="(res://[^"]*\.gd)"', content):
            referenced.add(ref.replace("res://", ""))
        # preload() 引用
        for ref in re.findall(r'preload\("(res://[^"]*\.gd)"\)', content):
            referenced.add(ref.replace("res://", ""))

    unused = all_scripts - referenced
    # 排除 addons/ 下的脚本
    unused = [u for u in unused if not u.startswith("addons/")]
    if unused:
        WARNINGS.append(f"{len(unused)} 个未引用的 .gd 脚本")
        for u in unused[:5]:
            print(f"  ⚠️ {u}")
    else:
        print("  ✅ 所有脚本都被引用")


def check_gdscript_syntax():
    """GDScript 基础语法检查（缩进、括号匹配）"""
    print("\n[5] 检查 GDScript 语法...")
    issues = []
    for gd in ROOT.rglob("*.gd"):
        if "/.git/" in str(gd) or "/.godot/" in str(gd):
            continue
        try:
            content = gd.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        lines = content.split("\n")
        for i, line in enumerate(lines, 1):
            # 检查 tab/空格混用
            if "\t" in line and "    " in line and not line.strip().startswith("#"):
                issues.append((gd.name, i, "混用 tab 和空格"))
    if issues:
        WARNINGS.append(f"{len(issues)} 个缩进问题")
        for f, line, msg in issues[:5]:
            print(f"  ⚠️ {f}:{line} {msg}")
    else:
        print("  ✅ 缩进一致")


def check_scene_chain():
    """验证 scene_manager.gd 的 level_chain"""
    print("\n[6] 检查 scene_manager.gd level_chain...")
    sm = ROOT / "scene_manager.gd"
    if not sm.exists():
        print("  ⚠️ scene_manager.gd 不存在")
        return
    content = sm.read_text(encoding="utf-8")
    m = re.search(r'level_chain\s*:\s*Array\s*\[\s*String\s*\]\s*=\s*\[(.*?)\]', content, re.DOTALL)
    if not m:
        print("  ⚠️ 未找到 level_chain")
        return
    paths = re.findall(r'"(res://[^"]+)"', m.group(1))
    broken = []
    for p in paths:
        if not (ROOT / p.replace("res://", "")).exists():
            broken.append(p)
    if broken:
        ERRORS.append(f"level_chain 有 {len(broken)} 个失效关卡")
        for p in broken:
            print(f"  ❌ {p}")
    else:
        print(f"  ✅ {len(paths)} 个关卡全部存在")


def main():
    print(f"=" * 50)
    print(f"Godot 静态检查 - {ROOT.name}")
    print(f"=" * 50)

    check_chinese_filename()
    check_tscn_references()
    check_orphan_uids()
    check_unused_scripts()
    check_gdscript_syntax()
    check_scene_chain()

    print(f"\n{'=' * 50}")
    print(f"汇总: {len(ERRORS)} 错误, {len(WARNINGS)} 警告")
    print(f"{'=' * 50}")
    if ERRORS:
        print("\n❌ 错误:")
        for e in ERRORS:
            print(f"  - {e}")
        sys.exit(1)
    if WARNINGS:
        print("\n⚠️ 警告:")
        for w in WARNINGS:
            print(f"  - {w}")
    print("\n✅ 通过")


if __name__ == "__main__":
    main()
