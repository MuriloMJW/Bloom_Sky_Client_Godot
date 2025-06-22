extends Node

signal player_connected(player_x, player_y, player_id)
signal other_player_connected(other_player_x, other_player_y, other_player_id)
signal other_player_disconnected(other_player_id)
signal player_moved(player_x, player_y, id)
signal other_player_moved(other_player_x, other_player_y, other_player_id)
signal player_shoot()
signal player_killed(killed_id)
signal player_respawned(player_respawned_id, player_respawned_x, player_respawned_y)
signal other_player_shoot(other_player_id)


#var websocket_url = "ws://127.0.0.1:8080"
#var websocket_url = "ws://127.0.0.1:9913"
var websocket_url = "wss://3ae453be-0bb5-4226-9e4d-e6a65193784a-00-2juxj2mj683q2.janeway.replit.dev/"

var socket := WebSocketPeer.new()
var last_state = WebSocketPeer.STATE_CLOSED
var my_id = -1

@onready var chat_screen = $Control/VBoxContainer
@onready var input_chat = $Control/VBoxContainer/Input
@onready var output_chat = $Control/VBoxContainer/OutputContainer/MarginContainer/Output
@onready var status_screen = $Control/PanelContainer/MarginContainer2/Status

enum Network {
	# Client -> Server
	REQUEST_CONNECT = 0,
	
	REQUEST_PLAYER_MOVE = 1,
	
	REQUEST_PLAYER_SHOOT = 2,
	REQUEST_PLAYER_DAMAGE = 3,
	REQUEST_PLAYER_RESPAWN = 4,
	
	CHAT_MESSAGE = 100,
	
	# Server -> Client
	PLAYER_CONNECTED = 100,
	OTHER_PLAYER_CONNECTED = 101,
	OTHER_PLAYER_DISCONNECTED = 102,
	
	PLAYER_MOVED = 103,
	OTHER_PLAYER_MOVED = 104,
	
	PLAYER_SHOOT = 105,
	OTHER_PLAYER_SHOOT = 106,
	#PLAYER_DAMAGED = 107,
	PLAYER_KILLED = 108,
	PLAYER_RESPAWNED = 109,
	
	CHAT_RECEIVED = 200
}



func _ready() -> void:
	chat_screen.hide()
	socket.connect_to_url(websocket_url)

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
			status_screen.text = "Desconectado"
			
	
	return
			
func _on_state_open():
	print("OPEN!")
	status_screen.text = "OPEN"
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
	
	var buffer : StreamPeerBuffer
	buffer = StreamPeerBuffer.new()
	buffer.data_array = packet
	
	var msgid = buffer.get_u8()
	
	match msgid:
		Network.PLAYER_CONNECTED:
			_handle_player_connected(buffer)
			
		Network.OTHER_PLAYER_CONNECTED:
			_handle_other_player_connected(buffer)
			
		Network.OTHER_PLAYER_DISCONNECTED:
			_handle_other_player_disconnected(buffer)
			
		Network.PLAYER_MOVED:
			_handle_player_moved(buffer)
			
		Network.OTHER_PLAYER_MOVED:
			_handle_other_player_moved(buffer)
			
		Network.PLAYER_SHOOT:
			_handle_player_shoot(buffer)
			
		Network.OTHER_PLAYER_SHOOT:
			_handle_other_player_shoot(buffer)
			
		Network.PLAYER_KILLED:
			_handle_player_killed(buffer)
			
		Network.PLAYER_RESPAWNED:
			_handle_player_respawned(buffer)

		Network.CHAT_RECEIVED:
			_handle_chat_received(buffer)
			
			
		_:
			print("PACOTE NÃO TRATADO: ", msgid)
			


# --- [ PEDIDOS AO SERVIDOR ] --- #

func _request_connect():
	print("===REQUEST CONNECT===")
	var buffer : StreamPeerBuffer
	buffer = StreamPeerBuffer.new()
	buffer.put_u8(Network.REQUEST_CONNECT)
	_send_packet(buffer)
	
func _request_player_move(move_x, move_y):
	print("===REQUEST PLAYER MOVE===")
	var buffer : StreamPeerBuffer
	buffer = StreamPeerBuffer.new()
	buffer.put_u8(Network.REQUEST_PLAYER_MOVE)
	buffer.put_u16(move_x)
	buffer.put_u16(move_y)
	_send_packet(buffer)
	
func _request_player_shoot():
	print("===REQUEST PLAYER SHOOT===")
	var buffer : StreamPeerBuffer
	buffer = StreamPeerBuffer.new()
	buffer.put_u8(Network.REQUEST_PLAYER_SHOOT)
	_send_packet(buffer)
	
func _request_player_damage(player_damaged_id, player_damager_id, damage_value):
	print("===REQUEST PLAYER DAMAGE===")
	var buffer : StreamPeerBuffer
	buffer = StreamPeerBuffer.new()
	buffer.put_u8(Network.REQUEST_PLAYER_DAMAGE)
	buffer.put_u8(player_damaged_id)
	buffer.put_u8(player_damager_id)
	buffer.put_u8(damage_value)
	_send_packet(buffer)

func _request_player_respawn(player_to_respawn_id):
	print("===REQUEST PLAYER DAMAGE===")
	var buffer : StreamPeerBuffer
	buffer = StreamPeerBuffer.new()
	buffer.put_u8(Network.REQUEST_PLAYER_RESPAWN)
	buffer.put_u8(player_to_respawn_id)
	_send_packet(buffer)

func _player_chat():
	print("===PLAYER CHAT===")
	var text = input_chat.text
	if text == "":
		return
		
	input_chat.text = ""
		
	var buffer : StreamPeerBuffer
	buffer = StreamPeerBuffer.new()
	
	
	buffer.put_u8(Network.CHAT_MESSAGE)
	
	var text_bytes = text.to_ascii_buffer()
	text_bytes.append(0) 
	print(text_bytes)
	buffer.put_data(text_bytes)

	_send_packet(buffer)
	
	
# --- [ RESPOSTAS DO SERVIDOR ] --- #

func _handle_player_connected(buffer):
	print("===PLAYER CONNECTED===")
	status_screen.text = "Conectado!"
	chat_screen.show()
	
	var start_x = buffer.get_u16()
	var start_y = buffer.get_u16()
	my_id = buffer.get_u8()
	
	emit_signal("player_connected", start_x, start_y, my_id)
	

func _handle_other_player_connected(buffer):
	print("===OTHER PLAYER CONNECTED===")
	var start_x = buffer.get_u16()
	var start_y = buffer.get_u16()
	var other_player_id = buffer.get_u8()
	emit_signal("other_player_connected", start_x, start_y, other_player_id)

func _handle_other_player_disconnected(buffer):
	print("===OTHER PLAYER DISCONNECTED===")
	var other_player_id = buffer.get_u8()
	emit_signal("other_player_disconnected", other_player_id)

func _handle_player_moved(buffer):
	print("===PLAYER MOVED===")
	var move_x = buffer.get_u16()
	var move_y = buffer.get_u16()
	var player_id = buffer.get_u8()
	emit_signal("player_moved", move_x, move_y, player_id)

func _handle_other_player_moved(buffer):
	print("===OTHER PLAYER MOVED===")
	var move_x = buffer.get_u16()
	var move_y = buffer.get_u16()
	var other_player_id = buffer.get_u8()
	emit_signal("other_player_moved", move_x, move_y, other_player_id)

func _handle_player_shoot(buffer):
	print("===PLAYER SHOOT===")
	emit_signal("player_shoot")
	
func _handle_other_player_shoot(buffer):
	print("===OTHER PLAYER SHOOT===")
	var other_player_id = buffer.get_u8()
	emit_signal("other_player_shoot", other_player_id)
	
func _handle_player_killed(buffer):
	print("===PLAYER KILLED===")
	var player_killed_id = 	buffer.get_u8()
	emit_signal("player_killed", player_killed_id)

func _handle_player_respawned(buffer):
	print("===PLAYER RESPAWNED===")
	var player_respawned_id = 	buffer.get_u8()
	var player_respawned_x = buffer.get_u16()
	var player_respawned_y = buffer.get_u16()
	emit_signal("player_respawned", player_respawned_id, player_respawned_x, player_respawned_y)

func _handle_chat_received(buffer):
	#var text_received = socket.get_packet().get_string_from_ascii()
	var string_size = buffer.get_size() - buffer.get_position()
	var text_received = buffer.get_utf8_string(string_size)
	print("Texto recebido: ", text_received)
	
	output_chat.text += (text_received+"\n")
	
	
	
func _on_input_text_submitted(new_text: String) -> void:
	_player_chat()

# --- [ SINAIS RECEBIDOS ] --- #

func _on_main_game_player_moved(x: Variant, y: Variant, id: Variant) -> void:
	var buffer : StreamPeerBuffer
	buffer = StreamPeerBuffer.new()
	buffer.clear()
	buffer.seek(0)
	buffer.put_u8(Network.REQUEST_PLAYER_MOVE)
	buffer.put_u16(x)
	buffer.put_u16(y)
	buffer.put_u8(my_id)
	
	_send_packet(buffer)

func _on_player_move_pressed(x: Variant, y: Variant) -> void:
	_request_player_move(x, y)
	
func _on_player_shoot_pressed(id: Variant) -> void:
	_request_player_shoot()
	
func _on_player_damage_report(player_damaged_id: Variant, player_damager_id: Variant, damage_value: Variant):
	_request_player_damage(player_damaged_id, player_damager_id, damage_value)

func _on_respawn_pressed(player_to_respawn_id):
	_request_player_respawn(player_to_respawn_id)
