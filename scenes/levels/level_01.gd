extends LevelBase
## Level_01_Farm: tutorial/intro level.

@onready var intro_trigger: Area2D = $IntroTrigger
var intro_played: bool = false


func _ready() -> void:
	level_name = "Farm"
	next_level_path = "res://scenes/levels/level_02.tscn"
	checkpoint_unlocks_fury = true
	super._ready()

	if intro_trigger:
		intro_trigger.body_entered.connect(_on_intro_trigger_entered)


func _on_intro_trigger_entered(body: Node) -> void:
	if body.is_in_group("player") and not intro_played:
		intro_played = true
		cutscene.play_cutscene(narrative_db.intro_farm())
