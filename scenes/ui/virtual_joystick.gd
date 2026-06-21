extends Control
## Virtual joystick for touch movement. Left-side d-pad.
## Emulates move_left / move_right Input actions.

signal moved(vector: Vector2)
signal released()

const MAX_RADIUS: float = 72.0
const DEADZONE: float = 0.15

var _touch_index: int = -1
var _output: Vector2 = Vector2.ZERO
var _is_pressed: bool = false

@onready var base: Sprite2D = $Base
@onready var knob: Sprite2D = $Knob


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _is_point_inside(event.position):
				_touch_index = event.index
				_is_pressed = true
				_update_knob(event.position)
		else:
			if event.index == _touch_index:
				_reset()

	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_knob(event.position)


func _is_point_inside(pos: Vector2) -> bool:
	var rect := Rect2(global_position - size / 2, size)
	return rect.has_point(pos)


func _update_knob(pos: Vector2) -> void:
	var relative: Vector2 = pos - global_position
	var len: float = relative.length()
	if len < DEADZONE * MAX_RADIUS:
		_output = Vector2.ZERO
		emit_signal("moved", _output)
		return

	var clamped: Vector2 = relative.limit_length(0.0, MAX_RADIUS)
	_output = clamped / MAX_RADIUS
	_output.y = 0.0  # Only horizontal movement

	knob.position = _output * MAX_RADIUS

	# Feed into Input actions
	_update_input_actions()
	emit_signal("moved", _output)


func _reset() -> void:
	_touch_index = -1
	_is_pressed = false
	_output = Vector2.ZERO
	knob.position = Vector2.ZERO
	_update_input_actions()
	emit_signal("released")


func _update_input_actions() -> void:
	# Simulate Input actions from the joystick output
	var input := Input.singleton
	if _output.x < -DEADZONE:
		input.parse_input_event(_make_action("move_left", true))
		input.parse_input_event(_make_action("move_right", false))
	elif _output.x > DEADZONE:
		input.parse_input_event(_make_action("move_right", true))
		input.parse_input_event(_make_action("move_left", false))
	else:
		input.parse_input_event(_make_action("move_left", false))
		input.parse_input_event(_make_action("move_right", false))


static func _make_action(action: String, pressed: bool) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	return ev
