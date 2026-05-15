extends CharacterBody2D

# --- 基础属性 ---
var speed: float = 90.0
var death_count: int = 0
var damage_amount = 1.0
var health = 1
var block_rate: float = 0.47    # 已调低至 47%，更具平衡性
var is_dead: bool = false
var is_invincible: bool = false 

# --- 技能设置 ---
@onready var knight_scene = preload("res://骑士.tscn")
var skill_timer: Timer

@onready var player = get_tree().get_first_node_in_group("player")
@onready var sprite = $AnimatedSprite2D

func _ready():
	add_to_group("enemy")
	
	# 初始化 3 分钟定时器
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
	
	# 追踪与转向
	var direction = (player.global_position - global_position).normalized()
	sprite.flip_h = player.global_position.x < global_position.x
	
	if global_position.distance_to(player.global_position) > 50.0:
		velocity = direction * speed
		sprite.play("run")
	else:
		velocity = Vector2.ZERO
		sprite.play("idle")
	
	move_and_slide()

# --- 技能逻辑：消失 + 9骑士 ---
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
	var knight = knight_scene.instantiate()
	var spawn_x = player.global_position.x + randf_range(-150, 150)
	knight.global_position = Vector2(spawn_x, global_position.y - 400)
	get_parent().add_child(knight)

# --- 受伤判定 (47% 格挡) ---
func take_damage():
	if is_dead or is_invincible: return
	
	if randf() < block_rate:
		print("格挡！(47%几率)")
		# 这里可以加个清脆的金属声效
	else:
		death_count += 1
		sprite.play("hurt")
		print("击中！进度: " + str(death_count) + "/11")
		
		if death_count >= 11:
			is_dead = true
			sprite.play("die")
			# 确保跳转路径正确且无下划线
			await get_tree().create_timer(1.5).timeout
			if has_node("/root/SceneManager"):
				SceneManager.goto_next_level()
