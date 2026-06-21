extends CharacterBody2D
## Boss enemy with 3-phase AI. Used for Halvard and Final Boss.
## Uses VisibleOnScreenNotifier2D to save CPU when off-screen.

enum State { IDLE, CHASE, ATTACK_FAST, ATTACK_HEAVY, PAUSE, HURT, DEAD }

const SPEED: float = 60.0
const GRAVITY: float = 1200.0
const DETECTION_RANGE: float = 300.0
const ATTACK_RANGE: float = 50.0
const AI_TICK_RATE: float = 0.5

var max_hp: int = 15
var hp: int
var phase: int = 1
var state: State = State.IDLE
var player_ref: Node = null
var facing_right: bool = true
var is_on_screen: bool = true

var attack_cooldown: float = 0.0
var hurt_timer: float = 0.0
var ai_tick: float = 0.0
var pause_timer: float = 0.0
var enraged: bool = false

var fast_atk_dmg: int = 1
var heavy_atk_dmg: int = 2
var fast_atk_cd: float = 1.5
var heavy_atk_cd: float = 3.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var heavy_attack_area: Area2D = $HeavyAttackArea
@onready var heavy_collision: CollisionShape2D = $HeavyAttackArea/CollisionShape2D
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D


func _ready() -> void:
	hp = max_hp
	attack_collision.disabled = true
	heavy_collision.disabled = true
	detection.body_entered.connect(_on_detection_area_body_entered)
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	heavy_attack_area.body_entered.connect(_on_heavy_attack_area_body_entered)
	screen_notifier.screen_entered.connect(_on_screen_entered)
	screen_notifier.screen_exited.connect(_on_screen_exited)


func _on_screen_entered() -> void:
	is_on_screen = true
	set_physics_process(true)


func _on_screen_exited() -> void:
	is_on_screen = false
	state = State.IDLE
	velocity = Vector2.ZERO
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		velocity.y += GRAVITY * delta
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if attack_cooldown > 0:
		attack_cooldown -= delta
	if hurt_timer > 0:
		hurt_timer -= delta
		if hurt_timer <= 0 and state == State.HURT:
			state = State.IDLE

	ai_tick -= delta
	if ai_tick <= 0 and state not in [State.HURT, State.DEAD]:
		ai_tick = AI_TICK_RATE
		tick_ai()

	if state == State.PAUSE:
		pause_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
		if pause_timer <= 0:
			state = State.IDLE

	move_and_slide()
	update_animation()


func tick_ai() -> void:
	if not player_ref or not is_instance_valid(player_ref):
		player_ref = _find_player()
		if not player_ref or not is_on_screen:
			state = State.IDLE
			return

	var dist: float = global_position.distance_to(player_ref.global_position)
	_update_phase()

	if state == State.IDLE and dist < DETECTION_RANGE:
		state = State.CHASE

	match state:
		State.CHASE:
			if dist < ATTACK_RANGE and attack_cooldown <= 0:
				_choose_attack()
			elif dist < DETECTION_RANGE:
				var dir: float = sign(player_ref.global_position.x - global_position.x)
				facing_right = dir > 0
				velocity.x += dir * SPEED * 0.5

	if state in [State.IDLE, State.CHASE]:
		var dir: float = sign(player_ref.global_position.x - global_position.x) if player_ref else 1.0
		facing_right = dir > 0
		velocity.x = dir * SPEED * (1.3 if enraged else 1.0)


func _update_phase() -> void:
	var hp_pct: float = float(hp) / float(max_hp)
	if hp_pct <= 0.33:
		phase = 3
		enraged = true
		fast_atk_dmg = 2
		heavy_atk_dmg = 3
		fast_atk_cd = 1.0
		heavy_atk_cd = 2.0
	elif hp_pct <= 0.66:
		phase = 2
		fast_atk_dmg = 1
		heavy_atk_dmg = 2
		fast_atk_cd = 1.5
		heavy_atk_cd = 3.0
	else:
		phase = 1
		fast_atk_dmg = 1
		heavy_atk_dmg = 2
		fast_atk_cd = 2.0


func _choose_attack() -> void:
	if phase == 3 or phase == 2 or randf() < 0.6:
		_perform_fast_attack()
	else:
		_perform_heavy_attack()


func _perform_fast_attack() -> void:
	state = State.ATTACK_FAST
	attack_cooldown = fast_atk_cd
	attack_collision.disabled = false
	var tween := create_tween()
	tween.tween_interval(0.3)
	tween.tween_callback(func():
		attack_collision.disabled = true
		state = State.IDLE
	)


func _perform_heavy_attack() -> void:
	state = State.ATTACK_HEAVY
	attack_cooldown = heavy_atk_cd
	heavy_collision.disabled = false
	var tween := create_tween()
	tween.tween_interval(0.6)
	tween.tween_callback(func():
		heavy_collision.disabled = true
		state = State.PAUSE
		pause_timer = 1.0
	)


func take_damage(amount: int, knockback_dir: Vector2) -> void:
	if state == State.DEAD:
		return
	hp -= amount
	if hp <= 0:
		state = State.DEAD
		_die()
		return
	state = State.HURT
	hurt_timer = 0.3
	velocity = knockback_dir * 100.0


func _die() -> void:
	set_physics_process(false)
	attack_collision.disabled = true
	heavy_collision.disabled = true
	$CollisionShape2D.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_callback(queue_free)


func _find_player() -> Node:
	var players := get_tree().get_nodes_in_group("player")
	return players[0] if players.size() > 0 else null


func update_animation() -> void:
	var anim_name: String = "idle"
	match state:
		State.IDLE: anim_name = "idle"
		State.CHASE: anim_name = "run"
		State.ATTACK_FAST: anim_name = "attack_fast"
		State.ATTACK_HEAVY: anim_name = "attack_heavy"
		State.HURT: anim_name = "hurt"
		State.DEAD: anim_name = "dead"

	if enraged and anim_name in ["idle", "run"]:
		anim_name = "enraged_" + anim_name

	anim.play(anim_name)
	anim.flip_h = not facing_right


func _on_detection_area_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_ref = body


func _on_attack_area_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		var dir: Vector2 = Vector2.RIGHT if facing_right else Vector2.LEFT
		body.take_damage(fast_atk_dmg, dir)


func _on_heavy_attack_area_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		var dir: Vector2 = Vector2.RIGHT if facing_right else Vector2.LEFT
		body.take_damage(heavy_atk_dmg, dir * 2.0)
