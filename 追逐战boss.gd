extends CharacterBody2D

# --- 属性筐 ---
@export var speed = 250        # 追逐速度(比玩家稍微慢一点点最刺激)
@export var health = 9998      # 霸主级血量
var is_dead = false            # 死亡标记位

# --- 每一帧的逻辑处理 ---
func _ready():
	add_to_group("enemy")

func _physics_process(_delta):
	if is_dead: return         # 死了就别动了

	# 1. 寻找你的"骑士"
	var player = get_tree().get_first_node_in_group("player")

	if player:
		# 2. 磁吸追踪:计算方向并移动
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed

		# 3. 自动翻转图片(看向骑士)
		if direction.x != 0:
			$AnimatedSprite2D.flip_h = direction.x < 0

		move_and_slide()

		# 4. 碰撞检测:暴力清场模式
		handle_collisions()

# --- 碰撞逻辑筐:碎箱与秒杀 ---
func handle_collisions():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var target = collision.get_collider()

		# A. 秒杀玩家
		if target.is_in_group("player"):
			if target.has_method("take_damage"):
				target.take_damage(99999) # 触发玩家死亡
				print("已执行秒杀程序 qwq")

		# B. 撞碎一切木箱(只要名字里带 box 或 木箱)
		elif "box" in target.name.to_lower() or "木箱" in target.name:
			# 可以在这里加个简单的爆炸粒子特效
			target.queue_free()
			print("障碍物已清除!")

# --- 死亡逻辑筐:变淡消散 ---
func take_damage(amount):
	if is_dead: return
	health -= amount
	print("Boss剩余血量: ", health)

	if health <= 0:
		die()

func die():
	is_dead = true
	# 禁用所有碰撞,防止死的时候还能撞碎箱子
	$CollisionShape2D.set_deferred("disabled", true)

	print("Boss4 开始消散... 王朝更迭 qwq")

	# 使用 Tween 实现你要求的"变淡消失"
	var tween = create_tween()
	# 1.5秒内透明度归零,同时稍微缩小一点点
	tween.tween_property($AnimatedSprite2D, "modulate:a", 0.0, 1.5)
	tween.parallel().tween_property($AnimatedSprite2D, "scale", Vector2(0.5, 0.5), 1.5)

	# 动画播完,彻底从帝国版图中抹去
	tween.finished.connect(func():
		if has_node("/root/SceneManager"):
			SceneManager.goto_next_level()
		queue_free()
	)
