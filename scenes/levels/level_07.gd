extends Node2D
## Level_07_FinalBoss: Ash-covered battlefield. Final tragedy.

@onready var player: Node = $Player
@onready var checkpoint: Area2D = $Checkpoint
@onready var end_trigger: Area2D = $EndTrigger
@onready var boss: Node = $BossFinal
@onready var story_trigger: Area2D = $StoryTrigger
var story_played: bool = false
var ending_played: bool = false


func _ready() -> void:
	if checkpoint:
		checkpoint.body_entered.connect(_on_checkpoint_entered)
	if end_trigger:
		end_trigger.body_entered.connect(_on_end_trigger_entered)
	if story_trigger:
		story_trigger.body_entered.connect(_on_story_trigger)

	var hud = get_node_or_null("/root/Main/HUD")
	if hud and hud.has_method("show_level_name"):
		hud.show_level_name("The Ash Battlefield", 3.0)

	if player:
		game_state.last_checkpoint = player.global_position
		game_state.checkpoint_level = "res://scenes/levels/level_07.tscn"

	# Boss is stronger for final fight; starts asleep
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


func _on_checkpoint_entered(body: Node) -> void:
	if body.is_in_group("player"):
		game_state.last_checkpoint = checkpoint.global_position
		game_state.current_hp = game_state.max_hp
		var hud = get_node_or_null("/root/Main/HUD")
		if hud and hud.has_method("show_checkpoint"):
			hud.show_checkpoint()
		game_state.upgrade_max_hp(1)


func _on_end_trigger_entered(body: Node) -> void:
	if body.is_in_group("player") and not ending_played:
		ending_played = true
		# Boss must be dead to end
		if boss and boss.hp > 0:
			return
		# Play tragic ending cutscene
		cutscene.play_cutscene(narrative_db.final_boss_defeat())
		await cutscene.cutscene_finished
		await get_tree().create_timer(2.0).timeout
		# Return to main menu via GameManager
		game_state.reset()
		game_manager.return_to_menu()
