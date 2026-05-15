extends CharacterBody2D

# ===== 调试开关 =====
const DEBUG = false
func _debug_print(msg):
	if DEBUG: print(msg)

# 属性设置
@export var speed = 80.0
@export var health: int = 1
@export var attack_damage = 1

@onready var sprite = $AnimatedSprite2D
@onready var attack_area = $attackarea
@onready var player = get_tree().get_first_node_in_group("player")

var is_attacking = false
var direction = 1
var is_dead = false

func _ready():
	add_to_group("enemy")

func _physics_process(delta):
	if is_dead: return  # 修复：死亡后不再移动

	if is_attacking:
		return

	if player:
		var diff = player.global_position.x - global_position.x
		direction = sign(diff)

		if direction != 0:
			sprite.flip_h = direction < 0
			attack_area.scale.x = direction

		if abs(diff) > 50:
			velocity.x = direction * speed
			sprite.play("run")
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			start_attack()

	move_and_slide()

func start_attack():
	is_attacking = true
	velocity.x = 0
	sprite.play("attack")

	await get_tree().create_timer(0.6).timeout
	check_damage()

	await sprite.animation_finished
	is_attacking = false

func check_damage():
	var targets = attack_area.get_overlapping_bodies()
	for target in targets:
		if target.has_method("take_damage"):
			target.take_damage(attack_damage)

func take_damage(amount: int):
	health -= amount
	_debug_print("[Boss4] 受到伤害，当前血量：" + str(health))
	if health <= 0:
		die()

func die():
	is_dead = true
	set_physics_process(false)
	sprite.play("death")
	await sprite.animation_finished
	queue_free()