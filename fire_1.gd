extends Area2D

# 属性配置
@export var speed: float = 380.0
@export var damage: int = 1
var target_node: Node2D = null
var velocity: Vector2 = Vector2.ZERO
var is_exploding: bool = false
var is_dead: bool = false  # 死亡状态锁，防止死后继续处理

# 引用节点
@onready var sprite = $AnimatedSprite2D
@onready var lifetime_timer: Timer = Timer.new()

func _ready():
	target_node = get_tree().get_first_node_in_group("player")

	# 设置安全定时器并正确连接
	lifetime_timer.wait_time = 3.0
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(_on_timer_timeout)
	add_child(lifetime_timer)
	lifetime_timer.start()

	sprite.play("moving")

func _process(delta: float):
	if is_dead or is_exploding: return

	if target_node:
		var direction = (target_node.global_position - global_position).normalized()
		velocity = velocity.lerp(direction * speed, 0.12)
		rotation = velocity.angle()
		global_position += velocity * delta

		if global_position.distance_to(target_node.global_position) < 30.0:
			hit_target()

func hit_target():
	if is_exploding: return
	is_exploding = true

	if target_node.has_method("take_damage"):
		target_node.take_damage(damage)

	monitoring = false

	sprite.play("explode")

	await sprite.animation_finished

	is_dead = true
	queue_free()

func _on_timer_timeout():
	if not is_exploding and not is_dead:
		is_dead = true
		queue_free()