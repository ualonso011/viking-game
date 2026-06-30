extends Node
## UI container. Just holds child nodes — game logic is in GameManager singleton.

@onready var main_menu = $MainMenu
@onready var hud = $HUD
@onready var touch_controls = $TouchControls


func _ready() -> void:
	main_menu.visible = true
	hud.visible = false
	touch_controls.visible = false

	var ap = $AnimationPlayer
	if ap and ap.has_animation("fade_in"):
		ap.play("fade_in")
