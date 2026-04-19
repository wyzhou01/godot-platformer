extends Node2D

const DAMAGE := 1
const MAX_LIFETIME := 4.0

var _velocity: Vector2 = Vector2.ZERO
var _lifetime := 0.0
var _hit_players: Array[Node2D] = []

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox

func initialize(direction: Vector2, speed: float) -> void:
	_velocity = direction.normalized() * speed
	# 旋转精灵朝飞行方向（angle() 从X轴正方向逆时针）
	rotation = _velocity.angle()
	print("[Arrow] 初始化 | 速度=", _velocity.length(), " | 方向=", _velocity.normalized())

func _ready() -> void:
	# 连接碰撞信号：碰到玩家身体就扣血
	hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	# 沿速度方向移动（不走物理引擎，避免撞墙）
	position += _velocity * delta

	# 超时删除
	_lifetime += delta
	if _lifetime > MAX_LIFETIME:
		queue_free()

# ===== 碰撞回调：碰到玩家身体才扣血 =====
func _on_hitbox_body_entered(body: Node2D) -> void:
	# 检查是否在 player group 且未命中过
	if not body.is_in_group("player"):
		return
	if _hit_players.has(body):
		return
	_hit_players.append(body)

	print("[Arrow] 击中玩家！")
	if body.has_method("take_damage"):
		body.take_damage(DAMAGE)

	# 命中后删除箭矢
	queue_free()
