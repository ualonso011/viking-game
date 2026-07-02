extends CanvasLayer
## Credits panel: scrollable attribution text loaded from assets/audio/ATTRIBUTION.md.

const ATTRIBUTION_PATH := "res://assets/audio/ATTRIBUTION.md"

@onready var text_label: RichTextLabel = $Panel/MarginContainer/VBoxContainer/ScrollContainer/RichTextLabel


func _ready() -> void:
	theme = preload("res://assets/themes/viking_theme.tres")
	process_mode = PROCESS_MODE_ALWAYS
	visible = false

	_load_attribution()
	$Panel/MarginContainer/VBoxContainer/BackButton.pressed.connect(hide)


func _load_attribution() -> void:
	var file := FileAccess.open(ATTRIBUTION_PATH, FileAccess.READ)
	if file:
		text_label.text = file.get_as_text()
	else:
		text_label.text = "Créditos no disponibles."
