extends CharacterBody2D

# ===== 调试开关 =====
const DEBUG = false
func _debug_print(msg):
	if DEBUG: print(msg)

# --- 基础属性 ---
@export var speed: float = 90.0
@export var death_count: int = 0
@export var damage_amount: float = 1.0
@export var health: int = 1
@export var block_rate: float = 0.47
var is_dead: bool = false
var is_invincible: bool = false

# --- 技能设置 ---
@export var knight_scene: PackedScene = preload("res://骑士.tscn")
var skill_timer: Timer

@onready var player = get_tree().get_first_node_in_group("player")
@onready var sprite = $AnimatedSprite2D

func _ready():
	add_to_group("enemy")

	skill_timer = Timer.new()
	skill_timer.wait_time = 180.0
	skill_timer.autostart = true
	skill_timer.one_shot = false
	skill_timer.timeout.connect(_on_skill_timeout)
	add_child(skill_timer)

	randomize()

func _physics_process(_delta: float) -> void:
	if is_dead or is_invincible or player == null:
		return

	var direction = (player.global_position - global_position).normalized()
	sprite.flip_h = player.global_position.x < global_position.x

	if global_position.distance_to(player.global_position) > 50.0:
		velocity = direction * speed
		sprite.play("run")
	else:
		velocity = Vector2.ZERO
		sprite.play("idle")

	move_and_slide()

func _on_skill_timeout():
	if is_dead: return

	is_invincible = true
	sprite.modulate.a = 0
	set_collision_layer_value(1, false)

	for i in range(9):
		spawn_knight()
		await get_tree().create_timer(0.5).timeout

	await get_tree().create_timer(1.0).timeout
	sprite.modulate.a = 1
	set_collision_layer_value(1, true)
	is_invincible = false

func spawn_knight():
	if not knight_scene:
		_debug_print("[Boss2] knight_scene 未设置，跳过生成")
		return
	var knight = knight_scene.instantiate()
	if not knight:
		_debug_print("[Boss2] knight 场景实例化失败，跳过")
		return
	var spawn_x = player.global_position.x + randf_range(-150, 150)
	knight.global_position = Vector2(spawn_x, global_position.y - 400)
	get_parent().add_child(knight)

func take_damage(amount: int = 1):
	if is_dead or is_invincible: return

	if randf() < block_rate:
		_debug_print("格挡！(47%几率)")
	else:
		death_count += 1
		sprite.play("hurt")
		_debug_print("击中！进度: " + str(death_count) + "/11")

		if death_count >= 11:
			is_dead = true
			sprite.play("die")
			await get_tree().create_timer(1.5).timeout
			if has_node("/root/SceneManager"):
				SceneManager.goto_next_level()