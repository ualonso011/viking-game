extends Node
## AudioManager: bus-backed music + SFX + ambience. Singleton via autoload.

signal music_finished
signal bus_volume_changed(bus: StringName, linear: float)

const SFX_POOL_SIZE: int = 8
const MUSIC_BUS: StringName = &"Music"
const SFX_BUS: StringName = &"SFX"
const AMBIENCE_BUS: StringName = &"Ambience"

@onready var music_player: AudioStreamPlayer
@onready var ambience_player: AudioStreamPlayer
var sfx_pool: Array[AudioStreamPlayer] = []
var sfx_idx: int = 0


func _ready() -> void:
	music_player = _create_player(MUSIC_BUS)
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)

	ambience_player = _create_player(AMBIENCE_BUS)
	add_child(ambience_player)

	for i in SFX_POOL_SIZE:
		var player := _create_player(SFX_BUS)
		sfx_pool.append(player)
		add_child(player)


func _create_player(bus: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	return player


func play_music(track_name: StringName, loop: bool = true) -> void:
	var stream := _load_stream("res://assets/audio/music/%s.ogg" % track_name)
	if stream == null:
		return
	stream.loop = loop

	if music_player.playing:
		var old_player := music_player
		music_player = _create_player(MUSIC_BUS)
		music_player.stream = stream
		music_player.volume_db = -40.0
		music_player.finished.connect(_on_music_finished)
		add_child(music_player)

		var tween := create_tween().set_parallel(true)
		tween.tween_property(old_player, "volume_db", -40.0, 0.5)
		tween.tween_property(music_player, "volume_db", 0.0, 0.5).set_delay(0.5)
		tween.chain().tween_callback(func(): old_player.queue_free())
		music_player.play()
	else:
		music_player.stream = stream
		music_player.volume_db = 0.0
		music_player.play()


func stop_music(fade_ms: int = 500) -> void:
	if not music_player.playing:
		return
	var tween := create_tween()
	tween.tween_property(music_player, "volume_db", -40.0, fade_ms / 1000.0)
	tween.tween_callback(func():
		music_player.stop()
		music_player.stream = null
	)


func play_sfx(sfx_name: StringName) -> void:
	var stream := _load_stream("res://assets/audio/sfx/%s.ogg" % sfx_name)
	if stream == null:
		return

	var player := sfx_pool[sfx_idx]
	sfx_idx = (sfx_idx + 1) % sfx_pool.size()
	player.stream = stream
	player.play()


func play_ambience(track_name: StringName) -> void:
	var stream := _load_stream("res://assets/audio/ambience/%s.ogg" % track_name)
	if stream == null:
		return
	stream.loop = true
	ambience_player.stream = stream
	ambience_player.volume_db = 0.0
	ambience_player.play()


func stop_ambience(fade_ms: int = 500) -> void:
	if not ambience_player.playing:
		return
	var tween := create_tween()
	tween.tween_property(ambience_player, "volume_db", -40.0, fade_ms / 1000.0)
	tween.tween_callback(func():
		ambience_player.stop()
		ambience_player.stream = null
	)


func set_bus_volume(bus: StringName, linear: float) -> void:
	linear = clampf(linear, 0.0, 1.0)
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(linear))
	bus_volume_changed.emit(bus, linear)


func get_bus_volume(bus: StringName) -> float:
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(idx))


## Convenience wrappers matching the public API surface expected by UI scenes.
func set_music_volume(linear: float) -> void:
	set_bus_volume(MUSIC_BUS, linear)


func set_sfx_volume(linear: float) -> void:
	set_bus_volume(SFX_BUS, linear)


func set_ambience_volume(linear: float) -> void:
	set_bus_volume(AMBIENCE_BUS, linear)


func _load_stream(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: missing stream %s" % path)
		return null
	return load(path) as AudioStream


func _on_music_finished() -> void:
	music_finished.emit()
