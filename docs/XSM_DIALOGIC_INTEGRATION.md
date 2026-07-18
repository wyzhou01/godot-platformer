# XSM 状态机 + Dialogic 对话系统 集成指南

> 版本: 1.0 | 日期: 2026-07-18 | 适用: godot-platformer
> XSM 版本: 2.0.4 | Dialogic 版本: 2.0-Alpha-20 (Godot 4.4+)

---

## 为什么用 XSM 状态机？

当前 `player.gd` 用 4 个 bool 标志位（`is_attacking / is_dodging / is_invincible / is_dead`）
+ if/else 散在 `_physics_process` 里。状态切换容易出错（例如 dodge 期间受击会怎样？）。

**XSM** 是 StateCharts 实现，把状态变成场景树里的节点，可视化、不会打架。

> 提示: `final_boss.gd` 已经用 enum state machine (`State.IDLE / CHASE / ATTACK_PRE / ...`),
> 这是好实践，但 XSM 更强大（支持 substates / parallel / history）。

---

## XSM 安装状态（Stage 3 已完成）

- ✅ `addons/xsm/` 已复制 (144K)
- ✅ `project.godot` 已启用 `res://addons/xsm/plugin.cfg`

启动 Godot 后，Add Node 搜索框里能看到：
- `State` (基础状态)
- `StateAnimation` (绑 AnimatedSprite2D)
- `StateLoop` (循环状态)
- `StateRegions` (并行/区域)
- `StateRand` (随机状态)

---

## Player 状态机重构示例（参考）

### 重构前 player.gd（bool 标志位）
```gdscript
var is_attacking = false
var is_dodging = false
var is_invincible = false
var is_dead = false

func _physics_process(delta):
    if is_dodging:
        velocity.x = (1 if not sprite.flip_h else -1) * DODGE_SPEED
        move_and_slide()
        return
    if is_attacking:
        velocity.x = move_toward(velocity.x, 0, ATTACK_FRICTION * delta)
    # ... 一堆 if/else
```

### 重构后（XSM 节点式）

**Step 1**: 创建 `scripts/states/idle_state.gd`
```gdscript
extends State

func _on_enter():
    actor.play_animation("idle")

func _on_update(_delta):
    var direction = Input.get_axis("left", "right")
    if direction != 0:
        state_change("Run")
    if Input.is_action_just_pressed("jump") and actor.is_on_floor():
        state_change("Jump")
    if Input.is_action_just_pressed("attack"):
        state_change("Attack")
```

**Step 2**: 创建其他状态文件
- `scripts/states/run_state.gd`
- `scripts/states/jump_state.gd`
- `scripts/states/attack_state.gd` (返回 idle when animation_finished)
- `scripts/states/dodge_state.gd`
- `scripts/states/die_state.gd`

**Step 3**: 在 player.tscn 场景树里
```
Player (CharacterBody2D, 挂 player.gd)
├── AnimatedSprite2D
├── CollisionShape2D
└── States
    ├── State: Idle (脚本: idle_state.gd)
    ├── State: Run (脚本: run_state.gd)
    ├── State: Jump (脚本: jump_state.gd)
    ├── State: Attack (脚本: attack_state.gd)
    ├── State: Dodge (脚本: dodge_state.gd)
    └── State: Die (脚本: die_state.gd)
```

**Step 4**: 修改 player.gd 为最简单的 wrapper
```gdscript
extends CharacterBody2D

var current_state: Node = null

func _ready():
    current_state = $States/Idle  # 默认状态
    current_state._on_enter()

func state_change(new_state: String):
    if current_state:
        current_state._on_exit()
    current_state = $States.get_node(new_state)
    current_state._on_enter()
```

---

## 推荐的改造顺序

1. **跑游戏确认现有 player 仍正常工作** ✅ (XSM 装好后不会影响)
2. **在 player.tscn 添加一个 State 节点，先做最简单的 IdleState**
3. **修改 player.gd 的 `_physics_process`，把 idle 时的逻辑移到 IdleState._on_update()**
4. **测试 — 跑游戏，玩家应该和之前一样站在那不动**
5. **逐步加 RunState / JumpState**
6. **最后替换 AttackState / DodgeState / DieState**

---

## Dialogic 安装状态（Stage 3 已完成）

- ✅ `addons/dialogic/` 已复制 (10M)
- ✅ `project.godot` 已启用 `res://addons/dialogic/plugin.cfg`
- ✅ Dialogic autoload "Dialogic" 已自动注册

启动 Godot 后：
- 主菜单栏出现 "Dialogic" 菜单
- 底部出现 Dialogic 编辑器面板
- Add Node 搜索框里能看到 Dialogic 相关节点

---

## Dialogic 对话系统使用

### 创建第一个对话

1. **FileSystem 面板** → 右键 `res://dialogs/` → New → Dialogic → Timeline
2. **命名**: `level1_intro.dlg`
3. **Dialogic 编辑器** 添加事件:
   - Text → "Welcome to the dungeon, brave knight."
   - Character → "Knight" (选择/创建角色)
   - Text → "Defeat the archer and proceed."
   - End

### 在场景中触发对话

在 `node_2d.tscn` 起点加触发器：
```gdscript
extends Area2D

func _ready():
    body_entered.connect(_on_body_entered)

func _on_body_entered(body):
    if body.is_in_group("player"):
        Dialogic.start("res://dialogs/level1_intro.dlg")
        set_deferred("monitoring", false)  # 防止重复触发
```

### 在 Boss 战前加嘲讽

在 `final_boss.tscn` boss 节点前加触发器：
```gdscript
extends Area2D

func _ready():
    body_entered.connect(_on_body_entered)

func _on_body_entered(body):
    if body.is_in_group("player"):
        Dialogic.start("res://dialogs/final_boss_taunt.dlg")
        await Dialogic.timeline_ended
        get_parent().start_boss_fight()  # 等对话结束才开始战斗
```

---

## 推荐的改造顺序

1. **跑游戏确认现有功能正常** ✅
2. **创建第一个对话文件 `level1_intro.dlg`**（手动）
3. **在 `node_2d.tscn` 起点加触发器，测试对话弹出**
4. **给最终boss 加战前嘲讽对话**
5. **给追逐战 boss 加对话**

---

## 参考资料

- XSM 文档: https://gitlab.com/atnb/xsm
- XSM 示例: https://gitlab.com/atnb/xsm/-/tree/master/examples/platformer
- Dialogic 文档: https://docs.dialogic.pro/
- Dialogic 视频教程: https://www.youtube.com/@dialogic-godot

---

## 已注册 Autoloads (项目当前)

| Autoload | 来源 | 用途 |
|----------|------|------|
| `SceneManager` | 项目自带 | 场景管理 / 存档点 / 淡入淡出 |
| `AppConfig` | Maaack 模板 | 配置文件持久化（音量/分辨率/键位） |
| `SceneLoader` | Maaack 模板 | 异步场景加载 |
| `ProjectMusicController` | Maaack 模板 | 全局音乐管理 |
| `ProjectUISoundController` | Maaack 模板 | UI 音效 |
| `Dialogic` | Dialogic 插件 | 对话系统入口 |
