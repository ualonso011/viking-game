extends Node
## Game manager singleton. Handles scene transitions, pause state.
## Always available — no tree navigation needed from other scripts.

enum GameState { MENU, PLAYING, CUTSCENE, PAUSED, GAME_OVER }

var current_state: GameState = GameState.MENU
var current_level = null


func _ready() -> void:
	# Apply runtime stretch mode (NOT in project.godot — breaks Docker CI)
	var win = get_window()
	if win:
		win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		win.content_scale_size = Vector2i(1920, 1080)

	# UI overlays live under Main; connect their signals once the scene loads.
	_call_when_main_ready(_connect_overlay_signals)


func _connect_overlay_signals() -> void:
	var main := get_tree().root.get_node_or_null("Main")
	if not main:
		return
	var pause_overlay := main.get_node_or_null("PauseOverlay")
	if pause_overlay and pause_overlay.has_signal("resume_requested"):
		pause_overlay.resume_requested.connect(_on_pause_resume)
	var game_over := main.get_node_or_null("GameOverScreen")
	if game_over and game_over.has_signal("retry_requested"):
		game_over.retry_requested.connect(_on_game_over_retry)


func _call_when_main_ready(callable: Callable) -> void:
	if get_tree().root.has_node("Main"):
		callable.call()
	else:
		get_tree().root.child_entered_tree.connect(func(node: Node):
			if node.name == "Main":
				callable.call()
		, CONNECT_ONE_SHOT)


func _unhandled_input(event) -> void:
	if event.is_action_pressed("ui_cancel"):
		if current_state == GameState.PLAYING:
			toggle_pause(true)
		elif current_state == GameState.PAUSED:
			toggle_pause(false)


func toggle_pause(paused: bool) -> void:
	var main := get_tree().root.get_node_or_null("Main")
	var overlay := main.get_node_or_null("PauseOverlay") if main else null
	if paused:
		current_state = GameState.PAUSED
		get_tree().paused = true
		if overlay:
			overlay.show()
	else:
		current_state = GameState.PLAYING
		get_tree().paused = false
		if overlay:
			overlay.hide()
		var options := main.get_node_or_null("OptionsPanel") if main else null
		if options:
			options.hide()


func start_game() -> void:
	var main := get_tree().root.get_node_or_null("Main")
	if main:
		_set_visible(main, "MainMenu", false)
		_set_visible(main, "HUD", true)
		_set_visible(main, "TouchControls", true)
		_set_visible(main, "PauseOverlay", false)
		_set_visible(main, "GameOverScreen", false)
		_set_visible(main, "OptionsPanel", false)
		_set_visible(main, "CreditsPanel", false)

	game_state.reset_for_level()
	current_state = GameState.PLAYING
	await load_level("res://scenes/levels/level_01.tscn")


func load_level(path: String) -> void:
	if current_level:
		current_level.queue_free()
		current_level = null

	# Fade out
	var main := get_tree().root.get_node_or_null("Main")
	var ap := main.get_node_or_null("AnimationPlayer") if main else null
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
		var hud := main.get_node_or_null("HUD") if main else null
		if hud and hud.has_method("show_level_name"):
			hud.show_level_name(level_name.capitalize())

		# Fade in
		if ap and ap.has_animation("fade_in"):
			ap.play("fade_in")
	else:
		push_error("Failed to load level: " + path)


func show_game_over() -> void:
	current_state = GameState.GAME_OVER
	get_tree().paused = true
	var main := get_tree().root.get_node_or_null("Main")
	if main:
		_set_visible(main, "GameOverScreen", true)
		_set_visible(main, "HUD", false)
		_set_visible(main, "TouchControls", false)
		_set_visible(main, "PauseOverlay", false)


func return_to_menu() -> void:
	# Reset game state and reload the main scene
	if current_level:
		current_level.queue_free()
		current_level = null

	game_state.reset()
	current_state = GameState.MENU
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func restart_level() -> void:
	current_state = GameState.PLAYING
	get_tree().paused = false
	var level_path := game_state.checkpoint_level
	if level_path == "":
		level_path = "res://scenes/levels/level_01.tscn"
	await load_level(level_path)


func _on_pause_resume() -> void:
	toggle_pause(false)


func _on_game_over_retry() -> void:
	current_state = GameState.PLAYING
	get_tree().paused = false
	var main := get_tree().root.get_node_or_null("Main")
	if main:
		_set_visible(main, "GameOverScreen", false)
		_set_visible(main, "HUD", true)
		_set_visible(main, "TouchControls", true)

	var level_path := game_state.checkpoint_level
	if level_path == "" or level_path == "res://scenes/levels/level_01.tscn":
		level_path = "res://scenes/levels/level_01.tscn"
	await load_level(level_path)


func _set_visible(parent: Node, path: String, val: bool) -> void:
	var node = parent.get_node_or_null(path)
	if node:
		node.visible = val
