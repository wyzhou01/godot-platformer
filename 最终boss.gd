extends CharacterBody2D

# ===== 调试开关 =====
const DEBUG = false
func _debug_print(msg):
	if DEBUG: print(msg)

# --- 核心属性 ---
@export var speed = 120.0
@export var parry_chance = 0.70
@export var health: int = 1

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
			velocity = Vector2.ZERO

	move_and_slide()

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

	if global_position.distance_to(player.global_position) < 100:
		start_ultimate_attack()

func start_ultimate_attack():
	current_state = State.ATTACK_PRE

	sprite.play("attack1")
	_debug_print("警告：最终 Boss 正在蓄力红黑旋涡...")

	await get_tree().create_timer(1.0).timeout
	execute_ultimate_maelstrom()

func execute_ultimate_maelstrom():
	current_state = State.ATTACK_ULTI
	_debug_print("释放：红黑旋涡（Attack1）激活！")

	await get_tree().create_timer(2.0).timeout
	current_state = State.CHASE

func take_damage(amount: int = 1):
	if current_state == State.DYING: return

	if randf() < parry_chance:
		_trigger_parry_effect()
	else:
		health -= amount
		if health <= 0:
			_trigger_dying_phase()

func _trigger_parry_effect():
	_debug_print("格挡成功！Boss 触发了 70% 概率的绝对防御！")

func _trigger_dying_phase():
	current_state = State.DYING
	sprite.play("die")
	_debug_print("Boss 进入垂死挣扎，开启 5 分钟劝死嘴炮模式...")
	await sprite.animation_finished
	if has_node("/root/SceneManager"):
		SceneManager.goto_next_level()
	queue_free()