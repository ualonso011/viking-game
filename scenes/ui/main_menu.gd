extends CanvasLayer
## Main menu screen.

signal start_game()


func _on_start_pressed() -> void:
	start_game.emit()
