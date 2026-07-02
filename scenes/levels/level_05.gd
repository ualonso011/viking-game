extends LevelBase
## Level_05_HalvardBoss: Jarl Halvard boss arena.

@onready var boss: Node = $BossHalvard
@onready var story_trigger: Area2D = $StoryTrigger
var story_played: bool = false


func _ready() -> void:
	level_name = "The Jarl's Hall"
	next_level_path = "res://scenes/levels/level_06.tscn"
	checkpoint_upgrades_hp = true
	super._ready()

	if story_trigger:
		story_trigger.body_entered.connect(_on_story_trigger)
	if boss:
		boss.set_physics_process(false)


func _on_story_trigger(body: Node) -> void:
	if body.is_in_group("player") and not story_played:
		story_played = true
		cutscene.play_cutscene(narrative_db.before_halvard())
		if boss and boss.has_method("set_physics_process"):
			await cutscene.cutscene_finished
			boss.set_physics_process(true)
