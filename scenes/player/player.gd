extends CharacterBody2D
## Player controller for Einar, the Ash Bear.
## Flat state machine with 5 mechanics: move, jump, light/heavy attack, dash.

enum State { IDLE, RUN, JUMP, FALL, ATTACK_LIGHT, ATTACK_HEAVY, DASH, HURT, DEAD }

# Movement
const SPEED: float = 200.0
const ACCEL: float = 1200.0
const FRICTION: float = 1800.0
const JUMP_VEL: float = -420.0
const JUMP_CUT_MULT: float = 0.5
const GRAVITY: float = 1200.0

# Combat
const LIGHT_ATK_DMG: int = 1
const LIGHT_ATK_CD: float = 0.3
const LIGHT_ATK_DURATION: float = 0.2
const HEAVY_ATK_DMG: int = 2
const HEAVY_ATK_CD: float = 0.8
const HEAVY_ATK_DURATION: float = 0.35
const KNOCKBACK_FORCE: float = 300.0

# Dash
const DASH_SPEED: float = 800.0
const DASH_DURATION: float = 0.3
const DASH_CD: float = 1.0

# Fury (Furia del Oso)
const FURY_DURATION: float = 5.0
const FURY_CD: float = 30.0
const FURY_DMG_MULT: float = 1.5

# Health
const INVULN_TIME: float = 1.0
const HURT_DURATION: float = 0.4

var state: State = State.IDLE
var facing_right: bool = true
var was_on_floor: bool = false

# Death-respawn loop guard
var death_count_at_checkpoint: int = 0
var last_death_checkpoint: Vector2 = Vector2.ZERO

# Attack state
var atk_timer: float = 0.0
var atk_cooldown: float = 0.0
var atk_damage: int = LIGHT_ATK_DMG
var is_heavy: bool = false

# Dash state
var dash_timer: float = 0.0
var dash_cooldown: float = 0.0
var dash_dir: float = 1.0

# Fury state
var fury_timer: float = 0.0

# Hurt state
var hurt_timer: float = 0.0
var invuln_timer: float = 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var atk_area: Area2D = $AttackArea
@onready var atk_collision: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	state = State.IDLE
	GameState.current_hp = GameState.max_hp
	update_attack_damage()
	atk_area.body_entered.connect(_on_attack_area_body_entered)


func _physics_process(delta: float) -> void:
	# Timers
	if atk_cooldown > 0:
		atk_cooldown -= delta
	if dash_cooldown > 0:
		dash_cooldown -= delta
	if fury_timer > 0:
		fury_timer -= delta
		if fury_timer <= 0:
			end_fury()
	if GameState.fury_cooldown_timer > 0:
		GameState.fury_cooldown_timer -= delta
	if invuln_timer > 0:
		invuln_timer -= delta
		sprite.modulate.a = 0.5 if int(invuln_timer * 10) % 2 == 0 else 1.0
	else:
		sprite.modulate.a = 1.0

	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Ground detection
	if is_on_floor() and not was_on_floor and state == State.JUMP:
		state = State.IDLE
	was_on_floor = is_on_floor()

	match state:
		State.IDLE, State.RUN:
			handle_movement(delta)
			handle_attack_start(delta)
			handle_dash_start()
			if is_on_floor() and Input.is_action_just_pressed("jump"):
				state = State.JUMP
				velocity.y = JUMP_VEL

		State.JUMP, State.FALL:
			handle_movement(delta)
			handle_attack_start(delta)
			handle_dash_start()
			# Variable jump height
			if state == State.JUMP and Input.is_action_just_released("jump"):
				velocity.y *= JUMP_CUT_MULT
			if velocity.y > 0:
				state = State.FALL
			if is_on_floor():
				state = State.IDLE

		State.ATTACK_LIGHT, State.ATTACK_HEAVY:
			atk_timer -= delta
			# Lock horizontal movement during heavy, halve during light
			if state == State.ATTACK_LIGHT and is_on_floor():
				var dir: float = Input.get_axis("move_left", "move_right")
				velocity.x = move_toward(velocity.x, dir * SPEED * 0.5, ACCEL * delta)
			else:
				velocity.x = move_toward(velocity.x, 0.0, ACCEL * delta)
			velocity.y += GRAVITY * delta * 0.5
			if atk_timer <= 0:
				end_attack()

		State.DASH:
			dash_timer -= delta
			velocity.x = dash_dir * DASH_SPEED
			velocity.y = 0.0
			if dash_timer <= 0:
				state = State.IDLE

		State.HURT:
			hurt_timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
			velocity.y += GRAVITY * delta
			if hurt_timer <= 0:
				state = State.IDLE

		State.DEAD:
			velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
			velocity.y += GRAVITY * delta

	# Death plane: kill player if fallen out of world
	if global_position.y > 1200:
		if state != State.DEAD:
			GameState.take_damage(GameState.current_hp)
			die()

	move_and_slide()
	update_animation()


func handle_movement(delta: float) -> void:
	var dir: float = Input.get_axis("move_left", "move_right")
	if dir != 0:
		facing_right = dir > 0
		velocity.x = move_toward(velocity.x, dir * SPEED, ACCEL * delta)
		state = State.RUN if is_on_floor() else state
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		if is_on_floor() and state != State.JUMP and state != State.FALL:
			state = State.IDLE


func handle_attack_start(delta: float) -> void:
	if atk_cooldown > 0:
		return
	if Input.is_action_just_pressed("attack_light"):
		start_attack(false)
	elif Input.is_action_just_pressed("attack_heavy"):
		start_attack(true)


func start_attack(heavy: bool) -> void:
	is_heavy = heavy
	if heavy:
		state = State.ATTACK_HEAVY
		atk_damage = HEAVY_ATK_DMG * int(GameState.get_damage())
		atk_timer = HEAVY_ATK_DURATION
		atk_cooldown = HEAVY_ATK_CD
	else:
		state = State.ATTACK_LIGHT
		atk_damage = LIGHT_ATK_DMG * int(GameState.get_damage())
		atk_timer = LIGHT_ATK_DURATION
		atk_cooldown = LIGHT_ATK_CD

	atk_collision.disabled = false
	# Position hitbox in front of player
	atk_area.position.x = 16 if facing_right else -16


func end_attack() -> void:
	atk_collision.disabled = true
	state = State.IDLE


func handle_dash_start() -> void:
	if dash_cooldown > 0:
		return
	if Input.is_action_just_pressed("dash"):
		state = State.DASH
		dash_timer = DASH_DURATION
		dash_cooldown = DASH_CD
		dash_dir = 1.0 if facing_right else -1.0

	# Fury activation
	if Input.is_action_just_pressed("fury") and GameState.fury_unlocked and GameState.fury_cooldown_timer <= 0 and fury_timer <= 0:
		activate_fury()


func take_damage(amount: int, knockback_dir: Vector2) -> void:
	if invuln_timer > 0 or state == State.DEAD or state == State.DASH:
		return
	if state == State.DASH:
		return

	GameState.take_damage(amount)
	if GameState.current_hp <= 0:
		state = State.DEAD
		die()
		return

	state = State.HURT
	hurt_timer = HURT_DURATION
	invuln_timer = INVULN_TIME
	velocity = knockback_dir * KNOCKBACK_FORCE


func die() -> void:
	state = State.DEAD
	atk_collision.disabled = true
	set_physics_process(false)

	# Death-respawn loop guard: if player dies 3+ times at same checkpoint,
	# respawn at level start instead to prevent softlock
	var current_cp := GameState.last_checkpoint
	if current_cp == last_death_checkpoint:
		death_count_at_checkpoint += 1
	else:
		death_count_at_checkpoint = 0
		last_death_checkpoint = current_cp

	if death_count_at_checkpoint >= 3:
		# Force respawn at level start
		GameState.last_checkpoint = Vector2.ZERO
		death_count_at_checkpoint = 0

	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_callback(_respawn)


func _respawn() -> void:
	GameState.current_hp = GameState.max_hp
	var level_path := GameState.checkpoint_level
	if level_path == "" or GameState.last_checkpoint == Vector2.ZERO:
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file(level_path)
	set_physics_process(true)


func update_animation() -> void:
	match state:
		State.IDLE:
			anim.play("idle")
		State.RUN:
			anim.play("run")
		State.JUMP, State.FALL:
			anim.play("jump")
		State.ATTACK_LIGHT:
			anim.play("attack_light")
		State.ATTACK_HEAVY:
			anim.play("attack_heavy")
		State.DASH:
			anim.play("dash")
		State.HURT:
			anim.play("hurt")
		State.DEAD:
			anim.play("dead")

	if facing_right:
		anim.flip_h = false
	else:
		anim.flip_h = true


func activate_fury() -> void:
	GameState.fury_active = true
	fury_timer = FURY_DURATION
	GameState.fury_cooldown_timer = FURY_CD
	# Visual feedback - red tint on sprite
	sprite.modulate = Color(1.5, 0.5, 0.5, 1)
	create_tween().tween_interval(0.1)


func end_fury() -> void:
	GameState.fury_active = false
	sprite.modulate = Color(1, 1, 1, 1)


func update_attack_damage() -> void:
	atk_damage = int(GameState.get_damage())


func _on_attack_area_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		var dir: Vector2 = Vector2.RIGHT if facing_right else Vector2.LEFT
		body.take_damage(atk_damage, dir)
