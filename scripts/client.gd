extends Node

signal player_connected(player_data: PlayerData)
signal other_player_connected(player_data: PlayerData)
signal other_player_disconnected(other_player_id)
signal player_moved(player_x, player_y)
signal other_player_moved(other_player_x, other_player_y, other_player_id)
signal player_damaged(damaged_id, player_damager_id, damage, player_hp)
signal player_killed(killed_id, player_damaged_id, player_damager_id, damage, player_is_alive, player_hp)
signal player_respawned(player_respawned_id, player_respawned_x, player_respawned_y)
signal player_shoot(player_id)
signal player_changed_team(player_changed_team_id)
signal player_sonicked(player_sonicked_id)
signal player_updated(player_data: PlayerData)

@onready var chat_screen = $Control/VBoxContainer
@onready var input_chat = $Control/VBoxContainer/Input
@onready var output_chat = $Control/VBoxContainer/OutputContainer/MarginContainer/Output
@onready var status_screen = $Control/PanelContainer/Status
@onready var ping_screen = $Control/PanelContainer2/Ping
@onready var ranking_screen = $Control/VBoxContainer2/OutputContainer/MarginContainer/RankingOutput
@onready var ping_timer: Timer = $PingTimer
@onready var output_container = $Control/VBoxContainer2/OutputContainer


var websocket_url = "ws://127.0.0.1:9913"
#var websocket_url = "wss://3ae453be-0bb5-4226-9e4d-e6a65193784a-00-2juxj2mj683q2.janeway.replit.dev/"
#var websocket_url = "ws://127.0.0.1:8080"
var game_title = "[color='yellow']PROTITP DIALGO[/color]\n"
var version = "[color='yellow']Versão 0.0.0.40 Prototype - 26/06/2025 [/color]"
var ping_paused = true

var socket := WebSocketPeer.new()
var last_state = WebSocketPeer.STATE_CLOSED
var my_id = -1

enum Network {
	# Client -> Server
	REQUEST_CONNECT = 0,
	
	REQUEST_PLAYER_MOVE = 1,
	
	REQUEST_PLAYER_SHOOT = 2,
	REQUEST_PLAYER_DAMAGE = 3,
	REQUEST_PLAYER_RESPAWN = 4,
	REQUEST_PLAYER_CHANGE_TEAM = 5,
	REQUEST_PLAYER_SONIC = 6,
	
	CHAT_MESSAGE = 100,
	
	PING = 254,
	
	# Server -> Client
	PLAYER_CONNECTED = 100,
	OTHER_PLAYER_CONNECTED = 101,
	OTHER_PLAYER_DISCONNECTED = 102,
	
	PLAYER_MOVED = 103,
	#OTHER_PLAYER_MOVED = 104,
	
	PLAYER_SHOOT = 105,
	#OTHER_PLAYER_SHOOT = 106,
	#PLAYER_DAMAGED = 107,
	#PLAYER_KILLED = 108,
	#PLAYER_RESPAWNED = 109,
	#PLAYER_CHANGED_TEAM = 110,
	PLAYER_SONICKED = 111,
	
	PLAYER_UPDATED = 112,
	
	RANKING_UPDATED = 199,
	CHAT_RECEIVED = 200,
	
	PONG = 255
}

func _ready() -> void:
	output_chat.text = game_title
	output_chat.text += version+"\n"
	ping_timer.paused = ping_paused
	chat_screen.hide()
	ranking_screen.hide()
	output_container.hide()
	socket.connect_to_url(websocket_url)
	ranking_screen.text = ''

func _process(delta: float) -> void:
	# Envia e recebe frames inicias de abertura (HTTP -> Websocket)
	socket.poll()
	
	var state = socket.get_ready_state()
	
	_handle_state_change(state)
	
	if(state == socket.STATE_OPEN):
		_wait_packets()
	
func _handle_state_change(state):
	
	if(state == last_state):
		return
	
	last_state = state
	
	match state:
		
		socket.STATE_CONNECTING:
			print("CONNECTING...")
			status_screen.text = "Conectando..."
				
		socket.STATE_OPEN:
			_on_state_open()
			
		socket.STATE_CLOSING:
			print("CLOSING...")
			status_screen.text = "Desconectando..."
				
		socket.STATE_CLOSED:
			print("CLOSED")
			status_screen.text = "[color=red]Desconectado[/color]"
			
	
	return
			
func _on_state_open():
	print("OPEN!")
	status_screen.text = "Open"
	_request_connect()
	
func _wait_packets():
	while (socket.get_available_packet_count() > 0):
		receive_packet(socket.get_packet())
	

func _send_packet(buffer):
	print("===ENVIANDO PACKET===")
	print(buffer.data_array)
	socket.send(buffer.data_array)

func receive_packet(packet):
	print("===RECEBIDO===")
	#print(socket.get_packet())
	
	print("Packet received: ", packet)
	
	'''
	for i in range(packet.size()):
		var b = packet[i]
		print("Byte %d: %d" % [i, b])
	'''
	
	var buffer = MyBuffer.new(packet)
	
	var msgid = buffer.read_u8()
	
	match msgid:
		Network.PLAYER_CONNECTED:
			_handle_player_connected(buffer)
			
		Network.OTHER_PLAYER_CONNECTED:
			_handle_other_player_connected(buffer)
			
		Network.OTHER_PLAYER_DISCONNECTED:
			_handle_other_player_disconnected(buffer)
			
		#Network.PLAYER_MOVED:
			#_handle_player_moved(buffer)
			
		#Network.OTHER_PLAYER_MOVED:
		#	_handle_other_player_moved(buffer)
			
		Network.PLAYER_SHOOT:
			_handle_player_shoot(buffer)
			
		#Network.OTHER_PLAYER_SHOOT:
		#	_handle_other_player_shoot(buffer)
			
		#Network.PLAYER_DAMAGED:
		#	_handle_player_damaged(buffer)
			
		#Network.PLAYER_KILLED:
		#	_handle_player_killed(buffer)
			
		#Network.PLAYER_RESPAWNED:
		#	_handle_player_respawned(buffer)
			
		#Network.PLAYER_CHANGED_TEAM:
		#	_handle_player_changed_team(buffer)
			
		Network.PLAYER_SONICKED:
			_handle_player_sonicked(buffer)
		
		Network.PLAYER_UPDATED:
			_handle_player_updated(buffer)
			
		Network.RANKING_UPDATED:
			_handle_ranking_updated(buffer)
			
		Network.CHAT_RECEIVED:
			_handle_chat_received(buffer)
			
		Network.PONG:
			_handle_pong(buffer)
			
			
		_:
			print("PACOTE NÃO TRATADO: ", msgid)
			


# --- [ PEDIDOS AO SERVIDOR ] --- #

func _request_connect():
	print("===REQUEST CONNECT===")
	var buffer : MyBuffer
	buffer = MyBuffer.new()
	buffer.write_u8(Network.REQUEST_CONNECT)
	_send_packet(buffer)

func _request_player_move(move_x, move_y):
	print("===REQUEST PLAYER MOVE===")
	var buffer : MyBuffer
	buffer = MyBuffer.new()
	buffer.write_u8(Network.REQUEST_PLAYER_MOVE)
	buffer.write_u16(move_x)
	buffer.write_u16(move_y)
	_send_packet(buffer)

func _request_player_shoot():
	print("===REQUEST PLAYER SHOOT===")
	var buffer : MyBuffer
	buffer = MyBuffer.new()
	buffer.write_u8(Network.REQUEST_PLAYER_SHOOT)
	_send_packet(buffer)

func _request_player_damage(player_damaged_id, player_damager_id, damage_value):
	print("===REQUEST PLAYER DAMAGE===")
	var buffer : MyBuffer
	buffer = MyBuffer.new()
	buffer.write_u8(Network.REQUEST_PLAYER_DAMAGE)
	buffer.write_u8(player_damaged_id)
	buffer.write_u8(player_damager_id)
	buffer.write_u8(damage_value)
	_send_packet(buffer)

func _request_player_respawn(player_to_respawn_id):
	print("===REQUEST PLAYER DAMAGE===")
	var buffer : MyBuffer
	buffer = MyBuffer.new()
	buffer.write_u8(Network.REQUEST_PLAYER_RESPAWN)
	buffer.write_u8(player_to_respawn_id)
	_send_packet(buffer)

func _request_player_change_team():
	print("===REQUEST PLAYER CHANGE TEAM===")
	var buffer : MyBuffer
	buffer = MyBuffer.new()
	buffer.write_u8(Network.REQUEST_PLAYER_CHANGE_TEAM)
	_send_packet(buffer)

func _request_player_sonic():
	print("===REQUEST PLAYER SONIC===")
	var buffer : MyBuffer
	buffer = MyBuffer.new()
	buffer.write_u8(Network.REQUEST_PLAYER_SONIC)
	_send_packet(buffer)

func _player_chat():
	print("===PLAYER CHAT===")
	var text = input_chat.text
	if text == "":
		return
		
	input_chat.text = ""
		
	var buffer : MyBuffer
	buffer = MyBuffer.new()
	buffer.write_u8(Network.CHAT_MESSAGE)
	buffer.write_string(text)

	_send_packet(buffer)

func _ping():
	var timestamp_now = Time.get_ticks_msec()
	
	var buffer : MyBuffer
	buffer = MyBuffer.new()
	buffer.write_u8(Network.PING)
	buffer.write_u64(timestamp_now)
	_send_packet(buffer)


# --- [ RESPOSTAS DO SERVIDOR ] --- #
func _handle_player_updated(buffer):
	print("===PLAYER UPDATED===")
	
	var player_data = PlayerData.new()
	player_data.id = buffer.read_u8()
	
	var mask = buffer.read_u8()
	print("MASK: ", mask)
	
	# ====         BITMASK         === #
	var BIT_X            = 1 << 0 # 0000 0001
	var BIT_Y            = 1 << 1 # 0000 0010
	var BIT_IS_ALIVE     = 1 << 2 # 0000 0100
	var BIT_HP           = 1 << 3 # 0000 1000
	var BIT_TEAM_ID      = 1 << 4 # 0001 0000
	var BIT_TEAM         = 1 << 5 # 0010 0000
	var BIT_TOTAL_KILLS  = 1 << 6 # 0010 0000
	
	
	if BIT_X & mask:
		player_data.x = buffer.read_u16()
	if BIT_Y & mask:
		player_data.y = buffer.read_u16()
	if BIT_IS_ALIVE & mask:
		player_data.is_alive = buffer.read_u8()
	if BIT_HP & mask:
		player_data.hp = buffer.read_u8()
	if BIT_TEAM_ID & mask:
		player_data.team_id = buffer.read_u8()
	if BIT_TEAM & mask:
		player_data.team = buffer.read_string()
	if BIT_TOTAL_KILLS & mask:
		player_data.total_kills = buffer.read_u16()
		
	emit_signal("player_updated", player_data)
		
	

func _handle_player_connected(buffer):
	print("===PLAYER CONNECTED===")
	status_screen.text = "Conectado"
	chat_screen.show()
	ranking_screen.show()
	output_container.show()
	
	var player_data = PlayerData.new()
	player_data.id = buffer.read_u8()
	player_data.x = buffer.read_u16()
	player_data.y = buffer.read_u16()
	player_data.team_id = buffer.read_u8()
	player_data.team = buffer.read_string()
	player_data.is_alive = buffer.read_u8()
	player_data.hp = buffer.read_u8()
	
	my_id = player_data.id
	
	emit_signal("player_connected", player_data)
	

func _handle_other_player_connected(buffer):
	print("===OTHER PLAYER CONNECTED===")
	
	var other_player_data = PlayerData.new()
	other_player_data.id = buffer.read_u8()
	other_player_data.x = buffer.read_u16()
	other_player_data.y = buffer.read_u16()
	other_player_data.team_id = buffer.read_u8()
	other_player_data.team = buffer.read_string()
	other_player_data.is_alive = buffer.read_u8()
	other_player_data.hp = buffer.read_u8()
	
	emit_signal("other_player_connected", other_player_data)

func _handle_other_player_disconnected(buffer):
	print("===OTHER PLAYER DISCONNECTED===")
	var other_player_id = buffer.read_u8()
	emit_signal("other_player_disconnected", other_player_id)

func _handle_other_player_moved(buffer):
	print("===OTHER PLAYER MOVED===")
	var move_x = buffer.read_u16()
	var move_y = buffer.read_u16()
	var other_player_id = buffer.read_u8()
	emit_signal("other_player_moved", move_x, move_y, other_player_id)

func _handle_player_shoot(buffer):
	print("===PLAYER SHOOT===")
	var shooter_id = buffer.read_u8()
	emit_signal("player_shoot", shooter_id)
	
'''		
func _handle_other_player_shoot(buffer):
	print("===OTHER PLAYER SHOOT===")
	var other_player_id = buffer.read_u8()
	emit_signal("other_player_shoot", other_player_id)
	

func _handle_player_damaged(buffer):
	print("===PLAYER DAMAGED===")
	var player_damaged_id = buffer.read_u8()
	var player_damager_id = buffer.read_u8()
	var damage = buffer.read_u8()
	var player_hp = buffer.read_u8()
	emit_signal("player_damaged", player_damaged_id, player_damager_id, damage, player_hp)
	
func _handle_player_killed(buffer):
	print("===PLAYER KILLED===")
	var player_damaged_id = buffer.read_u8()
	var player_damager_id = buffer.read_u8()
	var damage = buffer.read_u8()
	var player_is_alive = buffer.read_u8()
	var player_hp = buffer.read_u8()
	emit_signal("player_killed", player_damaged_id, player_damager_id, damage, player_is_alive, player_hp)

func _handle_player_respawned(buffer):
	print("===PLAYER RESPAWNED===")
	var player_respawned_id = 	buffer.read_u8()
	var player_respawned_x = buffer.read_u16()
	var player_respawned_y = buffer.read_u16()
	emit_signal("player_respawned", player_respawned_id, player_respawned_x, player_respawned_y)
 
func _handle_player_changed_team(buffer):
	print("===PLAYER CHANGED TEAM===")
	var player_changed_team_id = buffer.read_u8()
	emit_signal("player_changed_team", player_changed_team_id)
'''

func _handle_player_sonicked(buffer):
	print("===PLAYER SONICKED===")
	var player_sonicked_id = buffer.read_u8()
	emit_signal("player_sonicked", player_sonicked_id)
	
func _handle_ranking_updated(buffer):
	var ranking_text_received = buffer.read_string()
	ranking_screen.text = ranking_text_received


func _handle_chat_received(buffer):
	
	var text_received = buffer.read_string()
	
	print("Texto recebido: ", text_received)
	
	output_chat.text += (text_received+"\n")
	
func _handle_pong(buffer):
	var timestamp_received = buffer.read_u64()
	var timestamp_now = Time.get_ticks_msec()
	var ping = timestamp_now - timestamp_received
	
	#print("HANDLE: ", timestamp_received)
	#print("HANDLE: ", timestamp_now)
	
	
	ping_screen.text = str(ping)+"ms"
	
	
func _on_input_text_submitted(new_text: String) -> void:
	_player_chat()

# --- [ SINAIS RECEBIDOS ] --- #

func _on_main_game_player_moved(x: Variant, y: Variant, id: Variant) -> void:
	var buffer : MyBuffer
	buffer = MyBuffer.new()
	buffer.clear()
	buffer.seek(0)
	buffer.write_u8(Network.REQUEST_PLAYER_MOVE)
	buffer.write_u16(x)
	buffer.write_u16(y)
	buffer.write_u8(my_id)
	
	_send_packet(buffer)

func _on_player_move_pressed(x: Variant, y: Variant) -> void:
	_request_player_move(x, y)
	
func _on_player_shoot_pressed(id: Variant) -> void:
	_request_player_shoot()
	
func _on_player_damage_report(player_damaged_id: Variant, player_damager_id: Variant, damage_value: Variant):
	_request_player_damage(player_damaged_id, player_damager_id, damage_value)

func _on_respawn_pressed(player_to_respawn_id):
	_request_player_respawn(player_to_respawn_id)
	
func _on_player_change_team_pressed():
	_request_player_change_team()
	
func _on_player_sonic_pressed():
	_request_player_sonic()

func _on_ping_timer_timeout() -> void:
	_ping() # Replace with function body.
