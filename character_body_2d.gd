extends CharacterBody2D

# ===== 调试开关 =====
const DEBUG = false
func _debug_print(msg):
	if DEBUG: print(msg)

# ===== 导出参数 =====
@export var health: int = 9
@export var speed: float = 50.0
@export var detection_range: float = 800.0
@export var attack_cooldown: float = 1.0
@export var arrow_speed: float = 600.0
@export var is_archer: bool = true

# ===== 内部状态 =====
var is_acting: bool = false
var is_dead: bool = false
var player: Node2D = null
var attack_timer: float = attack_cooldown
var facing_right: bool = true
var _debug_tick: int = 0

const ARROW_SCENE := preload("res://arrow.tscn")

func _ready():
	add_to_group("enemy")

	if get_name().find("弓箭") >= 0 or get_name().to_lower().find("archer") >= 0:
		is_archer = true

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		for name in ["player", "Player", "PlayerBody", "player_body"]:
			var found = get_tree().root.find_child(name, true, false)
			if found:
				player = found
				break

	if $AnimatedSprite2D.animation_finished.is_connected(_on_animation_finished):
		$AnimatedSprite2D.animation_finished.disconnect(_on_animation_finished)
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)

	_debug_print("[Enemy] " + get_name() + " 初始化 | is_archer=" + str(is_archer) + " | 生命=" + str(health) + " | player=" + str(player))

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_debug_tick += 1
	if DEBUG and _debug_tick % 120 == 0:
		_debug_print("[Enemy] tick | player=" + str(player) + " | is_acting=" + str(is_acting))

	if is_acting:
		return

	if not player:
		velocity = Vector2.ZERO
		_play_anim("idle")
		move_and_slide()
		return

	var to_player: Vector2 = player.global_position - global_position
	var dist: float = to_player.length()
	var dir_sign: float = sign(to_player.x)

	if dir_sign != 0.0:
		facing_right = dir_sign > 0
		$AnimatedSprite2D.flip_h = facing_right

	# 动态获取屏幕宽度（从玩家相机，而非硬编码512）
	var screen_width: float = _get_screen_width()

	if dist <= detection_range and absf(player.global_position.x - global_position.x) < screen_width:
		velocity = Vector2.ZERO

		attack_timer -= delta
		if attack_timer <= 0.0:
			attack_timer = attack_cooldown
			if is_archer:
				_shoot_arrow(to_player.normalized())

		_play_anim("attack")
	else:
		velocity = Vector2.ZERO
		attack_timer = 0.0
		_play_anim("idle")

	move_and_slide()

func _get_screen_width() -> float:
	if player and player.has_node("Camera2D"):
		var camera = player.get_node("Camera2D")
		return get_viewport_rect().size.x / camera.zoom.x
	return 512.0  # fallback

func _shoot_arrow(direction: Vector2) -> void:
	if not is_archer:
		return

	var arrow = ARROW_SCENE.instantiate()
	if not arrow:
		_debug_print("[Enemy] 箭矢场景实例化失败")
		return

	var fly_dir: Vector2 = direction.normalized()
	fly_dir.y = 0.0
	fly_dir = fly_dir.normalized()

	var spawn_pos: Vector2 = global_position + fly_dir * 50.0 + Vector2(0, -10)
	arrow.global_position = spawn_pos
	if arrow.has_method("initialize"):
		var arrow_dir := Vector2(-1.0, 0.0) if facing_right else Vector2(1.0, 0.0)
		_debug_print("[Enemy射箭]" + get_name() + "facing_right=" + str(facing_right) + "→箭头方向=" + str(arrow_dir))
		arrow.initialize(arrow_dir, arrow_speed)
	else:
		var arrow_body: CharacterBody2D = arrow.get_node_or_null("CharacterBody2D")
		if arrow_body:
			var arrow_dir := Vector2(-1.0, 0.0) if facing_right else Vector2(1.0, 0.0)
			arrow_body.velocity = arrow_dir * arrow_speed

	get_parent().add_child(arrow)
	arrow.add_to_group("arrow")

func take_damage(amount: int) -> void:
	if is_dead:
		return

	health -= amount
	_debug_print("[Enemy] 被攻击！剩余生命：" + str(health) + " | 伤害：" + str(amount))

	is_acting = true
	velocity = Vector2.ZERO

	if health <= 0:
		die()
	else:
		_show_hurt_effect()
		_play_anim("hurt")

func die() -> void:
	is_dead = true
	is_acting = true
	velocity = Vector2.ZERO
	_debug_print("[Enemy] " + get_name() + " 死亡！")
	_play_anim("rip")
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _show_hurt_effect() -> void:
	$AnimatedSprite2D.modulate = Color(2.5, 2.5, 2.5)
	var tween := create_tween()
	tween.tween_property($AnimatedSprite2D, "modulate", Color.WHITE, 0.2)

func _play_anim(anim_name: String) -> void:
	var spr := $AnimatedSprite2D
	if not spr.sprite_frames:
		return
	if spr.sprite_frames.has_animation(anim_name) and spr.animation != anim_name:
		spr.play(anim_name)
	elif not spr.sprite_frames.has_animation(anim_name):
		pass

func _on_animation_finished() -> void:
	if is_dead:
		return
	var anim: StringName = $AnimatedSprite2D.animation
	if anim == "rip":
		is_acting = true
	elif anim == "hurt":
		is_acting = false
	elif anim.begins_with("attack"):
		is_acting = false