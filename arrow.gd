extends Node2D

const DAMAGE := 1
const MAX_LIFETIME := 4.0
const ARROW_RANGE := 1800.0

var _velocity: Vector2 = Vector2.ZERO
var _lifetime := 0.0
var _hit_players: Array[Node2D] = []
var _start_pos: Vector2 = Vector2.ZERO
var _debug_frames: int = 0
var _arrow_id: int = 0
static var _total_arrows: int = 0

var _sprite: AnimatedSprite2D
var _hitbox: Area2D

func _ready() -> void:
	_sprite = $AnimatedSprite2D
	_hitbox = $Hitbox
	_hitbox.body_entered.connect(_on_hitbox_body_entered)
	print("[Arrow] _ready: sprite=", _sprite)

func initialize(direction: Vector2, speed: float) -> void:
	_velocity = direction.normalized() * speed
	_start_pos = global_position
	_arrow_id = _total_arrows
	_total_arrows += 1
	_debug_frames = 0
	if _sprite:
		_sprite.flip_v = false
		_sprite.flip_h = _velocity.x < 0
	print("[Arrow] 初始化 #", _arrow_id, " | vel=", _velocity, " | flip_h=", _sprite.flip_h if _sprite else "null")

func _physics_process(delta: float) -> void:
	position += _velocity * delta
	_debug_frames += 1
	if _sprite:
		_sprite.flip_h = _velocity.x < 0
	# 前3帧打印飞行状态
	if _debug_frames <= 3:
		print("[Arrow #", _arrow_id, "] pos=", position, " vel=", _velocity)

	# 射程检测
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
