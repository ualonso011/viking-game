@tool
extends EditorScript
## Procedural asset generator for the Viking Game Remodel (PR 1).
## Run from the Godot editor (File > Run > Run Script) or via headless CLI:
##   godot --headless --editor --script res://assets/sprites/generate_assets.gd
## All output paths are deterministic and match the directory structure in design.md.

# Viking "Ash & Ember" palette
const DARK: Color = Color("0D0D14")
const EMBER: Color = Color("B2611C")
const ASH: Color = Color("4A4A52")
const BONE: Color = Color("F0E8DA")

const STEEL: Color = Color("9CA3A8")
const LEATHER: Color = Color("7A5C3A")
const SKIN: Color = Color("C4956A")
const BLOOD: Color = Color("8B1A1A")
const BOSS_RED: Color = Color("6B1A1A")


func _run() -> void:
	seed(1)
	generate_player_sprites()
	generate_soldier_sprites()
	generate_boss_sprites()
	generate_panels()
	generate_portraits()
	generate_backgrounds()
	generate_ui_sprites()
	generate_icon()
	print("Viking asset pipeline finished.")


# ---------------------------------------------------------------------------
# Player (64 px height, Einar the Ash Bear)
# ---------------------------------------------------------------------------
func generate_player_sprites() -> void:
	var base := _create_player_frame(64, 64)
	base.save_png("res://assets/sprites/player/player_idle.png")

	# 4-frame run strip (256x64)
	var run := Image.create(256, 64, false, Image.FORMAT_RGBA8)
	for f in 4:
		var frame := _create_player_frame(64, 64, f)
		run.blit_rect(frame, Rect2i(0, 0, 64, 64), Vector2i(f * 64, 0))
	run.save_png("res://assets/sprites/player/player_run.png")

	# Attack poses reuse base with weapon tint
	var light := base.duplicate()
	_draw_rect(light, 44, 24, 20, 12, STEEL)
	light.save_png("res://assets/sprites/player/player_attack_light.png")

	var heavy := base.duplicate()
	_draw_rect(heavy, 40, 16, 28, 16, STEEL)
	_tint_image(heavy, Color(1.2, 0.9, 0.6, 0.3))
	heavy.save_png("res://assets/sprites/player/player_attack_heavy.png")

	var jump := base.duplicate()
	_tint_image(jump, Color(0.9, 0.9, 1.0, 0.2))
	jump.save_png("res://assets/sprites/player/player_jump.png")

	var dash := base.duplicate()
	_tint_image(dash, Color(1.0, 1.0, 1.0, 0.35))
	dash.save_png("res://assets/sprites/player/player_dash.png")

	var hurt := base.duplicate()
	_tint_image(hurt, Color(1.0, 0.3, 0.3, 0.5))
	hurt.save_png("res://assets/sprites/player/player_hurt.png")

	var dead := base.duplicate()
	_tint_image(dead, Color(0.3, 0.3, 0.35, 0.6))
	dead.save_png("res://assets/sprites/player/player_dead.png")

	print("  Player sprites created")


func _create_player_frame(w: int, h: int, stride: int = -1) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	# Body / tunic
	_draw_rect(img, 20, 22, 24, 28, Color("3A4A5A"))
	# Legs
	_draw_rect(img, 22, 50, 8, 14, Color("2A2A2A"))
	_draw_rect(img, 34, 50, 8, 14, Color("2A2A2A"))
	# Belt
	_draw_rect(img, 20, 44, 24, 4, LEATHER)
	# Head
	_draw_rect(img, 24, 8, 16, 16, SKIN)
	# Helmet / hair
	_draw_rect(img, 22, 4, 20, 8, Color("3A3A3A"))
	_draw_rect(img, 18, 8, 6, 10, Color("3A3A3A"))
	_draw_rect(img, 40, 8, 6, 10, Color("3A3A3A"))
	# Arms
	_draw_rect(img, 8, 26, 12, 8, SKIN)
	_draw_rect(img, 44, 26, 12, 8, SKIN)
	# Axe haft on back
	_draw_rect(img, 48, 6, 4, 46, Color("5A3A2A"))
	# Axe head
	_draw_rect(img, 46, 2, 8, 10, STEEL)

	if stride >= 0:
		# Offset legs slightly per frame for run cycle
		var off: int = (stride % 2) * 2
		if stride == 1 or stride == 3:
			_draw_rect(img, 22 + off, 50, 8, 14, Color("2A2A2A"))
	return img


# ---------------------------------------------------------------------------
# Soldier enemy (32 px height)
# ---------------------------------------------------------------------------
func generate_soldier_sprites() -> void:
	var base := _create_soldier_frame(32, 32)
	base.save_png("res://assets/sprites/enemies/soldier_idle.png")

	var run := Image.create(128, 32, false, Image.FORMAT_RGBA8)
	for f in 4:
		var frame := _create_soldier_frame(32, 32, f)
		_run.blit_rect(run, frame, Rect2i(0, 0, 32, 32), Vector2i(f * 32, 0))
	run.save_png("res://assets/sprites/enemies/soldier_run.png")

	var atk := base.duplicate()
	_draw_rect(atk, 24, 14, 10, 4, STEEL)
	atk.save_png("res://assets/sprites/enemies/soldier_attack.png")

	var hurt := base.duplicate()
	_tint_image(hurt, Color(1.0, 0.4, 0.4, 0.5))
	hurt.save_png("res://assets/sprites/enemies/soldier_hurt.png")

	var dead := base.duplicate()
	_tint_image(dead, Color(0.3, 0.3, 0.35, 0.6))
	dead.save_png("res://assets/sprites/enemies/soldier_dead.png")

	print("  Soldier sprites created")


func _create_soldier_frame(w: int, h: int, stride: int = -1) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	# Tunic (English red)
	_draw_rect(img, 8, 10, 16, 14, Color("8B3A3A"))
	# Legs
	_draw_rect(img, 10, 24, 4, 8, Color("4A3A2A"))
	_draw_rect(img, 18, 24, 4, 8, Color("4A3A2A"))
	# Head
	_draw_rect(img, 10, 4, 12, 8, SKIN)
	# Helmet
	_draw_rect(img, 8, 2, 16, 4, STEEL)
	# Shield
	_draw_rect(img, 2, 12, 8, 12, Color("4A4A52"))
	# Sword arm
	_draw_rect(img, 24, 12, 6, 4, SKIN)

	if stride >= 0:
		var off: int = (stride % 2) * 2
		if stride == 1 or stride == 3:
			_draw_rect(img, 10 + off, 24, 4, 8, Color("4A3A2A"))
	return img


# ---------------------------------------------------------------------------
# Bosses (48 px height)
# ---------------------------------------------------------------------------
func generate_boss_sprites() -> void:
	# Halvard (first boss) - dark jarl
	var halvard_base := _create_boss_frame(48, 48, false)
	halvard_base.save_png("res://assets/sprites/enemies/boss_halvard_idle.png")

	var halvard_run := Image.create(192, 48, false, Image.FORMAT_RGBA8)
	for f in 4:
		var frame := _create_boss_frame(48, 48, false, f)
		halvard_run.blit_rect(frame, Rect2i(0, 0, 48, 48), Vector2i(f * 48, 0))
	halvard_run.save_png("res://assets/sprites/enemies/boss_halvard_run.png")

	var halvard_enraged := halvard_base.duplicate()
	_tint_image(halvard_enraged, Color(1.3, 0.4, 0.3, 0.35))
	halvard_enraged.save_png("res://assets/sprites/enemies/boss_halvard_enraged.png")

	# Final boss - ash-corrupted variant
	var final_base := _create_boss_frame(48, 48, true)
	final_base.save_png("res://assets/sprites/enemies/boss_final_idle.png")

	var final_run := Image.create(192, 48, false, Image.FORMAT_RGBA8)
	for f in 4:
		var frame := _create_boss_frame(48, 48, true, f)
		final_run.blit_rect(frame, Rect2i(0, 0, 48, 48), Vector2i(f * 48, 0))
	final_run.save_png("res://assets/sprites/enemies/boss_final_run.png")

	var final_enraged := final_base.duplicate()
	_tint_image(final_enraged, Color(1.4, 0.3, 0.2, 0.4))
	final_enraged.save_png("res://assets/sprites/enemies/boss_final_enraged.png")

	print("  Boss sprites created")


func _create_boss_frame(w: int, h: int, is_final: bool, stride: int = -1) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var armor := Color("3A2A1A") if not is_final else Color("1A1A1A")
	var cloak := BOSS_RED if not is_final else Color("4A4A52")

	# Body
	_draw_rect(img, 12, 16, 24, 24, armor)
	# Cloak
	_draw_rect(img, 8, 18, 8, 22, cloak)
	_draw_rect(img, 34, 18, 8, 22, cloak)
	# Legs
	_draw_rect(img, 14, 40, 8, 8, Color("2A1A0A"))
	_draw_rect(img, 26, 40, 8, 8, Color("2A1A0A"))
	# Head
	_draw_rect(img, 16, 6, 16, 14, SKIN)
	# Helmet / horns
	_draw_rect(img, 14, 2, 20, 6, Color("4A4A52"))
	_draw_rect(img, 10, 4, 6, 4, STEEL)
	_draw_rect(img, 32, 4, 6, 4, STEEL)
	# Weapon
	_draw_rect(img, 36, 12, 4, 28, Color("5A3A2A"))
	_draw_rect(img, 34, 8, 8, 8, STEEL)

	if stride >= 0:
		var off: int = (stride % 2) * 3
		if stride == 1 or stride == 3:
			_draw_rect(img, 14 + off, 40, 8, 8, Color("2A1A0A"))
	return img


# ---------------------------------------------------------------------------
# 9-slice panels (wood + stone)
# ---------------------------------------------------------------------------
func generate_panels() -> void:
	var wood := _create_panel(64, 64, true)
	wood.save_png("res://assets/sprites/panel_wood.png")

	var stone := _create_panel(64, 64, false)
	stone.save_png("res://assets/sprites/panel_stone.png")

	print("  Panels created")


func _create_panel(w: int, h: int, is_wood: bool) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var base := LEATHER if is_wood else ASH
	var dark := Color("3A2A1A") if is_wood else Color("2A2A2A")
	var light := Color("B2611C") if is_wood else Color("6A6A72")

	# Base fill
	_draw_rect(img, 0, 0, w, h, base)

	# Outer rim
	_draw_h_line(img, 0, w, 0, dark)
	_draw_h_line(img, 0, w, h - 1, dark)
	_draw_v_line(img, 0, 0, h, dark)
	_draw_v_line(img, w - 1, 0, h, dark)

	# Inner rim
	_draw_h_line(img, 2, w - 2, 2, light)
	_draw_h_line(img, 2, w - 2, h - 3, light)
	_draw_v_line(img, 2, 2, h - 2, light)
	_draw_v_line(img, w - 3, 2, h - 2, light)

	# Corner studs
	_draw_rect(img, 4, 4, 8, 8, light)
	_draw_rect(img, w - 12, 4, 8, 8, light)
	_draw_rect(img, 4, h - 12, 8, 8, light)
	_draw_rect(img, w - 12, h - 12, 8, 8, light)

	return img


# ---------------------------------------------------------------------------
# Portraits (128x128)
# ---------------------------------------------------------------------------
func generate_portraits() -> void:
	_create_portrait("narrator", Color("1A1A1A"), Color("0D0D14"), false)
	_create_portrait("einar", Color("3A4A5A"), Color("3A3A3A"), true)
	_create_portrait("halvard", BOSS_RED, Color("3A2A1A"), true)
	_create_portrait("young_warrior", Color("5A6B4A"), Color("4A3A2A"), true)
	_create_portrait("english_soldier", Color("8B3A3A"), STEEL, true)
	print("  Portraits created")


func _create_portrait(name: String, tunic: Color, hair: Color, has_face: bool) -> void:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	# Background
	_draw_rect(img, 0, 0, 128, 128, DARK)
	# Shoulders / tunic
	_draw_rect(img, 24, 80, 80, 48, tunic)
	# Neck
	_draw_rect(img, 52, 68, 24, 16, SKIN)
	# Head
	_draw_rect(img, 36, 24, 56, 56, SKIN)
	# Hair / helmet
	_draw_rect(img, 32, 16, 64, 20, hair)
	if has_face:
		# Eyes
		_draw_rect(img, 46, 44, 8, 6, Color("1A1A1A"))
		_draw_rect(img, 74, 44, 8, 6, Color("1A1A1A"))
		# Mouth
		_draw_rect(img, 56, 64, 16, 4, Color("8B3A3A"))
	img.save_png("res://assets/sprites/portraits/%s.png" % name)


# ---------------------------------------------------------------------------
# Backgrounds (1920x1080)
# ---------------------------------------------------------------------------
func generate_backgrounds() -> void:
	_create_background("farm_burning", Color("1A0A05"), Color("4A1A0A"), true)
	_create_background("cinders_village", Color("0D0D14"), Color("2A0A05"), true)
	_create_background("snowy_mountains", Color("0A1018"), Color("4A5A6A"), false)
	_create_background("english_coast", Color("081018"), Color("1A3A4A"), false)
	print("  Backgrounds created")


func _create_background(name: String, sky_top: Color, sky_bot: Color, burning: bool) -> void:
	var img := Image.create(1920, 1080, false, Image.FORMAT_RGBA8)
	# Vertical sky gradient
	for y in 1080:
		var t: float = float(y) / 1080.0
		var c: Color = sky_top.lerp(sky_bot, t)
		_draw_h_line(img, 0, 1920, y, c)

	# Distant mountains
	var mountain_color := Color(sky_bot.r * 0.6, sky_bot.g * 0.6, sky_bot.b * 0.6)
	for x in 1920:
		var h: int = 600 + int(sin(x * 0.005) * 80) + int(sin(x * 0.02) * 20)
		_draw_v_line(img, x, h, 1080, mountain_color)

	# Ground / ash layer
	_draw_rect(img, 0, 900, 1920, 180, Color("0D0D14"))

	if burning:
		# Fire sparks
		for i in 400:
			var px: int = randi() % 1920
			var py: int = 500 + randi() % 580
			var size: int = 2 + randi() % 4
			_draw_rect(img, px, py, size, size, EMBER)

	img.save_png("res://assets/sprites/backgrounds/%s.png" % name)


# ---------------------------------------------------------------------------
# UI sprites
# ---------------------------------------------------------------------------
func generate_ui_sprites() -> void:
	# Health bar background
	var bg := Image.create(128, 16, false, Image.FORMAT_RGBA8)
	_draw_rect(bg, 0, 0, 128, 16, Color("2A1A0A"))
	_draw_rect(bg, 2, 2, 124, 12, Color("1A0A00"))
	bg.save_png("res://assets/sprites/ui/health_bar_bg.png")

	# Health bar fill (ember gradient)
	var fill := Image.create(128, 16, false, Image.FORMAT_RGBA8)
	for x in 128:
		var t: float = float(x) / 128.0
		var c: Color = Color("B2611C").lerp(Color("5A1A0A"), t)
		_draw_v_line(fill, x, 0, 16, c)
	fill.save_png("res://assets/sprites/ui/health_bar_fill.png")

	# Fury icon (bear claw)
	var fury := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	_draw_rect(fury, 0, 0, 64, 64, DARK)
	_draw_rect(fury, 20, 12, 8, 32, EMBER)
	_draw_rect(fury, 32, 12, 8, 32, EMBER)
	_draw_rect(fury, 44, 16, 8, 28, EMBER)
	_draw_rect(fury, 12, 44, 40, 8, EMBER)
	fury.save_png("res://assets/sprites/ui/fury_icon.png")

	# Checkpoint flag
	var flag := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	_draw_rect(flag, 0, 0, 64, 64, Color(0, 0, 0, 0))
	_draw_rect(flag, 28, 8, 4, 48, Color("5A3A2A"))
	_draw_rect(flag, 32, 8, 24, 18, EMBER)
	flag.save_png("res://assets/sprites/ui/checkpoint_flag.png")

	print("  UI sprites created")


# ---------------------------------------------------------------------------
# Game icon (192x192, Thurisaz rune ᚦ)
# ---------------------------------------------------------------------------
func generate_icon() -> void:
	var img := Image.create(192, 192, false, Image.FORMAT_RGBA8)
	# Background
	_draw_rect(img, 0, 0, 192, 192, DARK)
	# Rounded-ish inner field
	_draw_rect(img, 16, 16, 160, 160, Color("1A1A24"))
	# Thurisaz rune: vertical bar + triangle / angular shape
	var rune := Color("B2611C")
	_draw_rect(img, 92, 36, 8, 120, rune)
	_draw_rect(img, 92, 36, 56, 8, rune)
	_draw_rect(img, 92, 92, 56, 8, rune)
	_draw_rect(img, 140, 36, 8, 64, rune)
	# Border
	_draw_h_line(img, 0, 192, 0, rune)
	_draw_h_line(img, 0, 192, 191, rune)
	_draw_v_line(img, 0, 0, 192, rune)
	_draw_v_line(img, 191, 0, 192, rune)
	img.save_png("res://assets/sprites/icon.png")
	print("  Icon created")


# ---------------------------------------------------------------------------
# Low-level helpers
# ---------------------------------------------------------------------------
func _draw_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for px in range(x, x + w):
		for py in range(y, y + h):
			if px >= 0 and py >= 0 and px < img.get_width() and py < img.get_height():
				img.set_pixel(px, py, color)


func _draw_h_line(img: Image, x: int, x2: int, y: int, color: Color) -> void:
	for px in range(x, x2):
		if px >= 0 and px < img.get_width() and y >= 0 and y < img.get_height():
			img.set_pixel(px, y, color)


func _draw_v_line(img: Image, x: int, y: int, y2: int, color: Color) -> void:
	for py in range(y, y2):
		if x >= 0 and x < img.get_width() and py >= 0 and py < img.get_height():
			img.set_pixel(x, py, color)


func _tint_image(img: Image, tint: Color) -> void:
	for x in img.get_width():
		for y in img.get_height():
			var c: Color = img.get_pixel(x, y)
			if c.a > 0:
				img.set_pixel(x, y, Color(
					lerp(c.r, tint.r, tint.a),
					lerp(c.g, tint.g, tint.a),
					lerp(c.b, tint.b, tint.a),
					c.a
				))
