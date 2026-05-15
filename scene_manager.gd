extends Node

# ===== SceneManager - 场景管理核心自动加载 =====

# 淡入淡出参数
var fade_overlay: ColorRect = null
var tween: Tween = null

# 存档数据
var checkpoint_position: Vector2 = Vector2.ZERO
var checkpoint_level_path: String = ""
var has_checkpoint: bool = false

# 关卡链顺序 (不含主菜单和 game over)
var level_chain: Array[String] = [
	"res://node_2d.tscn",
	"res://level3.tscn",
	"res://level。2.tscn",
	"res://level。3.tscn",
	"res://level4.tscn",
	"res://level。5.tscn",
	"res://level.6.tscn",
	"res://level。7.tscn",
]

func _ready():
	# 创建淡入淡出遮罩
	fade_overlay = ColorRect.new()
	fade_overlay.color = Color.BLACK
	fade_overlay.size = DisplayServer.window_get_size()
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_overlay.visible = false
	fade_overlay.z_index = 9999
	add_child(fade_overlay)

# ===== 淡入淡出核心 =====

func fade_to_black(duration := 0.8):
	fade_overlay.visible = true
	fade_overlay.color.a = 0.0
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, duration)
	await tween.finished

func fade_from_black(duration := 0.8):
	fade_overlay.visible = true
	fade_overlay.color.a = 1.0
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, duration)
	await tween.finished
	fade_overlay.visible = false

# ===== 关卡跳转 =====

func transition_to_scene(path: String):
	await fade_to_black()
	get_tree().change_scene_to_file(path)
	await fade_from_black()

func start_game():
	has_checkpoint = false
	checkpoint_level_path = ""
	transition_to_scene("res://node_2d.tscn")

func continue_game():
	if has_checkpoint and checkpoint_level_path != "":
		transition_to_scene(checkpoint_level_path)
	else:
		start_game()

func goto_next_level():
	var current_path = get_tree().current_scene.scene_file_path
	var idx = level_chain.find(current_path)
	if idx >= 0 and idx < level_chain.size() - 1:
		transition_to_scene(level_chain[idx + 1])
	else:
		# 最后一关 -> 回到主菜单
		goto_main_menu()

func goto_main_menu():
	transition_to_scene("res://ui/main_menu.tscn")

func goto_game_over():
	transition_to_scene("res://ui/game_over.tscn")

# ===== 存档点 =====

func save_checkpoint(pos: Vector2, level_path: String):
	checkpoint_position = pos
	checkpoint_level_path = level_path
	has_checkpoint = true

func restart_from_checkpoint():
	if has_checkpoint:
		await fade_to_black()
		get_tree().change_scene_to_file(checkpoint_level_path)
		# 等待场景加载完成后再设置玩家位置
		await get_tree().process_frame
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.global_position = checkpoint_position
			# 无敌帧保护
			if player.has_method("set_invincible"):
				player.set_invincible(true)
		await fade_from_black()

# ===== 死亡处理 =====

func on_player_died():
	await get_tree().create_timer(1.0).timeout
	if has_checkpoint and checkpoint_level_path != "":
		restart_from_checkpoint()
	else:
		goto_game_over()
