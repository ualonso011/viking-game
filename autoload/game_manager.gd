extends Node
## Game manager singleton. Handles scene transitions, pause state.
## Always available — no tree navigation needed from other scripts.

enum GameState { MENU, PLAYING, CUTSCENE, PAUSED }

var current_state: GameState = GameState.MENU
var current_level = null


func _ready() -> void:
	# Apply runtime stretch mode (NOT in project.godot — breaks Docker CI)
	var win = get_window()
	if win:
		win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		win.content_scale_size = Vector2i(1920, 1080)


func _unhandled_input(event) -> void:
	if event.is_action_pressed("ui_cancel"):
		if current_state == GameState.PLAYING:
			current_state = GameState.PAUSED
			get_tree().paused = true
		elif current_state == GameState.PAUSED:
			current_state = GameState.PLAYING
			get_tree().paused = false


func start_game() -> void:
	var main = get_tree().root.get_node_or_null("Main")
	if main:
		_set_visible(main, "MainMenu", false)
		_set_visible(main, "HUD", true)
		_set_visible(main, "TouchControls", true)

	game_state.reset_for_level()
	current_state = GameState.PLAYING
	await load_level("res://scenes/levels/level_01.tscn")


func load_level(path: String) -> void:
	if current_level:
		current_level.queue_free()
		current_level = null

	# Fade out
	var main = get_tree().root.get_node_or_null("Main")
	var ap = main.get_node_or_null("AnimationPlayer") if main else null
	if ap and ap.has_animation("fade_out"):
		ap.play("fade_out")
		await ap.animation_finished

	var level_res = load(path)
	if level_res:
		current_level = level_res.instantiate()
		get_tree().root.add_child(current_level)
		get_tree().root.move_child(current_level, 0)

		game_state.reset_for_level()

		var level_name = path.get_file().trim_suffix(".tscn")
		var hud = main.get_node_or_null("HUD") if main else null
		if hud and hud.has_method("show_level_name"):
			hud.show_level_name(level_name.capitalize())

		# Fade in
		if ap and ap.has_animation("fade_in"):
			ap.play("fade_in")
	else:
		push_error("Failed to load level: " + path)


func _set_visible(parent: Node, path: String, val: bool) -> void:
	var node = parent.get_node_or_null(path)
	if node:
		node.visible = val


func return_to_menu() -> void:
	# Reset game state and reload the main scene
	if current_level:
		current_level.queue_free()
		current_level = null

	game_state.reset()
	current_state = GameState.MENU
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")
