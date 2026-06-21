extends CanvasLayer
## Main menu screen.

signal start_game()

@onready var title_label: Label = $MenuContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $MenuContainer/VBoxContainer/SubtitleLabel
@onready var start_btn: Button = $MenuContainer/VBoxContainer/StartButton


func _ready() -> void:
	start_btn.pressed.connect(_on_start_pressed)


func _on_start_pressed() -> void:
	start_game.emit()
