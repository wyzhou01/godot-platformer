

extends CharacterBody2D

# --- 核心数值 ---
@export var SPEED = 250.0
@export var DAMAGE_AMOUNT = 1
@export var health = 1

var is_attacking = false

@onready var anim = $AnimatedSprite2D
@onready var attack_area = $attackarea
@onready var attack_collision = $attackarea/CollisionShape2D

func _ready():
	# --- 自动插线逻辑：绕过所有编辑器手动操作 ---
	if not attack_area.body_entered.is_connected(_on_attack_logic):
		attack_area.body_entered.connect(_on_attack_logic)
	
	attack_collision.disabled = true
	add_to_group("player")

func _physics_process(_delta):
	if anim.animation == "death": return

	var direction = Input.get_axis("ui_left", "ui_right")
	
	if not is_attacking:
		if direction:
			velocity.x = direction * SPEED
			anim.play("run")
			anim.flip_h = direction < 0
			# 同时也让攻击区跟着转向，确保刀往前面砍
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
	
	# 帧同步：开启判定
	attack_collision.disabled = false
	
	await anim.animation_finished
	
	attack_collision.disabled = true
	is_attacking = false

# --- 核心伤害判定函数 ---
func _on_attack_logic(body):
	# 只要不是你自己，且对方有受击逻辑，就干它！
	if body != self and body.has_method("take_damage"):
		body.take_damage(DAMAGE_AMOUNT)
		print("Bro, 判定成功！逻辑抹除中...")
