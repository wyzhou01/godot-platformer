extends CharacterBody2D

# ===== 调试开关 =====
const DEBUG = false
func _debug_print(msg):
	if DEBUG: print(msg)

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
	add_to_group("enemy")
	target = get_tree().get_first_node_in_group("player")

func _physics_process(_delta):
	if is_dead: return
	if not target: return

	var dist = global_position.distance_to(target.global_position)

	if dist < attack_range:
		if can_attack:
			start_attack_sequence()
		velocity = velocity.lerp(Vector2.ZERO, 0.1)
	else:
		var dir = (target.global_position - global_position).normalized()
		velocity = dir * speed
		if sprite.animation != "attack":
			sprite.play("run")  # 修复：统一用 "run"

	move_and_slide()
	sprite.flip_h = (target.global_position.x < global_position.x)

func start_attack_sequence():
	can_attack = false
	sprite.play("attack")

	await get_tree().create_timer(0.6).timeout

	if is_dead: return

	if fireball_scene:
		var base_angle = (target.global_position - global_position).angle() if target else 0.0
		var spread_range = deg_to_rad(90.0)
		for i in range(5):
			var fb = fireball_scene.instantiate()
			fb.global_position = global_position
			var offset = spread_range * (i / 4.0 - 0.5)
			fb.rotation = base_angle + offset
			get_tree().current_scene.add_child(fb)
	else:
		_debug_print("[Wizard2] fireball_scene 未设置，跳过发射")

	await get_tree().create_timer(4.0).timeout
	can_attack = true

func take_damage(amount: int):
	if is_dead: return

	health -= amount

	if health <= 0:
		die()
	else:
		sprite.play("hurt")

func die():
	is_dead = true
	velocity = Vector2.ZERO

	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

	sprite.play("die")

	await sprite.animation_finished
	queue_free()