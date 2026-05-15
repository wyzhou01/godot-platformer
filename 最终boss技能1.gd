extends Node2D

# --- 旋涡参数 ---
@export var pull_force = 800.0  # 吸引力度，数值越大吸得越快
@export var kill_radius = 15.0  # 到达中心多少像素内判定死亡
@export var active_duration = 5.0 # 旋涡持续时间

@onready var sprite = $AnimatedSprite2D
@onready var area = $attackarea

var targets_in_range = []

func _ready():
	# 播放你截图里的 attack1 动画
	sprite.play("attack1")
	
	# 持续时间结束后自动消失
	await get_tree().create_timer(active_duration).timeout
	queue_free()

func _physics_process(delta):
	# 遍历所有在吸引范围内的物体（主要是玩家）
	for body in targets_in_range:
		if body is CharacterBody2D:
			# 1. 计算从玩家指向旋涡中心的向量
			var pull_dir = global_position - body.global_position
			var distance = pull_dir.length()
			
			# 2. 如果还没到中心，就狠狠地吸
			if distance > kill_radius:
				# 距离越近，吸力越强（模拟黑洞物理）
				var current_pull = pull_dir.normalized() * pull_force * (100.0 / max(distance, 10.0))
				body.velocity += current_pull * delta
				# 注意：如果玩家有自己的移动逻辑，这里会形成“挣扎”的效果
			else:
				# 3. 到达中心：触发你说的“黑洞死亡”
				_kill_player(body)

func _kill_player(player_node):
	print("玩家被卷入旋涡中心，系统彻底崩坏！")
	if player_node.has_method("die"):
		player_node.die()
	else:
		# 如果玩家没写 die 方法，直接强行移除（CEO 式暴力美学）
		player_node.queue_free()
	
	# 玩家死后，旋涡可以产生一个爆发效果然后消失
	queue_free()

# --- 信号连接 (Area2D) ---
# 请在编辑器里把 attackarea 的 body_entered 和 body_exited 连过来
func _on_attackarea_body_entered(body):
	if body.is_in_group("player"):
		targets_in_range.append(body)
		# 这里可以触发你说的“眼前一黑”效果信号
		print("玩家进入黑洞引力范围！")

func _on_attackarea_body_exited(body):
	if body in targets_in_range:
		targets_in_range.erase(body)
