extends CanvasLayer
## Game-over screen: retry from checkpoint or return to main menu.
## process_mode=ALWAYS so it stays active while the tree is paused.

signal retry_requested


func _ready() -> void:
	theme = preload("res://assets/themes/viking_theme.tres")
	process_mode = PROCESS_MODE_ALWAYS
	visible = false

	$Panel/MarginContainer/VBoxContainer/RetryButton.pressed.connect(_on_retry)
	$Panel/MarginContainer/VBoxContainer/MainMenuButton.pressed.connect(_on_main_menu)


func _on_retry() -> void:
	hide()
	retry_requested.emit()


func _on_main_menu() -> void:
	hide()
	game_manager.return_to_menu()
