extends Node
## Root game manager. Handles scene transitions, game states.

enum GameStateEnum { MENU, PLAYING, CUTSCENE, PAUSED }

var current_state: GameStateEnum = GameStateEnum.MENU

@onready var main_menu = $MainMenu
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var fade_rect: ColorRect = $FadeRect
var current_level: Node = null


func _ready() -> void:
	main_menu.visible = true
	$HUD.visible = false
	$TouchControls.visible = false

	var err := main_menu.start_game.connect(_on_start_game)
	if err != OK:
		push_error("main: failed to connect start_game signal: ", error_string(err))

	# Fade-in at start
	if animation_player.has_animation("fade_in"):
		animation_player.play("fade_in")


func _on_start_game() -> void:
	main_menu.visible = false
	$HUD.visible = true
	$TouchControls.visible = true
	current_state = GameStateEnum.PLAYING
	load_level("res://scenes/levels/level_01.tscn")


func load_level(path: String) -> void:
	# Remove previous level
	if current_level:
		current_level.queue_free()
		current_level = null

	# Fade out
	if animation_player.has_animation("fade_out"):
		animation_player.play("fade_out")
		await animation_player.animation_finished

	# Load new level
	var level_res: PackedScene = load(path)
	if level_res:
		current_level = level_res.instantiate()
		add_child(current_level)
		move_child(current_level, 0)  # Behind UI

		# Reset player state
		GameState.reset_for_level()

		# Show level name in HUD
		var level_name: String = path.get_file().trim_suffix(".tscn")
		$HUD.show_level_name(level_name.capitalize())

		# Fade in
		if animation_player.has_animation("fade_in"):
			animation_player.play("fade_in")
	else:
		push_error("Failed to load level: " + path)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if current_state == GameStateEnum.PLAYING:
			current_state = GameStateEnum.PAUSED
			get_tree().paused = true
		elif current_state == GameStateEnum.PAUSED:
			current_state = GameStateEnum.PLAYING
			get_tree().paused = false
