extends CharacterBody2D

# ===== 调试开关 =====
const DEBUG = false
func _debug_print(msg):
	if DEBUG: print(msg)

# --- 属性筐 ---
@export var speed = 180.0        # 修复：从250降至180，比玩家（200）略慢，增加逃脱感
@export var health: int = 9998
var is_dead = false

# --- 每一帧的逻辑处理 ---
func _ready():
	add_to_group("enemy")

func _physics_process(_delta):
	if is_dead: return

	var player = get_tree().get_first_node_in_group("player")

	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed

		if direction.x != 0:
			$AnimatedSprite2D.flip_h = direction.x < 0

		move_and_slide()

		handle_collisions()

func handle_collisions():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var target = collision.get_collider()

		if target.is_in_group("player"):
			if target.has_method("take_damage"):
				target.take_damage(99999)
				_debug_print("已执行秒杀程序 qwq")

		elif "box" in target.name.to_lower() or "木箱" in target.name:
			target.queue_free()
			_debug_print("障碍物已清除!")

func take_damage(amount: int):
	if is_dead: return
	health -= amount
	_debug_print("Boss剩余血量: " + str(health))

	if health <= 0:
		die()

func die():
	is_dead = true
	$CollisionShape2D.set_deferred("disabled", true)

	_debug_print("Boss4 开始消散... 王朝更迭 qwq")

	var tween = create_tween()
	tween.tween_property($AnimatedSprite2D, "modulate:a", 0.0, 1.5)
	tween.parallel().tween_property($AnimatedSprite2D, "scale", Vector2(0.5, 0.5), 1.5)

	tween.finished.connect(func():
		if has_node("/root/SceneManager"):
			SceneManager.goto_next_level()
		queue_free()
	)