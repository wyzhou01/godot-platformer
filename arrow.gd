extends Node2D

# 箭矢飞行脚本 v12
# 方向由外部传入，不硬编码，命中检测只依赖 player group

const DAMAGE := 1
const MAX_LIFETIME := 4.0

var _velocity: Vector2 = Vector2.ZERO
var _lifetime := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func initialize(direction: Vector2, speed: float) -> void:
	_velocity = direction.normalized() * speed
	print("[Arrow] 初始化 | 方向=", _velocity)

func _physics_process(delta: float) -> void:
	# 用外部设定的速度方向飞行
	position += _velocity * delta

	# 根据飞行方向旋转精灵（atan2: 从X轴正方向逆时针旋转的角度）
	rotation = _velocity.angle()

	# 距离检测：只检测 player group
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		var dist := global_position.distance_to(p.global_position)
		if dist < 30.0:
			print("[Arrow] 命中玩家！距离=", dist)
			if p.has_method("take_damage"):
				p.take_damage(DAMAGE)
			queue_free()
			return

	# 超时删除
	_lifetime += delta
	if _lifetime > MAX_LIFETIME:
		queue_free()
