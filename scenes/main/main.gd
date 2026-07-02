extends Node
## UI container. Just holds child nodes — game logic is in GameManager singleton.

@onready var main_menu = $MainMenu
@onready var hud = $HUD
@onready var touch_controls = $TouchControls
@onready var options_panel = $OptionsPanel
@onready var credits_panel = $CreditsPanel
@onready var pause_overlay = $PauseOverlay
@onready var game_over_screen = $GameOverScreen


func _ready() -> void:
	main_menu.visible = true
	hud.visible = false
	touch_controls.visible = false
	options_panel.visible = false
	credits_panel.visible = false
	pause_overlay.visible = false
	game_over_screen.visible = false

	var ap = $AnimationPlayer
	if ap and ap.has_animation("fade_in"):
		ap.play("fade_in")
