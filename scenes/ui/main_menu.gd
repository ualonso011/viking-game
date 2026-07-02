extends CanvasLayer
## Main menu screen. Calls game_manager.start_game() directly.

const TITLE_SIZE_RATIO: float = 0.045
const SUBTITLE_SIZE_RATIO: float = 0.022
const BUTTON_SIZE_RATIO: float = 0.022


func _ready() -> void:
	theme = preload("res://assets/themes/viking_theme.tres")

	$VBoxContainer/StartButton.custom_minimum_size = Vector2(300, 60)
	$VBoxContainer/StartButton.button_down.connect(_on_start_pressed)
	$VBoxContainer/StartButton.button_up.connect(_on_start_pressed)

	var vp_height: float = get_viewport().get_visible_rect().size.y
	$VBoxContainer/TitleLabel.add_theme_font_size_override("font_size", max(16, int(vp_height * TITLE_SIZE_RATIO)))
	$VBoxContainer/SubtitleLabel.add_theme_font_size_override("font_size", max(12, int(vp_height * SUBTITLE_SIZE_RATIO)))
	$VBoxContainer/StartButton.add_theme_font_size_override("font_size", max(14, int(vp_height * BUTTON_SIZE_RATIO)))

	# Title fade-in tween (0.6s)
	$VBoxContainer/TitleLabel.modulate.a = 0.0
	$VBoxContainer/SubtitleLabel.modulate.a = 0.0
	var title_tween = create_tween()
	title_tween.set_parallel(true)
	title_tween.tween_property($VBoxContainer/TitleLabel, "modulate:a", 1.0, 0.6)
	title_tween.tween_property($VBoxContainer/SubtitleLabel, "modulate:a", 1.0, 0.6).set_delay(0.2)

	# Button hover glow
	$VBoxContainer/StartButton.mouse_entered.connect(_on_button_hover)
	$VBoxContainer/StartButton.mouse_exited.connect(_on_button_hover_end)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_on_start_pressed()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_start_pressed()


func _on_button_hover() -> void:
	var btn = $VBoxContainer/StartButton
	var hover_tween = create_tween()
	hover_tween.tween_property(btn, "self_modulate", Color(1.0, 0.8, 0.5, 1.0), 0.15)


func _on_button_hover_end() -> void:
	var btn = $VBoxContainer/StartButton
	var hover_tween = create_tween()
	hover_tween.tween_property(btn, "self_modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)


func _on_start_pressed() -> void:
	game_manager.start_game()
