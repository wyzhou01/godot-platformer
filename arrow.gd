extends Node2D

const DAMAGE := 1
const MAX_LIFETIME := 4.0
const ARROW_RANGE := 1800.0        # 约1个画面宽度

var _velocity: Vector2 = Vector2.ZERO
var _lifetime := 0.0
var _hit_players: Array[Node2D] = []
var _start_pos: Vector2 = Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox

func initialize(direction: Vector2, speed: float) -> void:
	_velocity = direction.normalized() * speed
	_start_pos = global_position  # 记录起点，用于算射程
	# 箭只水平翻转，不旋转（保持平行地面）
	if sprite:
		sprite.flip_v = false
		sprite.flip_h = _velocity.x < 0
	print("[Arrow] 初始化 | 速度=", _velocity.length(), " | 方向=", _velocity.normalized())

func _ready() -> void:
	hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	position += _velocity * delta

	# 射程检测：超过1个画面宽度就消失
	if _start_pos.distance_to(global_position) > ARROW_RANGE:
		queue_free()
		return

	# 超时删除
	_lifetime += delta
	if _lifetime > MAX_LIFETIME:
		queue_free()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if _hit_players.has(body):
		return
	_hit_players.append(body)

	print("[Arrow] 击中玩家！")
	if body.has_method("take_damage"):
		body.take_damage(DAMAGE)
	queue_free()
