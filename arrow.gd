extends Area2D

# 存档点（箭头）
var is_activated: bool = false

@onready var sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	# 初始状态为未激活
	sprite.play("default")
	sprite.modulate = Color(1, 1, 1, 0.5) # 半透明表示未激活
	# 确保碰撞体启用
	if collision_shape:
		collision_shape.disabled = false
	# 连接信号
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if is_activated: return
	if not body.is_in_group("player"): return
	
	is_activated = true
	
	# 激活：全亮并闪烁
	sprite.modulate = Color(1, 1, 1, 1)
	
	# 闪烁动画
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.3, 0.3)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.3)
	tween.set_loops(3)
	
	# 保存 checkpoint 到 SceneManager
	if has_node("/root/SceneManager"):
		SceneManager.save_checkpoint(global_position, get_tree().current_scene.scene_file_path)
	
	# 显示提示文字
	_show_checkpoint_text()

func _show_checkpoint_text():
	var label = Label.new()
	label.text = "Checkpoint Saved!"
	label.modulate = Color(0.3, 1, 0.3, 1) # 绿色
	label.position = Vector2(0, -40)
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -30), 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0, 1.0)
	tween.tween_callback(label.queue_free)
