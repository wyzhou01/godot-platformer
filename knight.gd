extends CharacterBody2D

# ===== 调试开关 =====
const DEBUG = false
func _debug_print(msg):
	if DEBUG: print(msg)

# 基础属性配置
@export var speed = 180.0
@export var block_chance = 0.35
@export var attack_range = 80.0
@export var damage_amount: float = 1.0
@export var detection_range = 400.0
@export var health: int = 3

var is_dead = false

@onready var sprite = $AnimatedSprite2D
@onready var attack_area = $AttackArea

func _ready():
	add_to_group("enemy")
	sprite.play("idle")

func _physics_process(delta):
	if is_dead: return

	var player = get_tree().get_first_node_in_group("player")
	if not player: return

	var direction = global_position.direction_to(player.global_position)
	var distance = global_position.distance_to(player.global_position)

	sprite.flip_h = (player.global_position.x < global_position.x)

	if distance < detection_range and distance > attack_range:
		velocity = direction * speed
		if sprite.animation != "run":
			sprite.play("run")
	elif distance <= attack_range:
		velocity = Vector2.ZERO
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
	if attack_area:
		for body in attack_area.get_overlapping_bodies():
			if body.is_in_group("player") and body.has_method("take_damage"):
				body.take_damage(damage_amount)
	if not is_dead:
		sprite.play("idle")

func take_damage(amount: int):
	if is_dead: return

	if randf() < block_chance:
		_trigger_block_effect()
	else:
		health -= amount
		_debug_print("受到伤害，当前血量: " + str(health))
		sprite.play("hurt")
		if health <= 0:
			_die()

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