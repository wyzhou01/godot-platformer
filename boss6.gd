extends CharacterBody2D

# 这里的属性你可以根据 2.0 引擎的强度自己调节
@export var speed = 150.0
@export var health = 1
@export var attack_damage = 1
@onready var sprite = $AnimatedSprite2D
@onready var attack_area = $attackarea

var player = null
var is_dead = false

func _ready():
	add_to_group("enemy")
	# 初始播放 idle 动画，也就是你截图里选中的那个
	sprite.play("idle")
	# 假设你的玩家节点叫 "Knight"，或者你可以通过 group 获取
	player = get_tree().get_first_node_in_group("player")

func _physics_process(_delta):
	if is_dead:
		return
		
	if player:
		# 简单的追踪逻辑：朝着玩家的方向移动
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * speed
		
		# 处理镜像翻转，让 Boss 永远盯着玩家看
		if direction.x > 0:
			sprite.flip_h = false
		else:
			sprite.flip_h = true
			
		move_and_slide()
		
		# 距离判断：如果离玩家近，就触发 attack 动画
		if global_position.distance_to(player.global_position) < 50:
			attack()

func attack():
	if sprite.animation != "attack":
		sprite.play("attack")
		print("【系统告警】Boss6 正在发动攻击，执行大清洗逻辑！qwq")

func take_damage(amount):
	health -= amount
	if health <= 0:
		die()

func die():
	is_dead = true
	sprite.play("die")
	print("【帝国记录】Boss6 已被击败，正在进入结算画面...")
	await sprite.animation_finished
	if has_node("/root/SceneManager"):
		SceneManager.goto_next_level()
	queue_free()
