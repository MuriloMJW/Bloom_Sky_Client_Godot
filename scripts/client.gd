extends Node

@onready var ping_timer: Timer = $PingTimer

# Conectam no main menu
signal auth_success
signal auth_fail

# Conectam no Game
#signal login_successful
signal player_connected(player_data: PlayerData)
signal other_player_connected(player_data: PlayerData)
signal other_player_disconnected(other_player_id)
signal player_shoot(player_id, speed, direction)
signal player_sonicked(player_sonicked_id)
signal player_updated(player_data: PlayerData)
signal rat_attacked()

# Hud do Game
signal connection_status_updated(connection_status_text: String)
signal ping_updated(ping_text: String)
signal chat_updated(chat_text: String)
signal ranking_updated(ranking_text: String)


var websocket_url = "ws://127.0.0.1:9913"
#var websocket_url = "wss://3ae453be-0bb5-4226-9e4d-e6a65193784a-00-2juxj2mj683q2.janeway.replit.dev/"
#var websocket_url = "ws://127.0.0.1:8080"
#var websocket_url = "wss://organic-potato-wvrj76v76g6hv7x-8080.app.github.dev/"

var debug_send_packet = false
var debug_received_packet = false
var ping_paused = false

var socket := WebSocketPeer.new()
var last_state = WebSocketPeer.STATE_CLOSED

var my_id = -1

var connection_status_text = "Null"
#var my_player_data_cache: PlayerData = null
#var other_player_data_cache: Array[PlayerData] = []

enum Network {
	# === Client -> Server ===
	REQUEST_AUTH = 0,
	REQUEST_CONNECT = 1,
	
	REQUEST_PLAYER_MOVE = 2,
	
	REQUEST_PLAYER_SHOOT = 3,
	REQUEST_PLAYER_DAMAGE = 4,
	REQUEST_PLAYER_RESPAWN = 5,
	REQUEST_PLAYER_CHANGE_TEAM = 6,
	REQUEST_PLAYER_SONIC = 7,
	
	REQUEST_PLAYER_UPDATE = 8,
	
	CHAT_MESSAGE = 100,
	PING = 254,
	
	# === Server -> Client ===
	AUTH_SUCCESS = 65,
	AUTH_FAIL = 66,
	PLAYER_CONNECTED = 67,
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
	PLAYER_SETUP = 113,
	
	RAT_ATTACKED = 198,
	RANKING_UPDATED = 199,
	CHAT_RECEIVED = 200,
	
	PONG = 255
}

func _ready() -> void:
	ping_timer.paused = ping_paused
	socket.connect_to_url(websocket_url)
	
	#input_chat.focus_next
	
func _process(delta: float) -> void:

	# Envia e recebe frames inicias de abertura (HTTP -> Websocket)

	socket.poll()
	
	var state = socket.get_ready_state()
	
	_handle_state_change(state)
	
	if(state == socket.STATE_OPEN):
		_wait_packets()
	#print(input_chat.has_focus())
	#print(get_viewport().gui_get_focus_owner())

	
func _handle_state_change(state):
	
	if(state == last_state):
		return
	
	last_state = state
	
	connection_status_text = "Null"
	match state:
		
		socket.STATE_CONNECTING:
			print("CONNECTING...")
			connection_status_text = "Conectando..."
			
		socket.STATE_OPEN:
			print("OPEN!")
			connection_status_text = "[color=green]Conectado[/color]"
			#_request_connect()
			#_on_state_open()
			
		socket.STATE_CLOSING:
			print("CLOSING...")
			connection_status_text = "Desconectando..."
		socket.STATE_CLOSED:
			print("CLOSED")
			connection_status_text = "[color=red]Desconectado[/color]"
			
	
	emit_signal("connection_status_updated", connection_status_text)
	return
			
func _on_state_open():
	# Emite o sinal para a tela do game para,
	# quando carregada ela enviar o request_connect
	#emit_signal("connection_open") < Tentativa
	#_request_connect()
	pass
	
func _wait_packets():
	while (socket.get_available_packet_count() > 0):
		receive_packet(socket.get_packet())
	
func _send_packet(buffer: MyBuffer):
	var msg_id = buffer.read_u8()
	
	if(socket.get_ready_state() != socket.State.STATE_OPEN):
		print("ERRO: TENTANDO ENVIAR PACKET COM SERVIDOR FECHADO: MSG_ID:", msg_id)
		return
	
	#TODO?
	if my_id == -1 and msg_id != Network.REQUEST_AUTH and msg_id != Network.REQUEST_CONNECT:
		return
	
	if (debug_send_packet):
		print("===ENVIANDO PACKET===")
		print(buffer.data_array)
	socket.send(buffer.data_array)

func receive_packet(packet):
	if (debug_received_packet):
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
		Network.AUTH_SUCCESS:
			emit_signal("auth_success")
		Network.AUTH_FAIL:
			emit_signal("auth_fail")
		Network.PLAYER_CONNECTED:
			_handle_player_connected(buffer)
			
		Network.OTHER_PLAYER_DISCONNECTED:
			_handle_other_player_disconnected(buffer)
			
		Network.PLAYER_SHOOT:
			_handle_player_shoot(buffer)
			
		Network.PLAYER_SONICKED:
			_handle_player_sonicked(buffer)
		
		Network.PLAYER_UPDATED:
			_handle_player_updated(buffer)
			
		Network.RAT_ATTACKED:
			_handle_rat_attacked(buffer)
			
		Network.RANKING_UPDATED:
			_handle_ranking_updated(buffer)
			
		Network.CHAT_RECEIVED:
			_handle_chat_received(buffer)
			
		Network.PONG:
			_handle_pong(buffer)
			
		_:
			print("PACOTE NÃO TRATADO: ", msgid)


# --- [ PEDIDOS AO SERVIDOR ] --- #

func _request_authentication(username : String):
	print("===REQUEST AUTH===")
	var buffer : MyBuffer
	buffer = MyBuffer.new()
	buffer.write_u8(Network.REQUEST_AUTH)
	buffer.write_string(username)
	_send_packet(buffer)

func _request_connect():
	print("===REQUEST CONNECT===")
	var buffer : MyBuffer
	buffer = MyBuffer.new()
	buffer.write_u8(Network.REQUEST_CONNECT)
	_send_packet(buffer)

func _request_player_move(move_x, move_y):
	#print("===REQUEST PLAYER MOVE===")
	var buffer : MyBuffer
	buffer = MyBuffer.new()
	buffer.write_u8(Network.REQUEST_PLAYER_MOVE)
	buffer.write_float(move_x)
	buffer.write_float(move_y)
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

func _request_player_chat(chat_text):
	print("===PLAYER CHAT===")
		
	var buffer : MyBuffer
	buffer = MyBuffer.new()
	buffer.write_u8(Network.CHAT_MESSAGE)
	buffer.write_string(chat_text)

	_send_packet(buffer)

func _ping():
	
	var timestamp_now = Time.get_ticks_msec()
	
	var buffer : MyBuffer
	buffer = MyBuffer.new()
	buffer.write_u8(Network.PING)
	buffer.write_u64(timestamp_now)
	_send_packet(buffer)

# --- [ RESPOSTAS DO SERVIDOR ] --- #
func _handle_player_connected(buffer):
	print("===PLAYER CONNECTED===")
	
	var is_my_player = buffer.read_u8()

	var player_data = PlayerData.new()
	player_data.id = buffer.read_u8()
	
	for attribute_data in player_data.PLAYER_BITMASK_LAYOUT:
		var attribute = attribute_data["attribute"]
		var data_type = attribute_data["data_type"]	
		var attribute_value
		
		match attribute_data["data_type"]:
			"u8":
				attribute_value = buffer.read_u8()
			"u16":
				attribute_value = buffer.read_u16()
			"s16":
				attribute_value = buffer.read_s16()
			"u32":
				attribute_value = buffer.read_u32()
			"u64":
				attribute_value = buffer.read_u64()
			"float":
				attribute_value = buffer.read_float()
			"string":
				attribute_value = buffer.read_string()
			_:
				print("Formato do bitmask layout inválido")
				
		player_data.set(attribute, attribute_value)

	if(is_my_player == Network.PLAYER_CONNECTED):
		my_id = player_data.id
		#my_player_data_cache = player_data
		emit_signal("player_connected", player_data)
		#emit_signal("login_successful")
	else:
		print("===OTHER PLAYER CONNECTED===")
		#other_player_data_cache.append(player_data)
		emit_signal("other_player_connected", player_data)

func _handle_player_updated(buffer):
	#print("===PLAYER UPDATED===")
	
	var player_data = PlayerData.new()
	player_data.id = buffer.read_u8()
	
	var mask = buffer.read_u16()
	#print("MASK: ", mask)

	
	for attribute_data in player_data.PLAYER_BITMASK_LAYOUT:
		if(mask & attribute_data["mask"]):
			var attribute = attribute_data["attribute"]
			var data_type = attribute_data["data_type"]	
			var attribute_value
			
			match attribute_data["data_type"]:
				"u8":
					attribute_value = buffer.read_u8()
				"u16":
					attribute_value = buffer.read_u16()
				"s16":
					attribute_value = buffer.read_u16()
				"u32":
					attribute_value = buffer.read_u32()
				"u64":
					attribute_value = buffer.read_u64()
				"float":
					attribute_value = buffer.read_float()
				"string":
					attribute_value = buffer.read_string()
				_:
					print("Formato do bitmask layout inválido")
					
			
			player_data.set(attribute, attribute_value)

	emit_signal("player_updated", player_data)

func _handle_other_player_disconnected(buffer):
	print("===OTHER PLAYER DISCONNECTED===")
	var other_player_id = buffer.read_u8()
	emit_signal("other_player_disconnected", other_player_id)


func _handle_player_shoot(buffer):
	print("===PLAYER SHOOT===")
	var shooter_id = buffer.read_u8()
	var speed = buffer.read_u16()
	var direction = buffer.read_u16()
	emit_signal("player_shoot", shooter_id, speed, direction)

func _handle_player_sonicked(buffer):
	print("===PLAYER SONICKED===")
	var player_sonicked_id = buffer.read_u8()
	emit_signal("player_sonicked", player_sonicked_id)
	
func _handle_rat_attacked(buffer):
	print("===RAT ATACKED===")
	emit_signal("rat_attacked")
	
	
	
func _handle_ranking_updated(buffer):
	var ranking_text_received = buffer.read_string()
	emit_signal("ranking_updated", ranking_text_received)
	


func _handle_chat_received(buffer):
	
	var text_received = buffer.read_string() + "\n"
	
	print("Texto recebido: ", text_received)
	
	#output_chat.text += (text_received+"\n")
	emit_signal("chat_updated", text_received)
	
func _handle_pong(buffer):
	var timestamp_received = buffer.read_u64()
	var timestamp_now = Time.get_ticks_msec()
	var ping = timestamp_now - timestamp_received
	
	#print("HANDLE: ", timestamp_received)
	#print("HANDLE: ", timestamp_now)
	
	
	var ping_received_text = str(ping)+"ms"
	emit_signal("ping_updated", ping_received_text)
	
	

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
	
