extends CharacterBody2D

# ===== 调试开关 =====
const DEBUG = false
func _debug_print(msg):
	if DEBUG: print(msg)

# --- 核心数值 ---
@export var SPEED = 250.0
@export var DAMAGE_AMOUNT = 1
@export var health: int = 1

var is_attacking = false

@onready var anim = $AnimatedSprite2D
@onready var attack_area = $attackarea
@onready var attack_collision = $attackarea/CollisionShape2D

func _ready():
	if not attack_area.body_entered.is_connected(_on_attack_logic):
		attack_area.body_entered.connect(_on_attack_logic)

	attack_collision.disabled = true
	# 注意：不要把自己加进 "player" 组，boss 不是玩家

func _physics_process(_delta):
	if anim.animation == "death": return

	var direction = Input.get_axis("ui_left", "ui_right")

	if not is_attacking:
		if direction:
			velocity.x = direction * SPEED
			anim.play("run")
			anim.flip_h = direction < 0
			attack_area.scale.x = -1 if direction < 0 else 1
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			anim.play("idle")

	if Input.is_action_just_pressed("attack") and not is_attacking:
		execute_attack()

	move_and_slide()

func execute_attack():
	is_attacking = true
	anim.play("attack")

	attack_collision.disabled = false

	await anim.animation_finished

	attack_collision.disabled = true
	is_attacking = false

func _on_attack_logic(body):
	if body != self and body.has_method("take_damage"):
		body.take_damage(DAMAGE_AMOUNT)
		_debug_print("判定成功！逻辑抹除中...")