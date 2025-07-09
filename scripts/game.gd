extends Node2D

@export var player_scene: PackedScene
@export var enemy_scene: PackedScene

@onready var chat_screen = $CanvasLayer/UI/BottomMargin/HBoxContainer/ChatVBoxContainer
@onready var input_chat = $CanvasLayer/UI/BottomMargin/HBoxContainer/ChatVBoxContainer/ChatInput
@onready var output_chat = $CanvasLayer/UI/BottomMargin/HBoxContainer/ChatVBoxContainer/OutputContainer/MarginContainer/ChatOutput
@onready var status_screen = $CanvasLayer/UI/TopMargin/HBoxContainer/StatusContainer/Status
@onready var ping_screen = $CanvasLayer/UI/TopMargin/HBoxContainer/PingContainer/Ping
@onready var fps_screen = $CanvasLayer/UI/TopMargin/HBoxContainer/FpsContainer/Fps
@onready var output_ranking = $CanvasLayer/UI/BottomMargin/HBoxContainer/RankingVBoxContainer/RankingContainer/MarginContainer/RankingOutput
@onready var ranking_screen = $CanvasLayer/UI/BottomMargin/HBoxContainer/RankingVBoxContainer
@onready var ui = $CanvasLayer/UI

@onready var mob_spawn_timer = $MobSpawnTimer


var game_title = "[color='yellow']BLOOM SKY[/color]\n"
var version = "[color='yellow']Versão 0.0.1 Alfa Pre-release - 09/07/2025 [/color]"


var my_id = -1
var players_connected = {}


func _ready() -> void:
	_setup_ui()
	#_setup_players()
	
	_connect_client_signals_to_game()
	
	#emit_signal("scene_loaded")
	Client._request_connect()

func _setup_players():
	# Método de spawnar os players através de cache
	var my_player_data = Client.my_player_data_cache
	print("===ME CONNECTED===")
	chat_screen.show()
	status_screen.text = "Conectado"
	
	output_ranking.show()
	ranking_screen.show()
	my_id = my_player_data.id
	
	spawn_player(my_player_data)
	
	var other_players_data = Client.other_player_data_cache
	for others in other_players_data:
		spawn_player(others)

func _setup_ui():
	chat_screen.hide()
	output_chat.text = game_title
	output_chat.text += version+"\n"
	output_ranking.hide()
	ranking_screen.hide()
	output_ranking.text = ''

func _process(delta: float) -> void:
	fps_screen.text = "FPS: "+str(Engine.get_frames_per_second())

func _connect_client_signals_to_game():
	# Sinais de Lógica do Jogo
	
	Client.player_connected.connect(_on_client_player_connected)
	Client.other_player_connected.connect(_on_client_other_player_connected)
	Client.other_player_disconnected.connect(_on_client_other_player_disconnected)
	Client.player_shoot.connect(_on_client_player_shoot)
	Client.player_sonicked.connect(_on_client_player_sonicked)
	Client.player_updated.connect(_on_client_player_updated)
	Client.rat_attacked.connect(_on_client_rat_attacked)
	
	# Sinais da Interface (HUD)
	Client.connection_status_updated.connect(_on_client_connection_status_updated)
	Client.ping_updated.connect(_on_client_ping_updated)
	Client.chat_updated.connect(_on_client_chat_updated)
	Client.ranking_updated.connect(_on_client_ranking_updated)

func _connect_player_signals_to_client(new_player):
	# Ligando sinais do player no client
	new_player.move_pressed.connect(Client._on_player_move_pressed)
	new_player.shoot_pressed.connect(Client._on_player_shoot_pressed)
	new_player.damage_report.connect(Client._on_player_damage_report)
	new_player.respawn_pressed.connect(Client._on_respawn_pressed)
	new_player.change_team_pressed.connect(Client._on_player_change_team_pressed)
	new_player.sonic_pressed.connect(Client._on_player_sonic_pressed)
	#client.focus_changed.connect(new_player._on_client_focus_changed)

func _connect_ui_signals_to_player(new_player):
	ui.focus_changed.connect(new_player._on_ui_focus_changed)

func _on_mob_spawn_timer_timeout() -> void:
	spawn_enemy()
		

func spawn_player(player_data):
	var new_player = player_scene.instantiate()
	
	
	new_player.setup(player_data)
	new_player.is_my_player = (my_id == player_data.id)
	
	players_connected[new_player.id] = new_player
	
	new_player.show_info()

	add_child(new_player)
	
	if(new_player.is_my_player):
		_connect_player_signals_to_client(new_player)
		_connect_ui_signals_to_player(new_player)

func spawn_enemy():
	for i in range(500):
		var spawn_x = randi_range(0, get_viewport().get_visible_rect().size.x)
		var spawn_y = 0
		var enemy = enemy_scene.instantiate()
		enemy.position.x = spawn_x
		enemy.position.y = spawn_y
		
		add_child(enemy)
		await get_tree().create_timer(0.07).timeout
	


# --- [ SINAIS RECEBIDOS ] --- #
func _on_client_player_connected(player_data: PlayerData) -> void:
	print("===ME CONNECTED===")
	chat_screen.show()
	status_screen.text = Client.connection_status_text
	
	output_ranking.show()
	ranking_screen.show()
	my_id = player_data.id
	
	spawn_player(player_data)


func _on_client_other_player_connected(other_player_data: PlayerData) -> void:
	spawn_player(other_player_data)

func _on_client_other_player_disconnected(other_player_id: Variant) -> void:
	players_connected[other_player_id].queue_free()
	players_connected.erase(other_player_id)


func _on_client_player_shoot(shooter_id, bullet_speed, bullet_direction) -> void:
	players_connected[shooter_id].shoot(bullet_speed, bullet_direction)



func _on_client_player_sonicked(player_sonicked_id: Variant) -> void:
	players_connected[player_sonicked_id].sonic()


func _on_client_player_updated(player_data: PlayerData) -> void:
	players_connected[player_data.id].setup(player_data)


func _on_client_rat_attacked() -> void:
	spawn_enemy()
	
# ORDENAR DEPOIS

# HUD
func _on_chat_input_text_submitted(new_text: String) -> void:
	var text = input_chat.text
	if text == "":
		return
		
	Client._request_player_chat(text)
		
	input_chat.text = ""

func _on_client_connection_status_updated(connection_status_text: String) -> void:
	status_screen.text = connection_status_text

func _on_client_ping_updated(ping_text: String) -> void:
	ping_screen.text = ping_text

func _on_client_chat_updated(chat_text: String) -> void:
	output_chat.text += chat_text 

func _on_client_ranking_updated(ranking_text: String) -> void:
	output_ranking.text = ranking_text
