extends CanvasLayer
## Touch control overlay for Android. Right-side action buttons.

@onready var btn_jump: TouchScreenButton = $RightControls/JumpBtn
@onready var btn_attack_light: TouchScreenButton = $RightControls/AttackLightBtn
@onready var btn_attack_heavy: TouchScreenButton = $RightControls/AttackHeavyBtn
@onready var btn_dash: TouchScreenButton = $RightControls/DashBtn
@onready var btn_fury: TouchScreenButton = $RightControls/FuryBtn
@onready var btn_left = $LeftControls/LeftBtn
@onready var btn_right = $LeftControls/RightBtn


func _ready() -> void:
	theme = preload("res://assets/themes/viking_theme.tres")

	# Wire TouchScreenButtons to Input actions
	btn_jump.action = "jump"
	btn_attack_light.action = "attack_light"
	btn_attack_heavy.action = "attack_heavy"
	btn_dash.action = "dash"
	btn_fury.action = "fury"

	# Assign CircleShape2D shapes for touch detection
	# Right-side action buttons: radius 80px
	var right_shape = CircleShape2D.new()
	right_shape.radius = 80
	btn_jump.shape = right_shape
	btn_attack_light.shape = right_shape
	btn_attack_heavy.shape = right_shape
	btn_dash.shape = right_shape
	btn_fury.shape = right_shape

	# Left-side movement buttons: radius 60px
	var left_shape = CircleShape2D.new()
	left_shape.radius = 60
	btn_left.shape = left_shape
	btn_right.shape = left_shape

	# Hide fury button until unlocked
	btn_fury.visible = false
	game_state.fury_unlocked_changed.connect(_on_fury_unlocked)


func _process(_delta: float) -> void:
	# Show fury button once unlocked
	if game_state.fury_unlocked and not btn_fury.visible:
		btn_fury.visible = true


func _on_fury_unlocked() -> void:
	btn_fury.visible = true
