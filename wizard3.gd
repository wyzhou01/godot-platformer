extends CharacterBody2D

# --- 属性配置 ---
@export var fireball_scene: PackedScene = preload("res://fire3.tscn")
@export var health: int = 1
var target: Node2D = null
var is_dead: bool = false
var can_action: bool = true

@onready var sprite = $AnimatedSprite2D

func _ready():
	target = get_tree().get_first_node_in_group("player")
	add_to_group("enemy") # 确保玩家能打到他

func _physics_process(_delta):
	if is_dead or not target or not can_action: return
	
	# 面向玩家
	sprite.flip_h = (target.global_position.x < global_position.x)
	# 启动循环 AI 逻辑
	start_boss_pattern()

# --- 核心 AI 流程 ---
func start_boss_pattern():
	can_action = false
	
	# 1. 玩家面前：连射 3 发
	await shoot_n_fireballs(3)
	await get_tree().create_timer(0.5).timeout
	
	# 2. 瞬移到玩家背后：射 1 发
	await teleport_relative(Vector2(150, 0)) # 偏移量，会根据玩家面向自动计算
	await shoot_n_fireballs(1)
	await get_tree().create_timer(0.8).timeout
	
	# 3. 循环冷却
	can_action = true

# --- 辅助动作函数 ---
func shoot_n_fireballs(n: int):
	sprite.play("attack")
	for i in range(n):
		var fb = fireball_scene.instantiate()
		fb.global_position = global_position
		fb.rotation = (target.global_position - global_position).angle()
		get_tree().current_scene.add_child(fb)
		await get_tree().create_timer(0.2).timeout # 连射间隔

func teleport_relative(offset: Vector2):
	# 简单的消失特效（借用 die 动画的一帧或者变透明）
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0, 0.2)
	await tween.finished
	
	# 计算玩家背后位置：如果玩家看右，我就去玩家左边
	var player_sprite = target.get_node("AnimatedSprite2D") if target.has_node("AnimatedSprite2D") else null
	var dir_sign = -1 if (player_sprite and player_sprite.flip_h) else 1
	global_position = target.global_position + Vector2(offset.x * dir_sign, offset.y)
	
	# 出现
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 1, 0.2)
	await tween.finished

# --- 死亡处理逻辑 ---
func take_damage(amount: int):
	if is_dead: return
	health -= amount
	sprite.play("hurt") # 播放受伤动画
	
	if health <= 0:
		die()

func die():
	is_dead = true
	can_action = false
	velocity = Vector2.ZERO
	
	# 关键：停止所有碰撞，防止死尸伤人
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	# 播放死亡动画
	sprite.play("die") 
	
	# 等待动画播完再消失
	await sprite.animation_finished
	queue_free()
