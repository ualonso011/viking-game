extends CanvasLayer
## Pause overlay: resume, options, return to main menu.
## process_mode=ALWAYS so it responds while the tree is paused.

signal resume_requested

@onready var options_panel: CanvasLayer = get_node_or_null("/root/Main/OptionsPanel")


func _ready() -> void:
	theme = preload("res://assets/themes/viking_theme.tres")
	process_mode = PROCESS_MODE_ALWAYS
	visible = false

	$Panel/MarginContainer/VBoxContainer/ResumeButton.pressed.connect(_on_resume)
	$Panel/MarginContainer/VBoxContainer/OptionsButton.pressed.connect(_on_options)
	$Panel/MarginContainer/VBoxContainer/MainMenuButton.pressed.connect(_on_main_menu)


func _on_resume() -> void:
	hide()
	resume_requested.emit()


func _on_options() -> void:
	if options_panel:
		options_panel.show()


func _on_main_menu() -> void:
	hide()
	game_manager.return_to_menu()
