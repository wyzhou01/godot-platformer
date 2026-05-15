extends Area2D

@export var damage_amount = 9999
@export var cooldown_time: float = 0.5  # 冷却时间（秒），防止每帧扣血

@onready var cooldown_timer: Timer = Timer.new()
var can_damage: bool = true

func _ready():
	cooldown_timer.wait_time = cooldown_time
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooldown_done)
	add_child(cooldown_timer)

func _physics_process(_delta):
	if not can_damage:
		return

	var overlapping_bodies = get_overlapping_bodies()

	for body in overlapping_bodies:
		if body.has_method("take_damage"):
			body.take_damage(damage_amount)
			_trigger_cooldown()

func _trigger_cooldown():
	can_damage = false
	cooldown_timer.start()

func _on_cooldown_done():
	can_damage = true