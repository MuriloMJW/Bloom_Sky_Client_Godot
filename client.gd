extends Node

var websocket_url = "ws://127.0.0.1:8080"
#var websocket_url = "wss://3ae453be-0bb5-4226-9e4d-e6a65193784a-00-2juxj2mj683q2.janeway.replit.dev/"

var socket := WebSocketPeer.new()
var last_state = WebSocketPeer.STATE_CLOSED

var my_id = -1

@onready var chat_screen = $Control/VBoxContainer
@onready var input_chat = $Control/VBoxContainer/Input
@onready var output_chat = $Control/VBoxContainer/OutputContainer/MarginContainer/Output


enum Network {
	PLAYER_ESTABLISH,
	PLAYER_CONNECT,
	PLAYER_JOINED,
	PLAYER_DISCONNECT,
	PLAYER_MOVE,
	CHAT
}

signal player_connected(id, x, y)

func _ready() -> void:
	chat_screen.hide()
	
	socket.connect_to_url(websocket_url)

func _process(delta: float) -> void:
	# Envia e recebe frames inicias de abertura (HTTP -> Websocket)
	socket.poll()
	
	var state = socket.get_ready_state()
	
	_state_changed()
	
	if(state == socket.STATE_OPEN):
		_wait_packets()
	
	
	
func _state_changed():
	var state = socket.get_ready_state()
	
	if(state == last_state):
		return false
	
	last_state = state
	
	match state:
		
		socket.STATE_CONNECTING:
			print("CONNECTING...")
			output_chat.text = "Conectando..."
				
		socket.STATE_OPEN:
			print("CONNECTED!")
			output_chat.text = "Conectado"
			
		socket.STATE_CLOSING:
			print("CLOSING...")
			output_chat.text = "Desconectando..."
				
		socket.STATE_CLOSED:
			print("CLOSED")
			output_chat.text = "Desconectado"
			
	
	return true
			

func _wait_packets():
	while (socket.get_available_packet_count() > 0):
		receive_packet(socket.get_packet())
	

func _on_input_text_submitted(new_text: String) -> void:
	var text = input_chat.text
	
	if text == "":
		return
		
	input_chat.text = ""
		
	var buffer : StreamPeerBuffer
	buffer = StreamPeerBuffer.new()
	
	
	buffer.put_u8(Network.CHAT)
	
	var text_bytes = text.to_ascii_buffer()
	text_bytes.append(0)
	print(text_bytes)
	buffer.put_data(text_bytes)
	

	_send_packet(buffer)
	

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
		Network.PLAYER_ESTABLISH:
			_handle_player_establish(buffer)
			
		Network.PLAYER_CONNECT:
			_handle_player_connect(buffer)
			
		Network.PLAYER_JOINED:
			print(2)
		Network.PLAYER_DISCONNECT:
			print(3)
		Network.PLAYER_MOVE:
			print(4)
		Network.CHAT:
			_handle_chat(buffer)
			
func _send_packet(buffer):
	print("===ENVIANDO PACKET===")
	print(buffer.data_array)
	socket.send(buffer.data_array)
	
	
func _handle_player_establish(buffer):
	print("===PLAYER ESTABLISH===")
	my_id = buffer.get_u8()
	chat_screen.show()
	
	
	buffer.clear()
	buffer.seek(0)
	buffer.put_u8(Network.PLAYER_ESTABLISH)
	buffer.put_u8(my_id)
	_send_packet(buffer)

func _handle_player_connect(buffer):
	print("===PLAYER CONNECT===")
	var start_x = buffer.get_u16()
	var start_y = buffer.get_u16()
	print("START X ", start_x)
	emit_signal("player_connected", my_id, start_x, start_y)




func _handle_chat(buffer):
	#var text_received = socket.get_packet().get_string_from_ascii()
	var string_size = buffer.get_size() - buffer.get_position()
	var text_received = buffer.get_utf8_string(string_size)
	print("Texto recebido: ", text_received)
	
	output_chat.text += ("\n"+text_received)
	
