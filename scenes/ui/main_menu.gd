extends CanvasLayer
## Main menu screen. Calls GameManager.start_game() directly.

const TITLE_SIZE_RATIO: float = 0.045
const SUBTITLE_SIZE_RATIO: float = 0.022
const BUTTON_SIZE_RATIO: float = 0.022


func _ready() -> void:
	$VBoxContainer/StartButton.custom_minimum_size = Vector2(300, 60)
	_style_button($VBoxContainer/StartButton)
	$VBoxContainer/StartButton.button_down.connect(_on_start_pressed)
	$VBoxContainer/StartButton.button_up.connect(_on_start_pressed)

	var vp_height: float = get_viewport().get_visible_rect().size.y
	$VBoxContainer/TitleLabel.add_theme_font_size_override("font_size", max(16, int(vp_height * TITLE_SIZE_RATIO)))
	$VBoxContainer/SubtitleLabel.add_theme_font_size_override("font_size", max(12, int(vp_height * SUBTITLE_SIZE_RATIO)))
	$VBoxContainer/StartButton.add_theme_font_size_override("font_size", max(14, int(vp_height * BUTTON_SIZE_RATIO)))


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_on_start_pressed()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_start_pressed()


func _style_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.25, 0.18, 0.1, 0.7)
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_left = 6
	normal.corner_radius_bottom_right = 6
	normal.content_margin_left = 40
	normal.content_margin_right = 40
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12
	btn.add_theme_stylebox_override("normal", normal)

	var hovered := StyleBoxFlat.new()
	hovered.bg_color = Color(0.35, 0.25, 0.15, 0.85)
	hovered.corner_radius_top_left = 6
	hovered.corner_radius_top_right = 6
	hovered.corner_radius_bottom_left = 6
	hovered.corner_radius_bottom_right = 6
	hovered.content_margin_left = 40
	hovered.content_margin_right = 40
	hovered.content_margin_top = 12
	hovered.content_margin_bottom = 12
	btn.add_theme_stylebox_override("hover", hovered)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.5, 0.35, 0.2, 0.9)
	pressed.corner_radius_top_left = 6
	pressed.corner_radius_top_right = 6
	pressed.corner_radius_bottom_left = 6
	pressed.corner_radius_bottom_right = 6
	pressed.content_margin_left = 40
	pressed.content_margin_right = 40
	pressed.content_margin_top = 12
	pressed.content_margin_bottom = 12
	pressed.border_width_left = 2
	pressed.border_width_top = 2
	pressed.border_width_right = 2
	pressed.border_width_bottom = 2
	pressed.border_color = Color(0.7, 0.5, 0.3, 1.0)
	btn.add_theme_stylebox_override("pressed", pressed)


func _on_start_pressed() -> void:
	GameManager.start_game()
