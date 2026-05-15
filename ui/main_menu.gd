extends CanvasLayer

@onready var start_button = $VBoxContainer/StartButton
@onready var continue_button = $VBoxContainer/ContinueButton

func _ready():
	# 入场淡入
	if has_node("/root/SceneManager"):
		SceneManager.fade_from_black()
	
	# 根据是否有存档显示继续按钮
	if not SceneManager.has_checkpoint:
		continue_button.disabled = true
		continue_button.modulate.a = 0.5
	else:
		continue_button.disabled = false
		continue_button.modulate.a = 1.0

func _on_start_pressed():
	if has_node("/root/SceneManager"):
		SceneManager.start_game()

func _on_continue_pressed():
	if has_node("/root/SceneManager"):
		SceneManager.continue_game()
