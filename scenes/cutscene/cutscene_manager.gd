extends CanvasLayer
## Cutscene manager (autoload): displays narrative text, blocks input.
## Accessible globally as "cutscene".

signal cutscene_finished

const INPUT_DELAY: float = 0.3  # Prevents accidental skip

var is_active: bool = false
var dialogue_lines: Array[Dictionary] = []
var current_line: int = 0
var input_blocked: bool = false

@onready var text_panel: Panel = $TextPanel
@onready var text_label: Label = $TextPanel/MarginContainer/Label
@onready var continue_hint: Label = $TextPanel/ContinueHint


func _ready() -> void:
	theme = preload("res://assets/themes/viking_theme.tres")
	text_panel.visible = false
	continue_hint.visible = false
	process_mode = PROCESS_MODE_WHEN_PAUSED


func play_cutscene(lines: Array[Dictionary]) -> void:
	"""Start a cutscene. lines: [{speaker: str, text: str}...]"""
	if is_active:
		return
	is_active = true
	dialogue_lines = lines
	current_line = 0
	input_blocked = true

	get_tree().paused = true
	_show_line()

	# Brief delay before accepting input
	await get_tree().create_timer(INPUT_DELAY, true, false, true).timeout
	input_blocked = false


func _show_line() -> void:
	if current_line >= dialogue_lines.size():
		_end_cutscene()
		return

	var line: Dictionary = dialogue_lines[current_line]
	var speaker: String = line.get("speaker", "")
	var text: String = line.get("text", "")

	if speaker != "":
		text_label.text = "[" + speaker + "]\n" + text
	else:
		text_label.text = text

	text_panel.visible = true
	continue_hint.visible = true


func _input(event: InputEvent) -> void:
	if not is_active or input_blocked:
		return
	if event.is_pressed() and not event.is_echo():
		current_line += 1
		_show_line()
		get_viewport().set_input_as_handled()


func _end_cutscene() -> void:
	is_active = false
	text_panel.visible = false
	continue_hint.visible = false
	get_tree().paused = false
	cutscene_finished.emit()
