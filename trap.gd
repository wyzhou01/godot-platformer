extends Area2D

@export var damage_amount = 9999 # 确保能秒杀怪兽或造成重伤

func _physics_process(_delta):
	# 每帧主动获取重叠的物体，不需要在编辑器里连线
	var overlapping_bodies = get_overlapping_bodies()
	
	for body in overlapping_bodies:
		# 检查物体是否有受伤函数
		if body.has_method("take_damage"):
			body.take_damage(damage_amount)
			# 如果是单次陷阱，可以加一句 queue_free() 把它移除
