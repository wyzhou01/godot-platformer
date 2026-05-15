extends Area2D

# ===== 调试开关 =====
const DEBUG = false
func _debug_print(msg):
	if DEBUG: print(msg)

@export var speed: float = 250.0
var damage: int = 1
var lifetime: float = 6.0
var damage_interval: float = 0.5
var timer: float = 0.0
var has_hit: bool = false

func _ready():
	$AnimatedSprite2D.play("fireball")
	get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_timeout)

func _on_lifetime_timeout():
	queue_free()

func _process(delta):
	var direction = Vector2.RIGHT.rotated(rotation)
	global_position += direction * speed * delta

	timer += delta
	if timer >= damage_interval:
		check_damage()
		timer = 0.0

func check_damage():
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
			if body.has_method("take_damage"):
				body.take_damage(damage)
				_debug_print("[战斗反馈] 火球2号烧到了：" + body.name)