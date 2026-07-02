class_name LevelBase
extends Node2D
## Base class for all levels. Handles checkpoint, end trigger, HUD banner,
## fury unlock, and HP upgrade. Subclasses override for story triggers/bosses.

@onready var player: Node = $Player
@onready var checkpoint: Area2D = $Checkpoint
@onready var end_trigger: Area2D = $EndTrigger

@export var level_name: String = "Level"
@export var next_level_path: String = ""
@export var checkpoint_unlocks_fury: bool = false
@export var checkpoint_upgrades_hp: bool = false


func _ready() -> void:
	_wire_signals()
	_set_initial_checkpoint()
	_show_level_name()


func _wire_signals() -> void:
	if checkpoint:
		checkpoint.body_entered.connect(_on_checkpoint_entered)
	if end_trigger:
		end_trigger.body_entered.connect(_on_end_trigger_entered)


func _set_initial_checkpoint() -> void:
	if player:
		game_state.last_checkpoint = player.global_position
		game_state.checkpoint_level = scene_file_path


func _show_level_name() -> void:
	var hud := get_node_or_null("/root/Main/HUD")
	if hud and hud.has_method("show_level_name"):
		hud.show_level_name(level_name, 3.0)


func _on_checkpoint_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	game_state.last_checkpoint = checkpoint.global_position
	game_state.current_hp = game_state.max_hp
	var hud := get_node_or_null("/root/Main/HUD")
	if hud and hud.has_method("show_checkpoint"):
		hud.show_checkpoint()
	if checkpoint_unlocks_fury and not game_state.fury_unlocked:
		game_state.fury_unlocked = true
	if checkpoint_upgrades_hp:
		game_state.upgrade_max_hp(1)


func _on_end_trigger_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	game_state.add_level_damage_bonus()
	if next_level_path != "":
		game_manager.load_level(next_level_path)
