extends Node2D

# --- 弹幕参数 ---
@export var speed = 400.0       # 飞行速度
@export var damage = 1          # 反正玩家也就 1 血，碰着就死
@export var lifetime = 4.0      # 没撞到东西多久后消失

var direction = Vector2.RIGHT   # 飞行方向

@onready var sprite = $AnimatedSprite2D

func _ready():
	# 播放截图里那个超帅的 attack1 燃烧动画
	sprite.play("attack1")
	
	# 旋转图片，让火焰尖端指向飞行方向
	rotation = direction.angle()
	
	# 自动销毁计时
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	# 像彩京游戏一样，笔直且决绝地冲向目标
	global_position += direction * speed * delta

# --- 碰撞逻辑 ---
func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		print("魔焰入体！玩家感受到了 1267 年的灼烧！")
		
		# 触发玩家死亡逻辑
		if body.has_method("die"):
			body.die()
		
		# 击中后产生一个小范围爆炸效果再消失
		_explode()

func _explode():
	# 这里可以添加爆炸粒子或者缩放动画
	speed = 0 # 停下
	sprite.play("attack1") # 或者播放一个爆炸动画
	# 这种细节 CEO 您肯定手到擒来
	await get_tree().create_timer(0.2).timeout
	queue_free()
