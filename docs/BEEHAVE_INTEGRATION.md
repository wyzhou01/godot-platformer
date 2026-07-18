# Beehave 行为树集成指南

> 版本: 1.0 | 日期: 2026-07-18 | 适用: godot-platformer
> 插件版本: Beehave v2.9.3-dev

---

## 为什么用行为树？

当前 boss AI 用 `if/else + bool 标志位` 实现（见 `boss1.gd / chase_boss.gd / final_boss.gd`），
加新行为时需要修改核心代码，且难以调试。

**行为树** 把 AI 拆成可视化节点（Selector/Sequence/Action/Condition），
新增技能 = 加一个节点，不需要改现有代码。

---

## 安装状态（Stage 2 已完成）

- ✅ `addons/beehave/` 已复制
- ✅ `script_templates/BeehaveNode/` 已复制（Godot 创建脚本时可看到 BeehaveNode 模板）
- ✅ `project.godot` 已启用 `res://addons/beehave/plugin.cfg`

启动 Godot 后，在 Add Node 搜索框里能看到：
- `BeehaveTree` (根节点)
- `SequenceComposite`, `SelectorComposite`, `SelectorReactive`, `SequenceReactive` (composites)
- `Inverter`, `Cooldown`, `Delayer`, `TimeLimiter`, `Repeater` (decorators)
- `ActionLeaf`, `ConditionLeaf`, `BlackboardSet`, `BlackboardCompare` (leaves)

---

## 概念

### 黑板 (Blackboard)
节点间共享数据字典。例如 boss 的 "target" / "health" / "phase" 都可以存黑板。

```gdscript
# 设置
blackboard.set_value("target", player)
blackboard.set_value("phase", "rage", "boss1")

# 读取
var target = blackboard.get_value("target")
```

### Composite 节点
- **Sequence**: 顺序执行子节点，**全部成功** 才成功（任一失败则退出）
- **Selector**: 顺序执行子节点，**任一成功** 就成功（全部失败才失败）
- **Reactive 变体**: 每帧重新评估已执行过的子节点
- **Random 变体**: 随机执行顺序

### Decorator 节点
- **Inverter**: 反转 SUCCESS ↔ FAILURE
- **Cooldown**: 强制 N 秒冷却（防止技能连发）
- **TimeLimiter**: 限时执行
- **Repeater**: 重复执行 N 次

### Leaf 节点（自定义你的逻辑）
- **ActionLeaf**: 写你的"做什么"（移动/攻击/释放技能）
- **ConditionLeaf**: 写你的"判断"（玩家在范围内？血量低于 50%？）

---

## Boss 重构示例（参考）

### 重构前的 boss1.gd（if/else 风格）
```gdscript
func _physics_process(_delta):
    if is_dead: return
    var dir = (player.global_position - global_position).normalized()
    velocity = dir * speed
    sprite.flip_h = dir.x < 0
    move_and_slide()
```

### 重构后（行为树风格）

**Step 1**: 创建 `scripts/beehave/actions/chase_action.gd`
```gdscript
@tool
class_name ChaseAction extends ActionLeaf

@export var speed: float = 120.0

func tick(actor: Node, blackboard: Blackboard) -> int:
    var target = blackboard.get_value("target")
    if not target or not is_instance_valid(target):
        return FAILURE
    
    var dir = (target.global_position - actor.global_position).normalized()
    actor.velocity = dir * speed
    actor.get_node("AnimatedSprite2D").flip_h = dir.x < 0
    actor.move_and_slide()
    return SUCCESS
```

**Step 2**: 创建 `scripts/beehave/conditions/has_target.gd`
```gdscript
@tool
class_name HasTargetCondition extends ConditionLeaf

func tick(actor: Node, blackboard: Blackboard) -> int:
    var target = blackboard.get_value("target")
    return SUCCESS if target and is_instance_valid(target) else FAILURE
```

**Step 3**: 创建 `scripts/beehave/actions/set_target_action.gd`（在 ready 时设置）
```gdscript
@tool
class_name SetTargetAction extends ActionLeaf

func tick(actor: Node, blackboard: Blackboard) -> int:
    var player = actor.get_tree().get_first_node_in_group("player")
    if player:
        blackboard.set_value("target", player)
        return SUCCESS
    return FAILURE
```

**Step 4**: 在 boss1.tscn 场景树里：
```
Boss1 (CharacterBody2D, 挂 boss1.gd)
├── AnimatedSprite2D
├── CollisionShape2D
└── BeehaveTree
    └── SelectorComposite
        ├── SequenceComposite
        │   ├── SetTargetAction
        │   └── ChaseAction
        └── IdleAction (可选)
```

**Step 5**: 修改 boss1.gd，让它在 _ready 时把 player 写到黑板
```gdscript
func _ready():
    add_to_group("enemy")
    var player = get_tree().get_first_node_in_group("player")
    if player:
        $BeehaveTree.blackboard.set_value("target", player)
```

---

## 推荐的改造顺序

1. **先装好插件（Stage 2 已做）** ✅
2. **跑游戏确认现有 boss 仍正常工作**
3. **打开一个简单 boss 的 .tscn（推荐 chase_boss）**
4. **添加 BeehaveTree 节点，挂一个最简单的 Sequence**
5. **测试 — 把 chase_boss.gd 里的 _physics_process 暂时注释掉，看行为树是否接管**
6. **逐步把其他 boss 重构为行为树**

---

## 调试

启动游戏后，编辑器右下角会出现 **🐝 Beehave Debugger** 面板。
打开后能看到每个 boss 当前在哪个 Action 上执行，性能如何。

---

## 参考资料

- Beehave 官方文档: https://bitbra.in/beehave
- Beehave GitHub: https://github.com/bitbrain/beehave
- 行为树入门: https://www.gamasutra.com/blogs/ChrisSimpson/20140717/221339/Behavior_trees_for_AI_How_they_work.php

