extends Area2D

# 属性配置（完全保留你的原始设定）
@export var speed: float = 380.0  # M4加持，速度可以快点
@export var damage: int = 1
var target_node: Node2D = null
var velocity: Vector2 = Vector2.ZERO
var is_exploding: bool = false # 重点：状态锁

# 引用节点
@onready var sprite = $AnimatedSprite2D

func _ready():
	# 使用 group 查找玩家，更健壮
	target_node = get_tree().get_first_node_in_group("player")
	
	# 2. 【 Moving 阶段】
	sprite.play("moving") 

func _process(delta: float):
	if is_exploding: return

	if target_node:
		# --- 核心：追踪逻辑 ---
		var direction = (target_node.global_position - global_position).normalized()
		velocity = velocity.lerp(direction * speed, 0.12) 
		rotation = velocity.angle()
		global_position += velocity * delta

		# --- 碰撞判定（依然使用距离判定） ---
		if global_position.distance_to(target_node.global_position) < 30.0:
			hit_target()

func hit_target():
	is_exploding = true
	
	# 伤害逻辑
	if target_node.has_method("take_damage"):
		target_node.take_damage(damage)
	
	monitoring = false
	
	# 3. 【 Explode 阶段】
	sprite.play("explode") 
	
	# 等待爆炸动画播完后再消失
	await sprite.animation_finished 
	
	# 4. 【 Free 阶段】
	queue_free()

func _on_timer_timeout():
	if not is_exploding:
		queue_free()
