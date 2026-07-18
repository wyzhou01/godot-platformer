extends Node2D

# ===== 弹幕参数 ---
@export var speed = 400.0
@export var damage = 1
@export var lifetime = 4.0

var direction = Vector2.RIGHT
var is_destroyed: bool = false

@onready var sprite = $AnimatedSprite2D

func _ready():
	sprite.play("attack")
	rotation = direction.angle()

	await get_tree().create_timer(lifetime).timeout
	if not is_destroyed:
		queue_free()

func _physics_process(delta: float):
	if is_destroyed: return
	global_position += direction * speed * delta

func _on_area_2d_body_entered(body):
	if is_destroyed: return
	if body.is_in_group("player"):
		if body.has_method("die"):
			body.die()
		_explode()

func _explode():
	if is_destroyed: return
	is_destroyed = true
	speed = 0
	sprite.play("attack")
	await get_tree().create_timer(0.2).timeout
	queue_free()