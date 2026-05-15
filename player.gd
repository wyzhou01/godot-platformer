extends CharacterBody2D

# ===== 调试开关 =====
const DEBUG = false
func _debug_print(msg):
	if DEBUG: print(msg)

# ===== 1. 核心属性 =====
const SPEED = 200.0
const JUMP_VELOCITY = -450.0
const ATTACK_FRICTION = 600.0
const DODGE_SPEED = 480.0
const DODGE_DURATION = 0.25
const INVINCIBLE_DURATION = 1.2
const PLAYER_DAMAGE = 3.0
const ENEMY_HIT_RADIUS := 80.0

# ===== 2. 内部状态 =====
var is_attacking = false
var is_dodging = false
var is_invincible = false
var is_dead = false
var _has_hit_this_swing = false  # 本次攻击是否已命中，防止一刀砍多次

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var invincible_timer: Timer = Timer.new()
@onready var dodge_timer_node: Timer = Timer.new()

func _ready() -> void:
	add_to_group("player")
	_setup_timer(invincible_timer, INVINCIBLE_DURATION, func(): is_invincible = false)
	_setup_timer(dodge_timer_node, DODGE_DURATION, func(): is_dodging = false)

	if not sprite.animation_finished.is_connected(_on_anim_finished):
		sprite.animation_finished.connect(_on_anim_finished)

func _setup_timer(t: Timer, wait: float, callback: Callable):
	add_child(t)
	t.wait_time = wait
	t.one_shot = true
	t.timeout.connect(callback)

func _physics_process(delta: float) -> void:
	if is_dead: return
	if is_dodging:
		_has_hit_this_swing = false  # 重置攻击标记
		velocity.x = (1 if not sprite.flip_h else -1) * DODGE_SPEED
		move_and_slide()
		return

	if not is_on_floor(): velocity.y += get_gravity().y * delta

	var direction := Input.get_axis("left", "right")
	if is_attacking:
		_check_melee_hit()
		velocity.x = move_toward(velocity.x, 0, ATTACK_FRICTION * delta)
	else:
		handle_movement_input(direction)

	move_and_slide()
	update_animations(direction)

func handle_movement_input(direction: float) -> void:
	if Input.is_key_pressed(KEY_X) and is_on_floor():
		is_dodging = true
		dodge_timer_node.start()
	if Input.is_action_just_pressed("jump") and is_on_floor(): velocity.y = JUMP_VELOCITY
	if Input.is_action_just_pressed("attack"):
		is_attacking = true
		_has_hit_this_swing = false  # 重置命中标记，新攻击开始
		sprite.play("attack")

	if direction != 0:
		velocity.x = direction * SPEED
		sprite.flip_h = (direction < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func _check_melee_hit() -> void:
	if not _has_hit_this_swing:  # 本次攻击还没命中过才检测
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if enemy.get("is_dead"): continue
			if global_position.distance_to(enemy.global_position) < ENEMY_HIT_RADIUS:
				if enemy.has_method("take_damage"):
					enemy.take_damage(PLAYER_DAMAGE)
					_has_hit_this_swing = true  # 本次攻击已命中，锁定
					break

# ===== 核心修改：受击即死 =====
# 注意：50HP 配置已弃用，当前为即死模式（一触即死）
func take_damage(_amount: int = 1) -> void:
	if is_dead or is_invincible: return
	die()

func die():
	if is_dead: return
	is_dead = true
	sprite.play("die")
	set_physics_process(false)
	_debug_print("在 1267 年的波兰，没有人能抗住这一击...")
	await sprite.animation_finished
	if has_node("/root/SceneManager"):
		SceneManager.on_player_died()

func set_invincible(val: bool):
	is_invincible = val
	if val:
		if invincible_timer.is_stopped():
			invincible_timer.start()

func _on_animated_sprite_2d_animation_finished():
	_on_anim_finished()

func _on_anim_finished():
	if sprite.animation == "attack": is_attacking = false

func update_animations(direction: float) -> void:
	if is_attacking or is_dodging: return
	if is_on_floor():
		sprite.play("run" if direction != 0 else "idle")
	else:
		sprite.play("jump")