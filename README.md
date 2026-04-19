# 🗡️ Godot 2D Platformer — Archer Combat

> A pixel-art 2D platformer with archer combat mechanics, built with Godot 4.6.

**仓库**: https://github.com/wyzhou01/godot-platformer

---

## 🎮 游戏操作

| 按键 | 动作 |
|------|------|
| `A` / `D` | 左右移动 |
| `Space` | 跳跃 |
| `鼠标左键` | 攻击（近战，600px 范围） |
| `X` | 闪避（无敌帧） |

---

## 🎯 战斗系统

- **主角**: 50 HP，1刀 = 50伤害（秒杀弓箭手）
- **弓箭手**: 3 HP，3秒射1箭，箭自动追踪玩家方向
- **闪避**: X键，1.2秒无敌帧
- **死亡**: 3秒后场景重启，场上箭矢清空

---

## 🛠️ 本地运行

```bash
# 1. Clone 仓库
git clone https://github.com/wyzhou01/godot-platformer.git
cd godot-platformer

# 2. 用 Godot 4.6 打开项目
#    Godot Engine -> Import -> 选择 project.godot

# 3. 点击 ▶️ Run（运行）
```

---

## 📁 项目结构

```
player.gd           # 主角：移动/攻击/闪避/受伤
character_body_2d.gd # 敌人AI：弓箭手3血/射箭逻辑
arrow.gd             # 箭矢：方向追踪/命中检测
arrow.tscn           # 箭矢场景（放大3倍可见）
assets/               # 像素美术素材
```

---

## 🤝 协作

```bash
# 各改各的，本地测试
git add .
git commit -m "描述改动"
git push

# 合并冲突时手动解决 .gd / .tscn 文件
```

---

## 📌 协作者注意

- 每次运行 Godot 会自动修改 `.godot/` 和 `*.import`
- **不要** 把这些文件提交到 git
- 已配置 `.gitignore` 自动忽略
