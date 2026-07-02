extends LevelBase
## Level_04_Warpath: Snowy mountains + fort approach.

@onready var story_trigger: Area2D = $StoryTrigger
var story_played: bool = false


func _ready() -> void:
	level_name = "Warpath"
	next_level_path = "res://scenes/levels/level_05.tscn"
	checkpoint_upgrades_hp = true
	super._ready()

	if story_trigger:
		story_trigger.body_entered.connect(_on_story_trigger)


func _on_story_trigger(body: Node) -> void:
	if body.is_in_group("player") and not story_played:
		story_played = true
		cutscene.play_cutscene(narrative_db.warpath_intro(), &"wind")
