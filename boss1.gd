extends CharacterBody2D

# ===== 调试开关 =====
const DEBUG = false
func _debug_print(msg):
	if DEBUG: print(msg)

# --- 属性变量 ---
@export var speed: float = 120.0
@export var death_count: int = 0
@export var block_rate: float = 0.55
@export var health: int = 1
@export var damage_amount: float = 1.0
var is_dead: bool = false

@onready var next_level_path: String = "res://levels/Level2.tscn"
@onready var player = get_tree().get_first_node_in_group("player")
@onready var sprite = $AnimatedSprite2D

func _ready():
	add_to_group("enemy")

func _physics_process(_delta: float) -> void:
	if is_dead or player == null:
		return

	var direction = (player.global_position - global_position).normalized()

	# 核心转身代码：统一用 $AnimatedSprite2D
	if player.global_position.x < global_position.x:
		sprite.flip_h = true
	else:
		sprite.flip_h = false

	if global_position.distance_to(player.global_position) > 45:
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func take_damage(amount: int = 1):
	if is_dead: return

	if randf() < block_rate:
		_debug_print("格挡！")
	else:
		death_count += 1
		_debug_print("击中！计数：" + str(death_count) + "/11")

		if death_count >= 11:
			win_and_go()

func win_and_go():
	is_dead = true
	_debug_print("Boss 被击败，3000 年后的宿命开启...")

	await get_tree().create_timer(1.0).timeout

	if has_node("/root/SceneManager"):
		SceneManager.goto_next_level()