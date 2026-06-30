extends CanvasLayer
## HUD overlay: health bar, fury cooldown, level name banner.

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var health_label: Label = $HealthBar/Label
@onready var fury_icon: TextureRect = $FuryIcon
@onready var fury_cooldown: TextureProgressBar = $FuryIcon/FuryCooldown
@onready var fury_label: Label = $FuryIcon/Label
@onready var level_name: Label = $LevelName
@onready var checkpoint_banner: Label = $CheckpointBanner

var level_name_timer: float = 0.0
var checkpoint_timer: float = 0.0
var _displayed_hp: float = 0.0


func _ready() -> void:
	_displayed_hp = game_state.current_hp
	level_name.modulate.a = 0.0
	checkpoint_banner.modulate.a = 0.0


func _process(delta: float) -> void:
	# Health bar (smooth lerp)
	var max_hp: int = game_state.max_hp
	var cur_hp: int = game_state.current_hp
	_displayed_hp = lerp(_displayed_hp, float(cur_hp), 1.0 - exp(-10.0 * delta))
	health_bar.max_value = max_hp
	health_bar.value = _displayed_hp
	health_label.text = str(cur_hp) + "/" + str(max_hp)

	# Fury cooldown
	if game_state.fury_unlocked:
		fury_icon.visible = true
		if game_state.fury_cooldown_timer > 0:
			var max_cd: float = 30.0
			fury_cooldown.value = game_state.fury_cooldown_timer
			fury_cooldown.max_value = max_cd
			fury_label.text = str(ceil(game_state.fury_cooldown_timer)) + "s"
			fury_icon.modulate = Color(0.5, 0.5, 0.5, 0.5)
		else:
			fury_cooldown.value = 0
			fury_label.text = ""
			fury_icon.modulate = Color(1, 1, 1, 1)
	else:
		fury_icon.visible = false

	# Level name fade
	if level_name_timer > 0:
		level_name_timer -= delta
		level_name.modulate.a = min(level_name_timer / 0.5, 1.0)
	else:
		level_name.modulate.a = 0.0

	# Checkpoint banner fade
	if checkpoint_timer > 0:
		checkpoint_timer -= delta
		checkpoint_banner.modulate.a = min(checkpoint_timer / 0.5, 1.0)
	else:
		checkpoint_banner.modulate.a = 0.0


func show_level_name(text: String, duration: float = 3.0) -> void:
	level_name.text = text
	level_name_timer = duration
	level_name.modulate.a = 1.0


func show_checkpoint() -> void:
	checkpoint_banner.text = "Checkpoint Saved!"
	checkpoint_timer = 2.0
	checkpoint_banner.modulate.a = 1.0
