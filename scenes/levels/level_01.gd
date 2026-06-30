extends Node2D
## Level_01_Farm: tutorial/intro level.

@onready var player: Node = $Player
@onready var checkpoint: Area2D = $Checkpoint
@onready var end_trigger: Area2D = $EndTrigger
@onready var intro_trigger: Area2D = $IntroTrigger
var intro_played: bool = false


func _ready() -> void:
	if checkpoint:
		checkpoint.body_entered.connect(_on_checkpoint_entered)
	if end_trigger:
		end_trigger.body_entered.connect(_on_end_trigger_entered)
	if intro_trigger:
		intro_trigger.body_entered.connect(_on_intro_trigger_entered)

	var hud_node = get_node_or_null("/root/Main/HUD")
	if hud_node and hud_node.has_method("show_level_name"):
		hud_node.show_level_name("Farm", 3.0)

	if player:
		game_state.last_checkpoint = player.global_position
		game_state.checkpoint_level = "res://scenes/levels/level_01.tscn"


func _on_intro_trigger_entered(body: Node) -> void:
	if body.is_in_group("player") and not intro_played:
		intro_played = true
		cutscene.play_cutscene(narrative_db.intro_farm())


func _on_checkpoint_entered(body: Node) -> void:
	if body.is_in_group("player"):
		game_state.last_checkpoint = checkpoint.global_position
		game_state.current_hp = game_state.max_hp
		var hud_node = get_node_or_null("/root/Main/HUD")
		if hud_node and hud_node.has_method("show_checkpoint"):
			hud_node.show_checkpoint()
		if not game_state.fury_unlocked:
			game_state.fury_unlocked = true
			game_state.fury_unlocked_changed.emit()


func _on_end_trigger_entered(body: Node) -> void:
	if body.is_in_group("player"):
		game_state.add_level_damage_bonus()
		game_state.current_level = 2
		var main = get_node_or_null("/root/Main")
		if main and main.has_method("load_level"):
			game_manager.load_level("res://scenes/levels/level_02.tscn")
