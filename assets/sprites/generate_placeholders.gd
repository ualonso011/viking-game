@tool
extends EditorScript
## Run this script once to generate placeholder sprites.
## Creates colored rectangles for all game sprites.

func _run() -> void:
	generate_player_sprite()
	generate_enemy_sprite()
	generate_tileset()
	generate_boss_sprite()
	generate_ui_assets()
	print("Placeholder sprites generated successfully!")


func generate_player_sprite() -> void:
	# 32x32 player sprite (blue-gray for Einar)
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var color := Color("4A6B8A")
	var armor := Color("7A5C3A")
	var skin := Color("D4A574")

	# Body
	_draw_rect(img, 8, 8, 16, 16, color)
	# Head
	_draw_rect(img, 12, 2, 8, 8, skin)
	# Helmet
	_draw_rect(img, 10, 0, 12, 4, armor)
	# Legs
	_draw_rect(img, 10, 24, 12, 8, Color("3A4A5A"))
	img.save_png("res://assets/sprites/player_idle.png")

	# Attack frame (arm extended)
	var atk_img := img.duplicate()
	_draw_rect(atk_img, 24, 10, 8, 4, Color("C0C0C0"))
	atk_img.save_png("res://assets/sprites/player_attack.png")

	# Hurt frame (red tint)
	var hurt_img := img.duplicate()
	_tint_image(hurt_img, Color(1, 0.3, 0.3, 0.5))
	hurt_img.save_png("res://assets/sprites/player_hurt.png")

	print("  Player sprites created")


func generate_enemy_sprite() -> void:
	# 32x32 soldier (red-brown)
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var color := Color("8B3A3A")
	var skin := Color("C4956A")

	_draw_rect(img, 8, 8, 16, 16, color)
	_draw_rect(img, 12, 2, 8, 8, skin)
	_draw_rect(img, 10, 0, 12, 4, Color("4A3A2A"))
	_draw_rect(img, 10, 24, 12, 8, Color("6B2A2A"))
	img.save_png("res://assets/sprites/enemy_soldier.png")

	# Attack frame
	var atk_img := img.duplicate()
	_draw_rect(atk_img, 24, 10, 8, 4, Color("FF4444"))
	atk_img.save_png("res://assets/sprites/enemy_soldier_attack.png")

	print("  Enemy soldier sprites created")


func generate_boss_sprite() -> void:
	# 48x48 boss (dark red, larger)
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	var color := Color("5A1A1A")
	var armor := Color("3A2A1A")
	var skin := Color("B8855A")

	_draw_rect(img, 12, 12, 24, 24, color)
	_draw_rect(img, 18, 4, 12, 12, skin)
	_draw_rect(img, 14, 2, 20, 6, armor)
	_draw_rect(img, 14, 36, 20, 12, Color("4A1A1A"))
	img.save_png("res://assets/sprites/boss.png")

	# Enraged frame (red glow)
	var rage_img := img.duplicate()
	_tint_image(rage_img, Color(1, 0.2, 0.2, 0.4))
	rage_img.save_png("res://assets/sprites/boss_enraged.png")

	print("  Boss sprites created")


func generate_tileset() -> void:
	# 16x16 tiles in a strip
	var img := Image.create(80, 16, false, Image.FORMAT_RGBA8)
	var colors := [
		Color("4A7A3A"),  # 0: Grass
		Color("6B4226"),  # 1: Dirt
		Color("8B7355"),  # 2: Stone
		Color("3A2A1A"),  # 3: Wood
		Color("2A1A0A"),  # 4: Dark stone
	]
	for i in colors.size():
		_draw_rect(img, i * 16, 0, 16, 16, colors[i])
	img.save_png("res://assets/sprites/tileset.png")

	# Background tiles
	var bg_img := Image.create(64, 16, false, Image.FORMAT_RGBA8)
	var bg_colors := [
		Color("4A6B8A"),  # Sky
		Color("6B8AAA"),  # Light sky
		Color("3A4A5A"),  # Mountains
		Color("5A6A7A"),  # Light mountains
	]
	for i in bg_colors.size():
		_draw_rect(bg_img, i * 16, 0, 16, 16, bg_colors[i])
	bg_img.save_png("res://assets/sprites/background_tiles.png")

	print("  Tilesets created")


func generate_ui_assets() -> void:
	# Health bar background
	var hb := Image.create(128, 16, false, Image.FORMAT_RGBA8)
	_draw_rect(hb, 0, 0, 128, 16, Color("2A1A0A"))
	_draw_rect(hb, 2, 2, 124, 12, Color("1A0A00"))
	hb.save_png("res://assets/sprites/health_bar_bg.png")

	# Health bar fill
	var hf := Image.create(128, 16, false, Image.FORMAT_RGBA8)
	_draw_rect(hf, 0, 0, 128, 16, Color("CC3333"))
	hf.save_png("res://assets/sprites/health_bar_fill.png")

	# Button background
	var btn := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	_draw_rect(btn, 0, 0, 64, 64, Color(1, 1, 1, 0.2))
	_draw_rect(btn, 2, 2, 60, 60, Color(1, 1, 1, 0.15))
	btn.save_png("res://assets/sprites/btn_bg.png")

	print("  UI sprites created")


func _draw_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for px in range(x, x + w):
		for py in range(y, y + h):
			if px < img.get_width() and py < img.get_height():
				img.set_pixel(px, py, color)


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
