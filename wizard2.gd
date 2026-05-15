extends CharacterBody2D

# --- 属性设置 ---
@export var health: int = 1       # 火焰法师更肉一些
@export var speed: float = 100.0
@export var attack_range: float = 400.0
@export var fireball_scene: PackedScene = preload("res://fire2.tscn")

# --- 内部变量 ---
var target: Node2D = null
var can_attack: bool = true
var is_dead: bool = false # 死亡状态锁
@onready var sprite = $AnimatedSprite2D

func _ready():
	# 自动加入敌人组，方便玩家判定攻击
	add_to_group("enemy")
	target = get_tree().get_first_node_in_group("player")

func _physics_process(_delta):
	# 逻辑锁：死了就不动、不思考
	if is_dead: return
	if not target: return
	
	var dist = global_position.distance_to(target.global_position)
	
	# 1. 行为决策
	if dist < attack_range:
		# 在攻击范围内，尝试施法并减速停下
		if can_attack: 
			start_attack_sequence()
		velocity = velocity.lerp(Vector2.ZERO, 0.1)
	else:
		# 追击玩家
		var dir = (target.global_position - global_position).normalized()
		velocity = dir * speed
		# 只有在不播攻击动画时播移动动画
		if sprite.animation != "attack":
			sprite.play("move") 
	
	move_and_slide()
	# 脸部朝向
	sprite.flip_h = (target.global_position.x < global_position.x)

# --- 施法逻辑：5火球竖排散射 ---
func start_attack_sequence():
	can_attack = false
	sprite.play("attack")
	
	# 施法前摇（0.6秒后火球成型）
	await get_tree().create_timer(0.6).timeout
	
	# 再次检查：防止在0.6秒蓄力期间被玩家砍死导致报错
	if is_dead: return
	
	if fireball_scene:
		# 发射 5 个火球，呈垂直扇形散开
		var base_angle = (target.global_position - global_position).angle() if target else 0.0
		var spread_range = deg_to_rad(90.0) # 总范围 90 度（-45 到 +45）
		for i in range(5):
			var fb = fireball_scene.instantiate()
			fb.global_position = global_position
			# 均匀分布在 -45度 到 45度 之间
			var offset = spread_range * (i / 4.0 - 0.5) # i=0 -> -0.5, i=4 -> 0.5
			fb.rotation = base_angle + offset
			get_tree().current_scene.add_child(fb)
	
	# 施法后摇/冷却（4秒）
	await get_tree().create_timer(4.0).timeout 
	can_attack = true

# --- 🩸 新增：受伤与死亡逻辑 ---
func take_damage(amount: int):
	if is_dead: return
	
	health -= amount
	
	if health <= 0:
		die()
	else:
		# 受到伤害时播一下 hurt 动画
		sprite.play("hurt")

func die():
	is_dead = true
	velocity = Vector2.ZERO
	
	# 物理屏蔽：死后不再阻挡玩家
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	# 停止当前所有动作，播放死亡动画
	sprite.play("die") 
	
	# 等待火焰法师倒地并熄灭
	await sprite.animation_finished
	queue_free()
