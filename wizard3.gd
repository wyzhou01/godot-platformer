extends CharacterBody2D

# ===== 调试开关 =====
const DEBUG = false
func _debug_print(msg):
	if DEBUG: print(msg)

# --- 属性配置 ---
@export var fireball_scene: PackedScene = preload("res://fire3.tscn")
@export var health: int = 1
var target: Node2D = null
var is_dead: bool = false
var can_action: bool = true

@onready var sprite = $AnimatedSprite2D

func _ready():
	target = get_tree().get_first_node_in_group("player")
	add_to_group("enemy")

func _physics_process(_delta):
	if is_dead or not target or not can_action: return

	sprite.flip_h = (target.global_position.x < global_position.x)
	start_boss_pattern()

func start_boss_pattern():
	can_action = false

	await shoot_n_fireballs(3)
	await get_tree().create_timer(0.5).timeout

	await teleport_relative(Vector2(150, 0))
	await shoot_n_fireballs(1)
	await get_tree().create_timer(0.8).timeout

	can_action = true

func shoot_n_fireballs(n: int):
	sprite.play("attack")
	for i in range(n):
		if fireball_scene:
			var fb = fireball_scene.instantiate()
			fb.global_position = global_position
			fb.rotation = (target.global_position - global_position).angle()
			get_tree().current_scene.add_child(fb)
		else:
			_debug_print("[Wizard3] fireball_scene 未设置，跳过发射")
		await get_tree().create_timer(0.2).timeout

func teleport_relative(offset: Vector2):
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0, 0.2)
	await tween.finished

	var player_sprite = target.get_node("AnimatedSprite2D") if target.has_node("AnimatedSprite2D") else null
	var dir_sign = -1 if (player_sprite and player_sprite.flip_h) else 1
	global_position = target.global_position + Vector2(offset.x * dir_sign, offset.y)

	sprite.play("attack")  # 修复：统一用 "attack" 而非 "move"
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 1, 0.2)
	await tween.finished

func take_damage(amount: int):
	if is_dead: return
	health -= amount
	sprite.play("hurt")

	if health <= 0:
		die()

func die():
	is_dead = true
	can_action = false
	velocity = Vector2.ZERO

	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

	sprite.play("die")

	await sprite.animation_finished
	queue_free()