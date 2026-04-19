extends CharacterBody2D

# ===== 导出参数 =====
@export var health: int = 9                       # 弓箭手生命值（9点）
@export var speed: float = 50.0
@export var detection_range: float = 800.0    # 感知玩家距离
@export var attack_cooldown: float = 1.0       # 射箭间隔（秒）
@export var arrow_speed: float = 600.0         # 箭矢速度
@export var is_archer: bool = true            # 是否为弓箭手（默认true，同一场景两个都是）

# ===== 内部状态 =====
var is_acting: bool = false                   # 动画锁（受伤/死亡动画期间禁止其他行为）
var is_dead: bool = false                     # 死亡状态
var player: Node2D = null
var attack_timer: float = attack_cooldown  # 启动时充满CD，第一次射箭等3秒
var facing_right: bool = true
var _debug_tick: int = 0  # 每帧+1，每120帧打印一次

# 箭矢场景预加载
const ARROW_SCENE := preload("res://arrow.tscn")

# ===== 初始化 =====
func _ready() -> void:
	# 向所有敌人广播：我是敌人（供玩家距离检测用）
	add_to_group("enemy")

	# 自动识别弓箭手（节点名含"弓箭"）
	if get_name().find("弓箭") >= 0 or get_name().to_lower().find("archer") >= 0:
		is_archer = true

	# 查找玩家节点（优先用 group，更可靠）
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		# 备用：逐个尝试常见节点名
		for name in ["player", "Player", "PlayerBody", "player_body"]:
			var found = get_tree().root.find_child(name, true, false)
			if found:
				player = found
				break

	# 动画完成信号
	if $AnimatedSprite2D.animation_finished.is_connected(_on_animation_finished):
		$AnimatedSprite2D.animation_finished.disconnect(_on_animation_finished)
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)

	print("[Enemy] ", get_name(), " 初始化 | is_archer=", is_archer, " | 生命=", health, " | player=", player)

# ===== 每帧AI逻辑 =====
func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# 调试：每2秒打印一次状态
	_debug_tick += 1
	if _debug_tick % 120 == 0:
		print("[Enemy] tick | player=", player, " | is_acting=", is_acting)

	if is_acting:
		return

	if not player:
		velocity = Vector2.ZERO
		_play_anim("idle")
		move_and_slide()
		return

	# 计算与玩家的距离和方向
	var to_player: Vector2 = player.global_position - global_position
	var dist: float = to_player.length()
	var dir_sign: float = sign(to_player.x)

	# 更新朝向（朝向玩家）
	if dir_sign != 0.0:
		var prev := facing_right
		facing_right = dir_sign > 0
		$AnimatedSprite2D.flip_h = not facing_right

	if dist <= detection_range:
		# === 感知范围内 ===
		velocity = Vector2.ZERO  # 弓箭手不追踪，原地射箭

		attack_timer -= delta
		if attack_timer <= 0.0:
			attack_timer = attack_cooldown
			if is_archer:
				_shoot_arrow(to_player.normalized())

		_play_anim("attack")
	else:
		# === 超出范围：待机 ===
		velocity = Vector2.ZERO
		attack_timer = 0.0
		_play_anim("idle")

	move_and_slide()

# ===== 射箭 =====
func _shoot_arrow(direction: Vector2) -> void:
	if not is_archer:
		return

	var arrow = ARROW_SCENE.instantiate()
	if not arrow:
		print("[Enemy] 箭矢场景实例化失败")
		return

	# 朝向玩家的方向（Y归零保证平行地面）
	var fly_dir: Vector2 = direction.normalized()
	fly_dir.y = 0.0
	fly_dir = fly_dir.normalized()

	var spawn_pos: Vector2 = global_position + fly_dir * 50.0 + Vector2(0, -10)
	arrow.global_position = spawn_pos
	if arrow.has_method("initialize"):
		# 朝向根据facing_right决定，确保箭和精灵朝向一致
		var arrow_dir := Vector2(1.0, 0.0) if facing_right else Vector2(-1.0, 0.0)
		print("[Enemy射箭]", get_name(), "facing_right=", facing_right, "→箭头方向=", arrow_dir)
		arrow.initialize(arrow_dir, arrow_speed)
	else:
		var arrow_body: CharacterBody2D = arrow.get_node_or_null("CharacterBody2D")
		if arrow_body:
			var arrow_dir := Vector2(1.0, 0.0) if facing_right else Vector2(-1.0, 0.0)
			arrow_body.velocity = arrow_dir * arrow_speed

	get_parent().add_child(arrow)
	arrow.add_to_group("arrow")

# ===== 受伤（被玩家攻击命中）=====
func take_damage(amount: int) -> void:
	# 死亡状态或动画播放中不重复受击
	if is_dead:
		return

	health -= amount
	print("[Enemy] 被攻击！剩余生命：", health, " | 伤害：", amount)

	# 停止当前行为
	is_acting = true
	velocity = Vector2.ZERO

	if health <= 0:
		die()
	else:
		# 受伤反应
		_show_hurt_effect()
		_play_anim("hurt")

# ===== 死亡 =====
func die() -> void:
	is_dead = true
	is_acting = true
	velocity = Vector2.ZERO
	print("[Enemy] ", get_name(), " 死亡！")
	_play_anim("rip")
	# 0.5秒后删除整个节点
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _show_hurt_effect() -> void:
	# 白色闪白效果
	$AnimatedSprite2D.modulate = Color(2.5, 2.5, 2.5)
	var tween := create_tween()
	tween.tween_property($AnimatedSprite2D, "modulate", Color.WHITE, 0.2)

# ===== 动画播放辅助 =====
func _play_anim(anim_name: String) -> void:
	var spr := $AnimatedSprite2D
	if not spr.sprite_frames:
		return
	if spr.sprite_frames.has_animation(anim_name) and spr.animation != anim_name:
		spr.play(anim_name)
	elif not spr.sprite_frames.has_animation(anim_name):
		# 如果动画不存在，静默跳过（不报错）
		pass

# ===== 动画完成回调 =====
func _on_animation_finished() -> void:
	if is_dead:
		return
	var anim: StringName = $AnimatedSprite2D.animation
	if anim == "rip":
		# 死亡动画播完，保持不动
		is_acting = true
	elif anim == "hurt":
		# 受伤动画播完，解锁并恢复待机
		is_acting = false
	elif anim.begins_with("attack"):
		# 攻击动画播完，解锁（可继续攻击）
		is_acting = false
