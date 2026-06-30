extends Node2D
## Level_02_Exile: Burned forest.

@onready var player: Node = $Player
@onready var checkpoint: Area2D = $Checkpoint
@onready var end_trigger: Area2D = $EndTrigger
@onready var story_trigger: Area2D = $StoryTrigger
var story_played: bool = false


func _ready() -> void:
	if checkpoint:
		checkpoint.body_entered.connect(_on_checkpoint_entered)
	if end_trigger:
		end_trigger.body_entered.connect(_on_end_trigger_entered)
	if story_trigger:
		story_trigger.body_entered.connect(_on_story_trigger)

	var hud = get_node_or_null("/root/Main/HUD")
	if hud and hud.has_method("show_level_name"):
		hud.show_level_name("Exile", 3.0)

	if player:
		game_state.last_checkpoint = player.global_position
		game_state.checkpoint_level = "res://scenes/levels/level_02.tscn"


func _on_story_trigger(body: Node) -> void:
	if body.is_in_group("player") and not story_played:
		story_played = true
		cutscene.play_cutscene(narrative_db.exile_forest())


func _on_checkpoint_entered(body: Node) -> void:
	if body.is_in_group("player"):
		game_state.last_checkpoint = checkpoint.global_position
		game_state.current_hp = game_state.max_hp
		var hud = get_node_or_null("/root/Main/HUD")
		if hud and hud.has_method("show_checkpoint"):
			hud.show_checkpoint()


func _on_end_trigger_entered(body: Node) -> void:
	if body.is_in_group("player"):
		game_state.add_level_damage_bonus()
		game_state.current_level = 3
		var main = get_node_or_null("/root/Main")
		if main and main.has_method("load_level"):
			game_manager.load_level("res://scenes/levels/level_03.tscn")
