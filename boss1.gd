extends CharacterBody2D

# --- 属性变量 ---
var speed: float = 120.0
var death_count: int = 0
var block_rate: float = 0.55
var health = 1
var damage_amount = 1.0
var is_dead: bool = false

# 这里的路径一定要和你文件夹里的一模一样（无下划线，注意大小写）
@export_file("*.tscn") var next_level_path: String = "res://levels/Level2.tscn"

# 获取玩家节点 (假设玩家就在父节点下，名字叫 Player)
@onready var player = get_tree().get_first_node_in_group("player")

func _ready():
	add_to_group("enemy")

func _physics_process(_delta: float) -> void:
	if is_dead or player == null:
		return
	
	# 1. 计算玩家方向
	var direction = (player.global_position - global_position).normalized()
	
	# 2. 核心转身代码 (根据玩家在左还是在右，翻转 Sprite 节点)
	if player.global_position.x < global_position.x:
		$Sprite2D.flip_h = true   # 玩家在左，Boss 往左转
	else:
		$Sprite2D.flip_h = false  # 玩家在右，Boss 往右转
	
	# 3. 追踪移动 (4.x 标准写法)
	if global_position.distance_to(player.global_position) > 45:
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO # 靠太近就停下，冷冷地盯着你
		
	move_and_slide()

# --- 战斗判定 ---
func take_damage():
	if is_dead: return
	
	if randf() < block_rate:
		print("格挡！")
	else:
		death_count += 1
		print("击中！计数：" + str(death_count) + "/11")
		
		if death_count >= 11:
			win_and_go()

func win_and_go():
	is_dead = true
	print("Boss 被击败，3000 年后的宿命开启...")
	
	# 延迟 1 秒跳转，防止画面太突兀
	await get_tree().create_timer(1.0).timeout
	
	if has_node("/root/SceneManager"):
		SceneManager.goto_next_level()
