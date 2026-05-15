extends Area2D

@export var speed: float = 250.0  # 大火球飞得稍慢，更有压迫感
var damage: int = 1
var lifetime: float = 6.0
var damage_interval: float = 0.5 # 每0.5秒烧一次
var timer: float = 0.0

func _ready():
	$AnimatedSprite2D.play("fireball") 
	# 6秒后自动毁灭
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _process(delta):
	# 直线穿透飞行
	var direction = Vector2.RIGHT.rotated(rotation)
	global_position += direction * speed * delta
	
	# 持续伤害逻辑
	timer += delta
	if timer >= damage_interval:
		check_damage()
		timer = 0.0

func check_damage():
	# 检查重叠的物体
	var bodies = get_overlapping_bodies()
	for body in bodies:
		# 使用 group 判定玩家，更健壮
		if body.is_in_group("player"):
			if body.has_method("take_damage"):
				body.take_damage(damage)
				print("[战斗反馈] 火球2号烧到了：", body.name)
