extends LevelBase
## Level_03_Cinders: Ruined village.

@onready var story_trigger: Area2D = $StoryTrigger
var story_played: bool = false


func _ready() -> void:
	level_name = "Cinders"
	next_level_path = "res://scenes/levels/level_04.tscn"
	super._ready()

	if story_trigger:
		story_trigger.body_entered.connect(_on_story_trigger)


func _on_story_trigger(body: Node) -> void:
	if body.is_in_group("player") and not story_played:
		story_played = true
		cutscene.play_cutscene(narrative_db.cinders_intro(), &"fire_crackle")
