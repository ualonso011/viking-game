extends Node
## Persistent cross-level game state (singleton).

signal fury_unlocked_changed

var current_level: int = 1
var max_hp: int = 3
var current_hp: int = 3
var base_damage: float = 1.0
var fury_unlocked: bool = false
var fury_active: bool = false
var fury_cooldown_timer: float = 0.0
var last_checkpoint: Vector2 = Vector2.ZERO
var checkpoint_level: String = ""


func reset_for_level() -> void:
	current_hp = max_hp
	fury_active = false


func take_damage(amount: int) -> void:
	current_hp = maxi(current_hp - amount, 0)


func heal(amount: int = 0) -> void:
	if amount <= 0:
		current_hp = max_hp
	else:
		current_hp = mini(current_hp + amount, max_hp)


func upgrade_max_hp(amount: int = 1) -> void:
	max_hp += amount
	current_hp = max_hp


func get_damage() -> float:
	if fury_active:
		return base_damage * 1.5
	return base_damage


func add_level_damage_bonus() -> void:
	base_damage += 0.5


func _set_fury_unlocked(value: bool) -> void:
	if fury_unlocked != value:
		fury_unlocked = value
		fury_unlocked_changed.emit()

func reset() -> void:
	current_level = 1
	max_hp = 3
	current_hp = 3
	base_damage = 1.0
	fury_unlocked = false
	fury_cooldown_timer = 0.0
	last_checkpoint = Vector2.ZERO
	checkpoint_level = ""
