extends CanvasLayer
## Options panel: music/sfx/ambience volume, fullscreen, language.
## Persists settings to user://settings.cfg.

const CONFIG_PATH := "user://settings.cfg"
const DEFAULT_VOLUME := 0.8

@onready var music_slider: HSlider = $Panel/MarginContainer/VBoxContainer/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $Panel/MarginContainer/VBoxContainer/SFXRow/SFXSlider
@onready var ambience_slider: HSlider = $Panel/MarginContainer/VBoxContainer/AmbienceRow/AmbienceSlider
@onready var fullscreen_check: CheckButton = $Panel/MarginContainer/VBoxContainer/FullscreenRow/FullscreenCheck
@onready var language_option: OptionButton = $Panel/MarginContainer/VBoxContainer/LanguageRow/LanguageOption


func _ready() -> void:
	theme = preload("res://assets/themes/viking_theme.tres")
	process_mode = PROCESS_MODE_ALWAYS

	_load_settings()

	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	ambience_slider.value_changed.connect(_on_ambience_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	language_option.item_selected.connect(_on_language_selected)
	$Panel/MarginContainer/VBoxContainer/CloseButton.pressed.connect(hide)

	visible = false


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(CONFIG_PATH)

	var music_vol := cfg.get_value("audio", "music", DEFAULT_VOLUME) as float
	var sfx_vol := cfg.get_value("audio", "sfx", DEFAULT_VOLUME) as float
	var ambience_vol := cfg.get_value("audio", "ambience", DEFAULT_VOLUME) as float
	var fullscreen := cfg.get_value("video", "fullscreen", false) as bool
	var locale := cfg.get_value("locale", "language", "es") as String

	music_slider.value = music_vol
	sfx_slider.value = sfx_vol
	ambience_slider.value = ambience_vol
	fullscreen_check.button_pressed = fullscreen
	language_option.select(0 if locale == "es" else 1)

	_apply_settings(music_vol, sfx_vol, ambience_vol, fullscreen, locale)


func _apply_settings(music: float, sfx: float, ambience: float, fullscreen: bool, locale: String) -> void:
	audio_manager.set_music_volume(music)
	audio_manager.set_sfx_volume(sfx)
	audio_manager.set_ambience_volume(ambience)
	_set_fullscreen(fullscreen)
	TranslationServer.set_locale(locale)


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music_slider.value)
	cfg.set_value("audio", "sfx", sfx_slider.value)
	cfg.set_value("audio", "ambience", ambience_slider.value)
	cfg.set_value("video", "fullscreen", fullscreen_check.button_pressed)
	cfg.set_value("locale", "language", "es" if language_option.selected == 0 else "en")
	cfg.save(CONFIG_PATH)


func _on_music_changed(value: float) -> void:
	audio_manager.set_music_volume(value)
	_save_settings()


func _on_sfx_changed(value: float) -> void:
	audio_manager.set_sfx_volume(value)
	_save_settings()


func _on_ambience_changed(value: float) -> void:
	audio_manager.set_ambience_volume(value)
	_save_settings()


func _on_fullscreen_toggled(enabled: bool) -> void:
	_set_fullscreen(enabled)
	_save_settings()


func _set_fullscreen(enabled: bool) -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)


func _on_language_selected(index: int) -> void:
	var locale := "es" if index == 0 else "en"
	TranslationServer.set_locale(locale)
	_save_settings()
