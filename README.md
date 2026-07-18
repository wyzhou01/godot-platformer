# 🗡️ Godot 2D Platformer — Archer Combat

> A pixel-art 2D platformer with boss battles, archer combat, and 7 hand-crafted levels, built with **Godot 4.6** + **Jolt Physics**.

**仓库**: https://github.com/wyzhou01/godot-platformer

---

## 🎮 操作

| 按键 | 动作 |
|------|------|
| `A` / `D` | 左右移动 |
| `Space` | 跳跃 |
| `鼠标左键` | 攻击（近战，~80px 范围） |
| `X` | 闪避（1.2s 无敌帧） |

---

## ⚔️ 战斗系统

- **主角（骑士）**: 即死模式（一击必杀）
  - 移动速度: 200 px/s
  - 跳跃力度: -450
  - 攻击伤害: 3
  - 闪避速度: 480 px/s，持续 0.25s
  - 无敌帧: 1.2s
- **弓箭手**: 9 HP，1秒1箭，箭速度 600 px/s，射程 1800 px
- **闪避**: X键，0.25s 闪避 + 1.2s 无敌帧
- **死亡**: 1秒后从最近存档点复活（清除场上所有箭矢）
- **Boss**: 6 个 boss 各自有独立 AI（最终boss、追逐战boss 等）

---

## 🗺️ 关卡

游戏共 7 关 + 6 个 boss：

| 关卡 | 场景文件 | 说明 |
|------|---------|------|
| Level 1 | `node_2d.tscn` | 起始关，3个弓箭手 |
| Level 2 | `level3.tscn` | 第二关 |
| Level 3 | `level_2.tscn` | 第三关 |
| Level 4 | `level_3.tscn` | 第四关 + 追逐战boss |
| Level 5 | `level4.tscn` | 第五关 |
| Level 6 | `level_5.tscn` | 第六关 |
| Level 7 | `level.6.tscn` | 第七关（含火陷阱） |
| Bonus | `level_6_burn.tscn`, `level_7.tscn` | 附加关卡 |

---

## 🛠️ 本地运行

```bash
# 1. Clone 仓库
git clone https://github.com/wyzhou01/godot-platformer.git
cd godot-platformer

# 2. 用 Godot 4.6 打开项目
#    Godot Engine → Import → 选择 project.godot

# 3. 点击 ▶️ Run（运行）
```

**要求**:
- Godot 4.6+ (Forward+ 渲染)
- Jolt Physics（已启用，在 `project.godot` 中配置）
- macOS / Windows / Linux

---

## 📁 项目结构

```
├── player.gd / .tscn             # 主角：移动/攻击/闪避/死亡
├── scene_manager.gd              # 场景管理 autoload：淡入淡出 + 存档点
├── character_body_2d.gd          # 通用敌人 AI 基类（弓箭手用）
├── arrow.gd / .tscn              # 箭矢：飞行 + 碰撞检测
├── trap.gd                       # 陷阱（火陷阱）
├── fire_1.gd / fire_2.gd / fire_3.gd # 火球特效脚本
├── light.gd                      # 灯光控制
├── boss1-6.gd / .tscn            # 6 个 boss 各自的 AI
├── final_boss.gd / .tscn         # 最终boss（多阶段攻击）
├── chase_boss.gd                 # 追逐战boss（速度比玩家略慢）
├── archer.tscn / knight_unit.tscn # 敌人单位场景
├── water.tscn / fire_red.tscn / cutscene.tscn # 道具/特效
├── level_*.tscn                  # 7+ 关卡
├── ui/
│   ├── main_menu.tscn            # 主菜单
│   └── game_over.tscn            # 游戏结束
├── assets/                       # 像素美术素材（角色、敌人、特效、TileMap）
└── project.godot                 # Godot 项目配置
```

---

## 🏗️ 架构

| 组件 | 实现 | 说明 |
|------|------|------|
| 物理 | Jolt Physics 3D | 已配置 |
| 渲染 | Forward+ | Godot 4.6 默认 |
| 场景管理 | `SceneManager` autoload | 淡入淡出 + 关卡链 + 存档点 |
| 输入 | Godot Input Map | WASD + Space + 鼠标 + X |
| 状态管理 | bool 标志位（`is_attacking / is_dodging` 等） | ⚠️ 计划重构为 XSM 状态机 |
| Boss AI | if/else + 标志位 | ⚠️ 计划重构为 Beehave 行为树 |
| UI 框架 | 直接画在场景树 | ⚠️ 计划引入 Maaack 模板 |
| 存档 | 内存（autoload var） | ⚠️ 计划改为 Resource 持久化 |
| 测试 | 无 | ⚠️ 计划引入 gdUnit4 |

> ⚠️ 标注「计划」的项目见 [REFACTOR_PLAN.md](./REFACTOR_PLAN.md)（如存在）

---

## 🤝 协作

```bash
# 各改各的，本地测试
git add .
git commit -m "描述改动"
git push
```

**Commit message 建议（中文）**:
- `feat: 新增 X 功能`
- `fix: 修复 Y bug`
- `refactor: 重构 Z 模块`

---

## 📌 注意事项

- ✅ `.godot/` 和 `.DS_Store` 已加入 `.gitignore`
- ✅ `*.png.import` 文件**应**提交（Godot 自动生成的资源索引）
- ✅ 命名规范: ASCII 英文 + 下划线（不再使用中文文件名）
- ❌ 不要提交: `.env`、`.idea/`、`*.tmp`

---

## 📜 版本

- **当前版本**: v0.1+ (Stage 0 完成)
- **Godot**: 4.6
- **引擎特性**: Forward+, Jolt Physics
- **开发**: 个人项目（阿迈）
- **AI 协作**: NB（DeepSeek）代码审查 / 嘟嘟（MiniMax-M3）架构设计
