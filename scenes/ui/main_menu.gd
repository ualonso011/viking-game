extends CanvasLayer
## Main menu screen.

signal start_game()

## Font size as fraction of viewport height (Title)
const TITLE_SIZE_RATIO: float = 0.045
## Font size as fraction of viewport height (Subtitle)
const SUBTITLE_SIZE_RATIO: float = 0.022
## Font size as fraction of viewport height (Button)
const BUTTON_SIZE_RATIO: float = 0.022


func _ready() -> void:
	# Connect the start button — direct, no signal chain detour
	var btn = $VBoxContainer/StartButton
	if btn and btn.has_signal(&"pressed"):
		btn.pressed.connect(_on_start_pressed)
	else:
		push_error("MainMenu: StartButton not found or has no 'pressed' signal")

	# Scale fonts to viewport height
	var vp_height: float = get_viewport().get_visible_rect().size.y
	$VBoxContainer/TitleLabel.add_theme_font_size_override("font_size", max(16, int(vp_height * TITLE_SIZE_RATIO)))
	$VBoxContainer/SubtitleLabel.add_theme_font_size_override("font_size", max(12, int(vp_height * SUBTITLE_SIZE_RATIO)))
	$VBoxContainer/StartButton.add_theme_font_size_override("font_size", max(14, int(vp_height * BUTTON_SIZE_RATIO)))


func _on_start_pressed() -> void:
	start_game.emit()
