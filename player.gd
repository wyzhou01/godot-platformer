extends CharacterBody2D

# ===== 玩家属性 =====
const SPEED = 200.0
const JUMP_VELOCITY = -450.0
const ATTACK_FRICTION = 600.0
const DODGE_SPEED = 480.0
const DODGE_DURATION = 0.25
const INVINCIBLE_DURATION = 1.2
const MAX_HEALTH = 50                   # 50格血
const PLAYER_DAMAGE = 3                # 玩家攻击:3刀砍死9血弓箭手
const ENEMY_HIT_RADIUS := 550.0     # 攻击判定半径（约9格）

# ===== 状态变量 =====
var is_attacking = false
var is_crouching = false
var is_dodging = false
var is_invincible = false
var is_dead = false
var player_health = MAX_HEALTH

var combo_count = 0
var dodge_timer := 0.0
var dodge_direction := 1               # 1=右,-1=左

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $"attack area"
@onready var hp_fill: ColorRect = $HealthBar/HPBg/HPFill
@onready var hp_label: Label = $HealthBar/HPBg/HPLabel
@onready var combo_timer: Timer = Timer.new()
@onready var invincible_timer: Timer = Timer.new()
@onready var dodge_timer_node: Timer = Timer.new()
@onready var hurt_flash: Node2D = $hurt_flash if has_node("hurt_flash") else null

# ===== 初始化 =====
func _ready() -> void:
	# 向所有敌人广播:我是玩家
	add_to_group("player")
	print("[Player] 已加入 group")

	# 攻击区域:启用碰撞检测
	if attack_area:
		attack_area.monitoring = false  # 默认关闭,攻击时开启
		# collision_mask: 检测所有物体(layer 1)
		attack_area.collision_mask = 0b0001  # 检测 layer 1
		if attack_area.body_entered.is_connected(_on_attack_area_body_entered):
			attack_area.body_entered.disconnect(_on_attack_area_body_entered)
		attack_area.body_entered.connect(_on_attack_area_body_entered)

	# 连击计时器
	add_child(combo_timer)
	combo_timer.wait_time = 0.6
	combo_timer.one_shot = true
	combo_timer.timeout.connect(_on_combo_timeout)

	# 无敌计时器
	add_child(invincible_timer)
	invincible_timer.one_shot = true
	invincible_timer.timeout.connect(_on_invincible_timeout)

	# 闪避计时器
	add_child(dodge_timer_node)
	dodge_timer_node.one_shot = true
	dodge_timer_node.timeout.connect(_on_dodge_timeout)

	# 动画完成信号
	if not sprite.animation_finished.is_connected(_on_animated_sprite_2d_animation_finished):
		sprite.animation_finished.connect(_on_animated_sprite_2d_animation_finished)

	print("[Player] 初始化完成 | 生命=", player_health)
	_update_health_bar()

# ===== 主循环 =====
func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# --- 闪避中:无敌 + 快速位移 ---
	if is_dodging:
		velocity.x = dodge_direction * DODGE_SPEED
		velocity.y += get_gravity().y * delta * 0.3
		move_and_slide()
		sprite.modulate.a = 0.4 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
		return

	sprite.modulate.a = 1.0

	# --- 重力 ---
	if not is_on_floor():
		velocity.y += get_gravity().y * delta

	# --- 移动/攻击 ---
	var direction := Input.get_axis("left", "right")
	if is_attacking:
		# 攻击中:仍然允许走路(攻击和移动不冲突)
		_check_melee_hit()
		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * SPEED, ATTACK_FRICTION * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, ATTACK_FRICTION * delta)
	else:
		handle_movement_input(direction)

	move_and_slide()
	update_animations(direction)

# ===== 输入处理 =====
func handle_movement_input(direction: float) -> void:
	is_crouching = Input.is_action_pressed("crouch")

	# 闪避(X键)
	if Input.is_key_pressed(KEY_X) and not is_dodging and is_on_floor():
		var dir := Input.get_axis("left", "right")
		var dodge_dir := 1 if dir == 0 else int(dir)
		start_dodge(dodge_dir)
	# 跳跃
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_dodging:
		velocity.y = JUMP_VELOCITY
	# 攻击(鼠标左键)
	if Input.is_action_just_pressed("attack"):
		print("[Player] 攻击键按下!")
		execute_combo()
		return
	# 移动
	if direction != 0:
		velocity.x = direction * SPEED
		sprite.flip_h = (direction < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

# ===== 闪避 =====
func start_dodge(dir: int) -> void:
	is_dodging = true
	is_invincible = true
	dodge_direction = dir
	dodge_timer_node.start(DODGE_DURATION)
	sprite.play("jump")  # 用跳跃动作代替闪避动画

func _on_dodge_timeout() -> void:
	is_dodging = false
	dodge_timer_node.stop()

# ===== 攻击 =====
func execute_combo() -> void:
	if is_attacking: return
	is_attacking = true
	combo_timer.stop()
	print("[Player] 执行攻击! combo=", combo_count)

	# 攻击时启用攻击区域碰撞检测
	if attack_area:
		attack_area.monitoring = true

	var push_force := 180.0
	if combo_count == 2:
		push_force = 300.0
	var move_dir := -1 if sprite.flip_h else 1
	velocity.x = move_dir * push_force

	var anim_to_play := "attack" + str(combo_count + 1)
	if sprite.sprite_frames.has_animation(anim_to_play):
		sprite.play(anim_to_play)
	else:
		sprite.play("attack")

	combo_count = (combo_count + 1) % 3
	combo_timer.start()

# ===== 近战攻击命中检测(距离判定)=====
func _check_melee_hit() -> void:
	if not is_attacking:
		return
	for enemy in get_tree().get_nodes_in_group("enemy"):
		# 跳过已死亡的敌人（queue_free前还在group里）
		if enemy.get("is_dead") == true:
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist < ENEMY_HIT_RADIUS:
			if enemy.has_method("take_damage"):
				enemy.take_damage(PLAYER_DAMAGE)
				print("[Player] 砍中!", enemy.get_name(), "! 距离=", dist)
			break  # 每攻击只命中一个敌人
			break

# ===== 受伤 =====
func take_damage(amount: int = 1) -> void:
	if is_dead or is_invincible:
		return

	player_health -= amount
	print("[Player] 被击中!剩余生命:", player_health)
	_update_health_bar()

	is_invincible = true
	invincible_timer.start(INVINCIBLE_DURATION)

	# 受伤闪烁效果
	flash_hurt()

	if player_health <= 0:
		die()
	else:
		# 受伤硬直:短时间停止
		is_attacking = false
		velocity = Vector2.ZERO

func flash_hurt() -> void:
	if sprite:
		sprite.modulate = Color(3, 1, 1)  # 红色闪烁
		await get_tree().create_timer(0.15).timeout
		if sprite:
			sprite.modulate = Color.WHITE

func _update_health_bar() -> void:
	if hp_fill:
		hp_fill.scale.y = 1.0  # 恢复高度
		# scale.x 从 0→1 代表血量百分比
		hp_fill.scale = Vector2(float(player_health) / float(MAX_HEALTH), 1.0)
	if hp_label:
		hp_label.text = "%s / %s" % [player_health, MAX_HEALTH]

func _on_invincible_timeout() -> void:
	is_invincible = false
	if sprite:
		sprite.modulate = Color.WHITE

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	print("[Player] 死亡!")
	sprite.play("rip")
	# 清理场上所有箭矢
	for arrow in get_tree().get_nodes_in_group("arrow"):
		arrow.queue_free()
	# 1.5秒后重启场景
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()

# ===== 攻击命中检测(核心链路)=====
# 当玩家攻击动画触发时,attack area 会检测范围内的敌人
# 攻击区域回调(现已改用距离检测,此回调仅作备用)
func _on_attack_area_body_entered(body: Node2D) -> void:
	pass  # 已改用 _check_melee_hit() 距离检测

# ===== 动画更新 =====
func update_animations(direction: float) -> void:
	if is_attacking or is_dodging:
		return
	if is_on_floor():
		if is_crouching:
			sprite.play("crouch-idle")
		elif direction != 0:
			sprite.play("run")
		else:
			sprite.play("idle")
	else:
		sprite.play("jump" if velocity.y < 0 else "jump")

# ===== 信号回调 =====
func _on_combo_timeout() -> void:
	combo_count = 0
	# 强制解除攻击状态(安全网)
	is_attacking = false

func _on_animated_sprite_2d_animation_finished() -> void:
	var anim := sprite.animation
	print("[Player] 动画完成: ", anim)
	if anim.begins_with("attack"):
		if attack_area:
			attack_area.monitoring = false
		is_attacking = false
		if is_on_floor():
			velocity.x = 0
	elif anim == "rip":
		pass
