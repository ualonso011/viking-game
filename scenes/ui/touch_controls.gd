extends CanvasLayer
## Touch control overlay for Android. Right-side action buttons.

@onready var btn_jump: TouchScreenButton = $RightControls/JumpBtn
@onready var btn_attack_light: TouchScreenButton = $RightControls/AttackLightBtn
@onready var btn_attack_heavy: TouchScreenButton = $RightControls/AttackHeavyBtn
@onready var btn_dash: TouchScreenButton = $RightControls/DashBtn
@onready var btn_fury: TouchScreenButton = $RightControls/FuryBtn


func _ready() -> void:
	# Wire TouchScreenButtons to Input actions
	btn_jump.action = "jump"
	btn_attack_light.action = "attack_light"
	btn_attack_heavy.action = "attack_heavy"
	btn_dash.action = "dash"
	btn_fury.action = "fury"

	# Hide fury button until unlocked
	btn_fury.visible = false
	GameState.fury_unlocked_changed.connect(_on_fury_unlocked)


func _process(_delta: float) -> void:
	# Show fury button once unlocked
	if GameState.fury_unlocked and not btn_fury.visible:
		btn_fury.visible = true


func _on_fury_unlocked() -> void:
	btn_fury.visible = true
