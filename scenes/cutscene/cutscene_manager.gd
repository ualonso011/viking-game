extends CanvasLayer
## Cutscene manager (autoload): displays narrative text, portraits, backgrounds.
## Accessible globally as "cutscene".

signal cutscene_finished

const INPUT_DELAY: float = 0.3  # Prevents accidental skip
const PORTRAIT_PATH := "res://assets/sprites/portraits/%s.png"
const BACKGROUND_PATH := "res://assets/sprites/backgrounds/%s.png"

var is_active: bool = false
var dialogue_lines: Array[Dictionary] = []
var current_line: int = 0
var input_blocked: bool = false

@onready var background_layer: TextureRect = $BackgroundLayer
@onready var portrait_panel: Control = $PortraitPanel
@onready var portrait_texture: TextureRect = $PortraitPanel/PortraitTexture
@onready var speaker_label: Label = $PortraitPanel/SpeakerLabel
@onready var text_panel: Panel = $TextPanel
@onready var text_label: Label = $TextPanel/MarginContainer/Label
@onready var continue_hint: Label = $TextPanel/ContinueHint


func _ready() -> void:
	theme = preload("res://assets/themes/viking_theme.tres")
	text_panel.visible = false
	continue_hint.visible = false
	background_layer.visible = false
	portrait_panel.visible = false
	process_mode = PROCESS_MODE_WHEN_PAUSED


func play_cutscene(lines: Array[Dictionary], ambience_track: StringName = &"") -> void:
	"""Start a cutscene. lines: [{speaker, text, portrait?, background?}...]"""
	if is_active:
		return
	is_active = true
	dialogue_lines = lines
	current_line = 0
	input_blocked = true

	if ambience_track != "":
		audio_manager.play_ambience(ambience_track)

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

	# Portrait handling
	var portrait_key: String = line.get("portrait", "")
	if portrait_key != "":
		portrait_texture.texture = load(PORTRAIT_PATH % portrait_key)
		speaker_label.text = speaker
		portrait_panel.visible = true
	else:
		portrait_panel.visible = false

	# Background handling with cross-fade
	var background_key: String = line.get("background", "")
	if background_key != "":
		var new_bg := load(BACKGROUND_PATH % background_key) as Texture2D
		if new_bg and new_bg != background_layer.texture:
			var tween := create_tween()
			tween.tween_property(background_layer, "modulate:a", 0.0, 0.2)
			tween.tween_callback(func():
				background_layer.texture = new_bg
				background_layer.visible = true
			)
			tween.tween_property(background_layer, "modulate:a", 1.0, 0.3)
		elif new_bg:
			background_layer.visible = true

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
	portrait_panel.visible = false
	background_layer.visible = false
	get_tree().paused = false
	cutscene_finished.emit()
