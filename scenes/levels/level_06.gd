extends Node2D
## Level_06_EnglandInvasion: Siege the English castle.

@onready var player: Node = $Player
@onready var checkpoint: Area2D = $Checkpoint
@onready var end_trigger: Area2D = $EndTrigger


func _ready() -> void:
	if checkpoint:
		checkpoint.body_entered.connect(_on_checkpoint_entered)
	if end_trigger:
		end_trigger.body_entered.connect(_on_end_trigger_entered)

	var hud = get_node_or_null("/root/Main/HUD")
	if hud and hud.has_method("show_level_name"):
		hud.show_level_name("England Invasion", 3.0)

	if player:
		GameState.last_checkpoint = player.global_position
		GameState.checkpoint_level = "res://scenes/levels/level_06.tscn"


func _on_checkpoint_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameState.last_checkpoint = checkpoint.global_position
		GameState.current_hp = GameState.max_hp
		var hud = get_node_or_null("/root/Main/HUD")
		if hud and hud.has_method("show_checkpoint"):
			hud.show_checkpoint()


func _on_end_trigger_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameState.add_level_damage_bonus()
		GameState.current_level = 7
		GameState.upgrade_max_hp(1)
		var main = get_node_or_null("/root/Main")
		if main and main.has_method("load_level"):
			main.load_level("res://scenes/levels/level_07.tscn")
