extends Node2D

# ===== 旋涡参数 ---
@export var pull_force = 800.0
@export var kill_radius = 15.0
@export var active_duration = 5.0

@onready var sprite = $AnimatedSprite2D
@onready var area = $attackarea

var targets_in_range = []
var is_active: bool = true

func _ready():
	sprite.play("attack")

	await get_tree().create_timer(active_duration).timeout
	queue_free()

func _physics_process(delta: float):
	if not is_active: return

	for body in targets_in_range:
		if body is CharacterBody2D:
			# 如果玩家处于无敌帧，不受旋涡影响
			if body.get("is_invincible") == true:
				continue

			var pull_dir = global_position - body.global_position
			var distance = pull_dir.length()

			if distance > kill_radius:
				var current_pull = pull_dir.normalized() * pull_force * (100.0 / max(distance, 10.0))
				body.velocity += current_pull * delta
			else:
				_kill_player(body)

func _kill_player(player_node: Node):
	print("玩家被卷入旋涡中心，系统彻底崩坏！")
	is_active = false
	if player_node.has_method("die"):
		player_node.die()
	queue_free()

func _on_attackarea_body_entered(body):
	if body.is_in_group("player"):
		if not body in targets_in_range:
			targets_in_range.append(body)
		print("玩家进入黑洞引力范围！")

func _on_attackarea_body_exited(body):
	if body in targets_in_range:
		targets_in_range.erase(body)