extends Node2D
## Level_05_HalvardBoss: Jarl Halvard boss arena.

@onready var player: Node = $Player
@onready var checkpoint: Area2D = $Checkpoint
@onready var end_trigger: Area2D = $EndTrigger
@onready var boss: Node = $BossHalvard
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
		hud.show_level_name("The Jarl's Hall", 3.0)

	if player:
		GameState.last_checkpoint = player.global_position
		GameState.checkpoint_level = "res://scenes/levels/level_05.tscn"

	# Boss starts asleep; awakened after cutscene
	if boss:
		boss.set_physics_process(false)


func _on_story_trigger(body: Node) -> void:
	if body.is_in_group("player") and not story_played:
		story_played = true
		cutscene.play_cutscene(NarrativeDB.before_halvard())
		# Give player a moment after cutscene before boss aggros
		if boss and boss.has_method("set_physics_process"):
			await cutscene.cutscene_finished
			boss.set_physics_process(true)


func _on_checkpoint_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameState.last_checkpoint = checkpoint.global_position
		GameState.current_hp = GameState.max_hp
		var hud = get_node_or_null("/root/Main/HUD")
		if hud and hud.has_method("show_checkpoint"):
			hud.show_checkpoint()
		GameState.upgrade_max_hp(1)


func _on_end_trigger_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameState.add_level_damage_bonus()
		GameState.current_level = 6
		var main = get_node_or_null("/root/Main")
		if main and main.has_method("load_level"):
			main.load_level("res://scenes/levels/level_06.tscn")
