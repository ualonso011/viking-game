extends CanvasLayer
## Main menu screen. Calls game_manager.start_game() directly.

const TITLE_SIZE_RATIO: float = 0.045
const SUBTITLE_SIZE_RATIO: float = 0.022
const BUTTON_SIZE_RATIO: float = 0.022


func _ready() -> void:
	theme = preload("res://assets/themes/viking_theme.tres")

	var vp_height: float = get_viewport().get_visible_rect().size.y
	$VBoxContainer/TitleLabel.add_theme_font_size_override("font_size", max(16, int(vp_height * TITLE_SIZE_RATIO)))
	$VBoxContainer/SubtitleLabel.add_theme_font_size_override("font_size", max(12, int(vp_height * SUBTITLE_SIZE_RATIO)))

	for btn in $VBoxContainer.get_children():
		if btn is Button:
			btn.custom_minimum_size = Vector2(300, 60)
			btn.add_theme_font_size_override("font_size", max(14, int(vp_height * BUTTON_SIZE_RATIO)))

	$VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	$VBoxContainer/OptionsButton.pressed.connect(_on_options_pressed)
	$VBoxContainer/CreditsButton.pressed.connect(_on_credits_pressed)
	$VBoxContainer/ExitButton.pressed.connect(_on_exit_pressed)

	# Title fade-in tween (0.6s)
	$VBoxContainer/TitleLabel.modulate.a = 0.0
	$VBoxContainer/SubtitleLabel.modulate.a = 0.0
	var title_tween = create_tween()
	title_tween.set_parallel(true)
	title_tween.tween_property($VBoxContainer/TitleLabel, "modulate:a", 1.0, 0.6)
	title_tween.tween_property($VBoxContainer/SubtitleLabel, "modulate:a", 1.0, 0.6).set_delay(0.2)


func _on_start_pressed() -> void:
	game_manager.start_game()


func _on_options_pressed() -> void:
	var options := get_node_or_null("/root/Main/OptionsPanel")
	if options:
		options.show()


func _on_credits_pressed() -> void:
	var credits := get_node_or_null("/root/Main/CreditsPanel")
	if credits:
		credits.show()


func _on_exit_pressed() -> void:
	get_tree().quit()
