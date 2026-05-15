extends CharacterBody2D

# 基础属性配置
@export var speed = 180.0
@export var block_chance = 0.35 # 35%的几率格挡
@export var attack_range = 80.0
@export var damage_amount = 1.0
@export var detection_range = 400.0

var health = 1
var is_dead = false

@onready var sprite = $AnimatedSprite2D
@onready var attack_area = $AttackArea

func _ready():
	add_to_group("enemy")
	sprite.play("idle")

func _physics_process(delta):
	if is_dead: return

	# 获取玩家位置
	var player = get_tree().get_first_node_in_group("player")
	if not player: return

	var direction = global_position.direction_to(player.global_position)
	var distance = global_position.distance_to(player.global_position)

	# 面向玩家
	sprite.flip_h = (player.global_position.x < global_position.x)

	# 追击逻辑
	if distance < detection_range and distance > attack_range:
		velocity = direction * speed
		if sprite.animation != "run":
			sprite.play("run")
	elif distance <= attack_range:
		velocity = Vector2.ZERO
		# 攻击
		if sprite.animation != "attack":
			start_attack()
	else:
		velocity = Vector2.ZERO
		if sprite.animation != "idle" and sprite.animation != "attack":
			sprite.play("idle")

	move_and_slide()

func start_attack():
	sprite.play("attack")
	await sprite.animation_finished
	if is_dead: return
	# 攻击帧结束后检测伤害
	if attack_area:
		for body in attack_area.get_overlapping_bodies():
			if body.is_in_group("player") and body.has_method("take_damage"):
				body.take_damage(damage_amount)
	# 继续巡逻/idle
	if not is_dead:
		sprite.play("idle")

# 当被主角攻击时调用的函数
func take_damage(amount):
	if is_dead: return

	# 核心逻辑：随机格挡判定
	if randf() < block_chance:
		_trigger_block_effect()
		print("Block! 骑士防御了这次攻击 awa")
	else:
		health -= amount
		print("受到伤害，当前血量: ", health)
		sprite.play("hurt")
		if health <= 0:
			_die()

# 弹出 "Block!" 文字提示的逻辑
func _trigger_block_effect():
	var label = Label.new()
	label.text = "Block!"
	label.modulate = Color.YELLOW
	label.position = Vector2(0, -50)
	add_child(label)

	var tween = create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -30), 0.5)
	tween.parallel().tween_property(label, "modulate:a", 0, 0.5)
	tween.tween_callback(label.queue_free)

func _die():
	is_dead = true
	set_physics_process(false)
	sprite.play("die")
	await sprite.animation_finished
	queue_free()
