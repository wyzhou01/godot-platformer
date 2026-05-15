extends CharacterBody2D

# --- 核心属性 ---
@export var speed = 120.0
@export var parry_chance = 0.70  # 传说中的 70% 格挡率
var health = 1                  # 1血血神，全靠身法

# --- 状态机 ---
enum State { IDLE, CHASE, ATTACK_PRE, ATTACK_ULTI, DYING }
var current_state = State.IDLE

# --- 节点引用 ---
@onready var sprite = $AnimatedSprite2D
@onready var player = get_tree().get_first_node_in_group("player") 

func _ready():
	add_to_group("enemy")

func _physics_process(_delta):
	match current_state:
		State.IDLE:
			_handle_idle()
		State.CHASE:
			_handle_chase()
		State.ATTACK_PRE, State.ATTACK_ULTI, State.DYING:
			velocity = Vector2.ZERO # 释放大招或垂死时原地站稳

	move_and_slide()

# --- 状态逻辑 ---
func _handle_idle():
	sprite.play("idle")
	if player and global_position.distance_to(player.global_position) < 400:
		current_state = State.CHASE

func _handle_chase():
	if not player: return
	sprite.play("walk")
	
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * speed
	sprite.flip_h = dir.x < 0
	
	# 距离够近就开大
	if global_position.distance_to(player.global_position) < 100:
		start_ultimate_attack()

# --- 大招逻辑：你要的动画名称在这里 ---
func start_ultimate_attack():
	current_state = State.ATTACK_PRE
	
	# 1. 释放大招前的预警动画
	# 你可以在 SpriteFrames 里新建一个叫 "attack1_pre" 的动画
	# 或者直接用你现在的 "attack1" 前几帧
	sprite.play("attack1") 
	print("警告：最终 Boss 正在蓄力红黑旋涡...")

	# 这里建议配合 AnimationPlayer 或者 Timer
	# 模拟那种“眼前一黑”的震荡感后，触发真正的伤害
	await get_tree().create_timer(1.0).timeout 
	execute_ultimate_maelstrom()

func execute_ultimate_maelstrom():
	current_state = State.ATTACK_ULTI
	# 播放大招持续动画（对应你截图里的 attack1）
	# 触发全屏弹幕、寄生虫效果、彩京式直线激光
	print("释放：红黑旋涡（Attack1）激活！")
	
	await get_tree().create_timer(2.0).timeout
	current_state = State.CHASE

# --- 核心防御逻辑：70% 格挡 ---
func take_damage(amount):
	if current_state == State.DYING: return

	# 判定格挡
	if randf() < parry_chance:
		_trigger_parry_effect()
	else:
		health -= amount
		if health <= 0:
			_trigger_dying_phase()

func _trigger_parry_effect():
	print("格挡成功！Boss 触发了 70% 概率的绝对防御！")
	# 播放叮的一声特效，或者微微闪白
	# 甚至可以反手给玩家一个“脑震荡”黑屏

func _trigger_dying_phase():
	current_state = State.DYING
	sprite.play("die")
	print("Boss 进入垂死挣扎，开启 5 分钟劝死嘴炮模式...")
	await sprite.animation_finished
	if has_node("/root/SceneManager"):
		SceneManager.goto_next_level()
	queue_free()
