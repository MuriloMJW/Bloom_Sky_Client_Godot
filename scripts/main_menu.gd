extends Control

@onready var username_input = $LoginContainer/UsernameInput
@onready var play_button = $LoginContainer/PlayButton

var dev_mode = true
var game_scene = "res://scenes/game.tscn"
var sent_auth_request = false

func _ready() -> void:
	#Client.login_successful.connect(_on_Client_login_successful)
	
	Client.auth_success.connect(_on_Client_auth_success)
	Client.auth_fail.connect(_on_Client_auth_fail)
	
	#play_button.disabled = true
	
	

func _process(delta: float) -> void:
	
	if (dev_mode):
		if(Client.socket.get_ready_state() == Client.socket.STATE_OPEN and not sent_auth_request):
			print("TA OPEN")
			var username = "Devmj"
			Client._request_authentication(username)
			sent_auth_request = true


func _on_play_button_pressed() -> void:
	#Client._request_connect()
	#get_tree().call_deferred("change_scene_to_file", game_scene)
	
	var username = username_input.text
	if username != "":
		Client._request_authentication(username)

	
	
func _on_Client_auth_success():
	print("=== AUTH SUCCESS! CHANGING SCENE... ===")
	get_tree().call_deferred("change_scene_to_file", game_scene)
	pass
	
func _on_Client_auth_fail():
	print("=== AUTH FAIL! TA FAZENDO COISA ERRADA... ===")
 
