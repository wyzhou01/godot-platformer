extends CharacterBody2D

# --- 属性设置 ---
@export var health: int = 1
@export var speed: float = 80.0
@export var fireball_scene: PackedScene 
@export var detection_range: float = 500.0

# --- 内部变量 ---
@onready var sprite = $AnimatedSprite2D

var is_chasing: bool = false
var can_attack: bool = true
var is_dead: bool = false # 状态锁：确保死后不乱跑、不乱打

func _ready():
	add_to_group("enemy")

func _physics_process(_delta: float) -> void:
	# 如果死了，就彻底断开大脑逻辑
	if is_dead: return

	# 寻找玩家
	var player = get_tree().get_first_node_in_group("player")
	if not player: return

	var dist = global_position.distance_to(player.global_position)
	
	# 1. 视觉检测逻辑
	if dist < detection_range:
		is_chasing = true
		var dir = (player.global_position - global_position).normalized()
		
		# 面向玩家
		sprite.flip_h = dir.x < 0
		
		# 2. 攻击节奏控制
		if can_attack:
			start_attack_sequence(player)
			
		# 移动逻辑
		velocity = dir * speed
		# 只有在不播攻击动画时才播走路动画，防止动作打架
		if sprite.animation != "attack":
			sprite.play("run")
	else:
		is_chasing = false
		velocity = Vector2.ZERO
		sprite.play("idle")

	move_and_slide()

# --- 核心攻击流程 ---
func start_attack_sequence(target):
	can_attack = false
	
	# 播放攻击前摇
	sprite.play("attack") 
	
	# 实例化火球
	if fireball_scene:
		var f = fireball_scene.instantiate()
		f.global_position = global_position
		# 兼容性检查：如果火球脚本里变量名叫 target_node 记得改一下
		if "target" in f:
			f.target = target 
		elif "target_node" in f:
			f.target_node = target
		get_parent().add_child(f)
	
	# 3秒CD
	await get_tree().create_timer(3.0).timeout
	can_attack = true

# --- 🩸 新增：受伤与死亡系统 ---
func take_damage(amount: int):
	if is_dead: return # 死人不会再痛了
	
	health -= amount
	
	if health <= 0:
		die()
	else:
		# 如果还没死，可以播个受击动画（你截图里的 hurt）
		sprite.play("hurt")
		# 0.2秒后恢复之前的动作（或者不播也行，直接等下一次状态机切换）

func die():
	is_dead = true
	velocity = Vector2.ZERO # 停在原地
	
	# 核心：关闭碰撞，让玩家能直接走过去，不被尸体挡住
	# 这里的 1 是指第一层，你可以根据你的层级调节
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	# 播放死亡动画
	sprite.play("death") 
	
	# 重点：等动画播完再把巫师从世界上抹去
	await sprite.animation_finished
	queue_free()
