extends LevelBase
## Level_07_FinalBoss: Ash-covered battlefield. Final tragedy.

@onready var boss: Node = $BossFinal
@onready var story_trigger: Area2D = $StoryTrigger
var story_played: bool = false
var ending_played: bool = false


func _ready() -> void:
	level_name = "The Ash Battlefield"
	next_level_path = ""
	checkpoint_upgrades_hp = true
	super._ready()

	if story_trigger:
		story_trigger.body_entered.connect(_on_story_trigger)
	if boss:
		boss.max_hp = 25
		boss.hp = 25
		boss.fast_atk_dmg = 2
		boss.heavy_atk_dmg = 3
		boss.set_physics_process(false)


func _on_story_trigger(body: Node) -> void:
	if body.is_in_group("player") and not story_played:
		story_played = true
		cutscene.play_cutscene(narrative_db.final_boss_intro())
		if boss:
			await cutscene.cutscene_finished
			boss.set_physics_process(true)


func _on_end_trigger_entered(body: Node) -> void:
	if not body.is_in_group("player") or ending_played:
		return
	# Boss must be dead to end
	if boss and boss.hp > 0:
		return
	ending_played = true
	cutscene.play_cutscene(narrative_db.final_boss_defeat())
	await cutscene.cutscene_finished
	await get_tree().create_timer(2.0).timeout
	game_state.reset()
	game_manager.return_to_menu()
