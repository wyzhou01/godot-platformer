# Changelog

## 2026-05-15 — NB 代码审查修复（第一轮）

> 项目：wyzhou01/godot-platformer
> 审查者：NB（Linux 服务器端代码编辑）
> 测试：Mac + Godot 4.6 运行验证

---

### 🔴 严重修复

#### 1. player.gd — 攻击判定无冷却，同一刀砍多次
**问题**：`_check_melee_hit()` 在 `is_attacking=true` 期间每帧调用，同一击中敌人无限次
**修复**：新增 `_has_hit_this_swing: bool` 标记，攻击动画开始时重置，命中后锁定，本轮结束前不再判定

#### 2. scene_manager.gd — 复活不清除场上箭矢
**问题**：`restart_from_checkpoint()` 只重置玩家位置，场上飞着的 `arrow.tscn` 实例继续存在，玩家无敌帧结束后可能再次被击中
**修复**：复活时先清除所有 `arrow` 组的节点，再重置玩家位置

#### 3. boss1.gd — 错误的节点路径
**问题**：使用 `$Sprite2D` 但实际节点是 `$AnimatedSprite2D`，运行时报空引用
**修复**：所有 boss/wizard 统一使用 `$AnimatedSprite2D`

#### 4. boss3.gd — 错误将自己加入 "player" 组
**问题**：`add_to_group("player")` 导致 Boss 被误识别为玩家
**修复**：移除该行

#### 5. fire_1.gd — 安全定时器从未连接
**问题**：`_on_timer_timeout()` 已定义但从未成为任何 Timer 的回调，火球无法自动销毁
**修复**：创建 timer 时正确连接 `timeout.connect(_on_timer_timeout)`

#### 6. character_body_2d.gd — 屏幕宽度硬编码
**问题**：`screen_width = 512.0` 依赖 Camera2D zoom=2.5，不够健壮
**修复**：动态从玩家相机获取实际屏幕宽度

---

### 🟡 中等修复

#### 7. wizard2.gd — 动画名 "move" 应为 "run"
**问题**：其他所有脚本用 "run"，这里用 "move"，动画会静默跳过
**修复**：统一为 `"run"`

#### 8. wizard3.gd — teleport_relative 中动画名不一致
**问题**：同一次行为中用了 "move"，应为 "attack"
**修复**：改为 `"attack"`

#### 9. trap.gd — 无碰撞冷却，玩家站上面每帧扣血
**问题**：`get_overlapping_bodies()` 每帧调用无冷却，9999血秒杀
**修复**：增加 `cooldown_timer: float`，冷却期间不重复触发

#### 10. 最终boss技能2.gd — 击中玩家后未立即销毁
**问题**：命中后 `speed = 0` 但火球继续存在到 lifetime 超时
**修复**：命中后立即 `queue_free()`

#### 11. 最终boss技能1.gd — 旋涡无敌帧无保护
**问题**：玩家无敌帧期间被拉进旋涡核心仍触发 `die()`
**修复**：检查玩家 `is_invincible` 状态，跳过无敌玩家

#### 12. boss4.gd — 死亡后仍追踪
**问题**：`die()` 调用后 `_physics_process` 仍在运行直到节点释放
**修复**：增加 `is_dead` 检查在 `move_and_slide` 之前

#### 13. 追逐战boss.gd — 速度250超过玩家200
**问题**：Boss 永远比玩家快，逃脱感缺失
**修复**：Boss 速度降至 180（比玩家慢一点，需要配合地形）

---

### 🟢 轻微修复

#### 14. player.gd — 注释过时
**问题**：注释说 50HP 可调，但代码已改为一触即死
**修复**：更新注释为 "一触即死，50格HP配置已弃用"

#### 15. 所有调试 print — 生产日志污染
**问题**：多处 `print()` 每帧/每2秒持续输出
**修复**：用 `const DEBUG = true` 开关统一管理，需要关闭时设 `DEBUG = false`

#### 16. health/damage 缺少 @export
**问题**：多个脚本硬编码数值，无法在 Inspector 里调整
**修复**：为 `knight.gd`、`boss1.gd`、`boss2.gd` 的 `health`、`damage_amount` 添加 `@export`

#### 17. fire_1.gd — 缺少碰撞层检查
**修复**：增加对 TileMap 和墙体碰撞的处理

#### 18. wizard1.gd — fireball_scene 无 fallback
**修复**：增加空值检查，`fireball_scene` 为 null 时跳过发射

#### 19. boss2.gd — knight_scene 无 fallback
**修复**：增加空值检查，`knight_scene` 为 null 时跳过生成

---

*如需还原某项修改，查看对应 git commit 即可。*
---

## 2026-07-18 — Stage 0: 基础设施清理

> 项目：wyzhou01/godot-platformer
> 执行：嘟嘟（MiniMax-M3）
> 测试：待阿迈手动跑游戏验证

### ✨ 重构

#### 1. ASCII 化所有中文文件名（23 个）
**问题**：23 个核心文件使用中文文件名（`最终boss.tscn`、`英军！.tscn`、`level。2.tscn` 等），导致：
- GitHub Actions、Godot 资源缓存对中文路径支持差
- 国际化协作者阅读困难
- 部分 CLI 工具转义问题

**修复**：建立完整映射表，批量改名

| 原名 | 新名 |
|------|------|
| `最终boss.gd` | `final_boss.gd` |
| `最终boss.tscn` | `final_boss.tscn` |
| `最终boss技能.tscn` | `final_boss_skill.tscn` |
| `最终boss技能1.gd` | `final_boss_skill1.gd` |
| `最终boss技能2.gd` | `final_boss_skill2.gd` |
| `最终boss技能2.tscn` | `final_boss_skill2.tscn` |
| `追逐战boss.gd` | `chase_boss.gd` |
| `第四关追逐战boss.tscn` | `level4_chase_boss.tscn` |
| `英军！.tscn` | `british_army.tscn` |
| `弓箭手.tscn` | `archer.tscn` |
| `哇特儿.tscn` | `water.tscn` |
| `发呀的红.tscn` | `fire_red.tscn` |
| `专场.tscn` | `cutscene.tscn` |
| `骑士.tscn` | `knight_unit.tscn` |
| `level。2.tscn` | `level_2.tscn` |
| `level。3.tscn` | `level_3.tscn` |
| `level。5.tscn` | `level_5.tscn` |
| `level。6 burn.tscn` | `level_6_burn.tscn` |
| `level。7.tscn` | `level_7.tscn` |

同时同步更新所有引用：
- `scene_manager.gd` 的 `level_chain` 数组
- `boss2.gd` 的 `preload("res://骑士.tscn")`
- 所有 `.tscn` 文件的 `[ext_resource type="Script" path="res://..."]` 和 `[ext_resource type="PackedScene" path="res://..."]`

Git 自动识别为 23 个 rename（相似度 97-100%），保留历史。

#### 2. 更新 .gitignore
**新增规则**:
- `.DS_Store`（macOS 残留）
- `Thumbs.db`, `desktop.ini`（Windows 残留）
- `.idea/`（JetBrains IDE）
- `*.tmp`, `*.swp`（临时文件）
- `.env`, `.env.local`（本地环境变量）

#### 3. 一次性 commit 所有 `*.png.import`
**问题**：之前 159 个 png.import 文件未追踪，每次 Godot 启动会重新生成
**修复**：一次性 `git add -A` + commit，仓库从此自包含

### 📚 文档

#### 4. 重写 README.md
- 与代码完全同步（之前的版本描述了过期的攻击范围 600px、HP 模式等）
- 加入项目结构、关卡清单、架构表
- 加入分支策略说明

#### 5. 更新 GDD.md 到 v0.3
- 与代码完全同步
- 标注待实现项目（Stage 1-5 的目标）
- 加入 ASCII 化改动记录

#### 6. 本 CHANGELOG 条目
记录 Stage 0 全部改动

### ✅ 静态验证通过

- 根目录无中文文件名
- 所有 `ext_resource` 引用指向存在的文件
- 所有 `.gd.uid` 都有对应 `.gd`
- `scene_manager.gd` 的 level_chain 引用全部有效
- Git 自动识别 23 个 rename（相似度 97-100%）

### ⚠️ 待阿迈手动验证

- [ ] Godot 打开项目，无报错
- [ ] 主菜单 → 开始游戏 → 进入 Level 1
- [ ] 7 关 + 6 boss 全部可正常进入
- [ ] 存档点复活正常
- [ ] 控制台无 NoneType 错误

---

