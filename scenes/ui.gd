extends Control

signal focus_changed(game_focus)

@onready var input_chat = $BottomMargin/HBoxContainer/ChatVBoxContainer/ChatInput


func _process(delta: float) -> void:
	if(Input.is_action_just_pressed("enter_pressed")):
		if(not input_chat.has_focus()):
			input_chat.grab_focus()
		else:
			input_chat.release_focus()
			
func _on_chat_input_focus_entered() -> void:
	emit_signal("focus_changed", false)


func _on_chat_input_focus_exited() -> void:
	emit_signal("focus_changed", true)
