extends Area2D

@export var speed: float = 550.0   # 速度比1号、2号都要快，主打"偷袭"
@export var damage: int = 1       # 伤害数值保留
@export var lifetime: float = 3    # 寿命保留

var direction: Vector2 = Vector2.ZERO

func _ready():
	# 从 rotation 计算 direction（wizard3 只设 rotation 不设 direction）
	direction = Vector2.RIGHT.rotated(rotation)
	
	# 让火球指向它的飞行方向
	if direction != Vector2.ZERO:
		look_at(global_position + direction)
	
	# 设置一个定时器，防止火球飞出地图后一直存在
	get_tree().create_timer(lifetime).timeout.connect(destroy)

func _physics_process(delta: float):
	# 核心飞行逻辑
	position += direction * speed * delta

# --- 信号连接：当撞到东西时 ---
func _on_body_entered(body: Node2D):
	# 使用 group 判断玩家
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
			print("[Combat] 偷袭成功！命中：", body.name)
		
		# 触发销毁流程
		destroy()
	
	# 如果撞到了墙（TileMap）也消失
	elif body is TileMap:
		destroy()

func destroy():
	# 消失动画：保留你设计的 Tween 缩放特效
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.1)
	await tween.finished
	queue_free()
