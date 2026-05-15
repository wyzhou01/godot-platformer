extends CanvasLayer

@onready var restart_button = $VBoxContainer/RestartButton
@onready var menu_button = $VBoxContainer/MenuButton

func _ready():
	# 入场淡入（延迟一点给玩家感受死亡）
	await get_tree().create_timer(0.5).timeout
	if has_node("/root/SceneManager"):
		SceneManager.fade_from_black(0.5)
	
	# 根据是否有存档显示重生按钮
	if not SceneManager.has_checkpoint:
		restart_button.disabled = true
		restart_button.modulate.a = 0.5
	else:
		restart_button.disabled = false
		restart_button.modulate.a = 1.0

func _on_restart_pressed():
	if has_node("/root/SceneManager"):
		SceneManager.restart_from_checkpoint()

func _on_menu_pressed():
	if has_node("/root/SceneManager"):
		SceneManager.goto_main_menu()
