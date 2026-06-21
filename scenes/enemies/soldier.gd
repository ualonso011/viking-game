extends CharacterBody2D
## Basic melee enemy with 3-state AI: idle → chase → attack.
## Uses VisibleOnScreenNotifier2D to save CPU when off-screen.

enum State { IDLE, CHASE, ATTACK, HURT, DEAD }

const SPEED: float = 80.0
const GRAVITY: float = 1200.0
const DETECTION_RANGE: float = 200.0
const ATTACK_RANGE: float = 35.0
const ATTACK_CD: float = 1.5
const KNOCKBACK_RESIST: float = 0.5
const AI_TICK_RATE: float = 0.3  # CPU saver: only think every 0.3s

var hp: int = 3
var state: State = State.IDLE
var player_ref: Node = null
var facing_right: bool = false
var is_on_screen: bool = true

var attack_cooldown: float = 0.0
var hurt_timer: float = 0.0
var ai_tick: float = 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D


func _ready() -> void:
	attack_collision.disabled = true
	detection.body_entered.connect(_on_detection_area_body_entered)
	detection.body_exited.connect(_on_detection_area_body_exited)
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	screen_notifier.screen_entered.connect(_on_screen_entered)
	screen_notifier.screen_exited.connect(_on_screen_exited)


func _on_screen_entered() -> void:
	is_on_screen = true
	set_physics_process(true)


func _on_screen_exited() -> void:
	is_on_screen = false
	# Stop processing when off-screen (save CPU on mobile)
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

	# Timers
	if attack_cooldown > 0:
		attack_cooldown -= delta
	if hurt_timer > 0:
		hurt_timer -= delta
		if hurt_timer <= 0 and state == State.HURT:
			state = State.IDLE

	# AI tick (performance: only think every AI_TICK_RATE seconds)
	ai_tick -= delta
	if ai_tick <= 0 and state not in [State.HURT, State.DEAD]:
		ai_tick = AI_TICK_RATE
		tick_ai()

	match state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
		State.CHASE:
			if player_ref and is_instance_valid(player_ref):
				var dir: float = sign(player_ref.global_position.x - global_position.x)
				facing_right = dir > 0
				velocity.x = move_toward(velocity.x, dir * SPEED, 400.0 * delta)
			else:
				player_ref = _find_player()
				if not player_ref:
					state = State.IDLE
		State.ATTACK:
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
		State.HURT:
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)

	move_and_slide()
	update_animation()


func tick_ai() -> void:
	if not player_ref or not is_instance_valid(player_ref):
		player_ref = _find_player()
		if not player_ref:
			state = State.IDLE
			return

	# Only chase if player is on screen too (performance)
	if not is_on_screen:
		state = State.IDLE
		return

	var dist: float = global_position.distance_to(player_ref.global_position)

	if state == State.IDLE and dist < DETECTION_RANGE:
		state = State.CHASE
	elif state == State.CHASE:
		if dist < ATTACK_RANGE and attack_cooldown <= 0:
			state = State.ATTACK
			attack_cooldown = ATTACK_CD
			_perform_attack()


func _perform_attack() -> void:
	attack_collision.disabled = false
	var tween := create_tween()
	tween.tween_callback(func(): attack_collision.disabled = true).set_delay(0.2)


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
	velocity = knockback_dir * 200.0 * KNOCKBACK_RESIST


func _die() -> void:
	set_physics_process(false)
	attack_collision.disabled = true
	# Disable collision so player can walk through
	$CollisionShape2D.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(queue_free)


func _find_player() -> Node:
	var players := get_tree().get_nodes_in_group("player")
	return players[0] if players.size() > 0 else null


func update_animation() -> void:
	match state:
		State.IDLE:
			anim.play("idle")
		State.CHASE:
			anim.play("run")
		State.ATTACK:
			anim.play("attack")
		State.HURT:
			anim.play("hurt")
		State.DEAD:
			anim.play("dead")

	anim.flip_h = not facing_right


func _on_detection_area_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_ref = body


func _on_detection_area_body_exited(_body: Node) -> void:
	pass


func _on_attack_area_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		var dir: Vector2 = Vector2.RIGHT if facing_right else Vector2.LEFT
		body.take_damage(1, dir)
