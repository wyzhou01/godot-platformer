extends CharacterBody2D

# 属性设置
@export var speed = 80.0
@export var health = 1
@export var attack_damage = 1

# 状态引用
@onready var sprite = $AnimatedSprite2D
@onready var attack_area = $attackarea
@onready var player = get_tree().get_first_node_in_group("player") # 确保你的玩家在player组

var is_attacking = false
var direction = 1

func _ready():
	add_to_group("enemy")

func _physics_process(delta):
	if is_attacking:
		return

	# 1. 简单的追踪逻辑
	if player:
		var diff = player.global_position.x - global_position.x
		direction = sign(diff)
		
		# 翻转Sprite和攻击区域
		if direction != 0:
			sprite.flip_h = direction < 0
			attack_area.scale.x = direction

		# 距离判定
		if abs(diff) > 50:
			velocity.x = direction * speed
			sprite.play("run") # 假设你有run动画
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			start_attack()
	
	move_and_slide()

# 2. 攻击逻辑
func start_attack():
	is_attacking = true
	velocity.x = 0
	sprite.play("attack") # 对应你调了半天的那个攻击帧
	
	# 这里可以根据动画帧触发伤害，或者简单延时
	await get_tree().create_timer(0.6).timeout 
	check_damage()
	
	# 攻击冷却/结束
	await sprite.animation_finished
	is_attacking = false

# 3. 伤害判定
func check_damage():
	var targets = attack_area.get_overlapping_bodies()
	for target in targets:
		if target.has_method("take_damage"):
			target.take_damage(attack_damage)

# 4. 受伤逻辑
func take_damage(amount):
	health -= amount
	# 可以在这里加个闪烁Shader或者受伤动画
	if health <= 0:
		die()

func die():
	set_physics_process(false)
	sprite.play("death")
	await sprite.animation_finished
	queue_free()
