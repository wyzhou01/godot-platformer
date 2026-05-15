extends CharacterBody2D

# ===== 调试开关 =====
const DEBUG = false
func _debug_print(msg):
	if DEBUG: print(msg)

# --- 属性设置 ---
@export var health: int = 1
@export var speed: float = 80.0
@export var detection_range: float = 500.0
@export var fireball_scene: PackedScene

# --- 内部变量 ---
@onready var sprite = $AnimatedSprite2D

var is_chasing: bool = false
var can_attack: bool = true
var is_dead: bool = false

func _ready():
	add_to_group("enemy")

func _physics_process(_delta: float) -> void:
	if is_dead: return

	var player = get_tree().get_first_node_in_group("player")
	if not player: return

	var dist = global_position.distance_to(player.global_position)

	if dist < detection_range:
		is_chasing = true
		var dir = (player.global_position - global_position).normalized()

		sprite.flip_h = dir.x < 0

		if can_attack:
			start_attack_sequence(player)

		velocity = dir * speed
		if sprite.animation != "attack":
			sprite.play("run")
	else:
		is_chasing = false
		velocity = Vector2.ZERO
		sprite.play("idle")

	move_and_slide()

func start_attack_sequence(target):
	can_attack = false

	sprite.play("attack")

	await get_tree().create_timer(3.0).timeout

	if is_dead: return

	if fireball_scene:
		var f = fireball_scene.instantiate()
		f.global_position = global_position
		if "target" in f:
			f.target = target
		elif "target_node" in f:
			f.target_node = target
		get_parent().add_child(f)
	else:
		_debug_print("[Wizard1] fireball_scene 未设置，跳过发射")

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

	sprite.play("death")

	await sprite.animation_finished
	queue_free()