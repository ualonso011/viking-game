extends Node
## Root game manager. Handles scene transitions, game states.
## NO type hints — some break Godot 4.3 Android export.

enum GameStateEnum { MENU, PLAYING, CUTSCENE, PAUSED }

var current_state = GameStateEnum.MENU

@onready var main_menu = $MainMenu
@onready var animation_player = $AnimationPlayer
@onready var fade_rect = $FadeRect
var current_level = null


func _ready() -> void:
	add_to_group("game_manager")

	main_menu.visible = true
	$HUD.visible = false
	$TouchControls.visible = false

	if animation_player.has_animation("fade_in"):
		animation_player.play("fade_in")


func _on_start_game() -> void:
	if main_menu:
		main_menu.visible = false
	if $HUD:
		$HUD.visible = true
	if $TouchControls:
		$TouchControls.visible = true
	current_state = GameStateEnum.PLAYING
	load_level("res://scenes/levels/level_01.tscn")


func load_level(path) -> void:
	if current_level:
		current_level.queue_free()
		current_level = null

	if animation_player and animation_player.has_animation("fade_out"):
		animation_player.play("fade_out")
		await animation_player.animation_finished

	var level_res = load(path)
	if level_res:
		current_level = level_res.instantiate()
		add_child(current_level)
		move_child(current_level, 0)

		GameState.reset_for_level()

		var level_name = path.get_file().trim_suffix(".tscn")
		if $HUD and $HUD.has_method("show_level_name"):
			$HUD.show_level_name(level_name.capitalize())

		if animation_player and animation_player.has_animation("fade_in"):
			animation_player.play("fade_in")
	else:
		push_error("Failed to load level: " + path)


func _unhandled_input(event) -> void:
	if event.is_action_pressed("ui_cancel"):
		if current_state == GameStateEnum.PLAYING:
			current_state = GameStateEnum.PAUSED
			get_tree().paused = true
		elif current_state == GameStateEnum.PAUSED:
			current_state = GameStateEnum.PLAYING
			get_tree().paused = false
