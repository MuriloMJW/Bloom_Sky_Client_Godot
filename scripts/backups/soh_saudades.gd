extends Node
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


Movimento do player no mouse

	'''
		if(Input.is_action_just_pressed("mouse_click")):
			var mouse_position = get_global_mouse_position()
			var x = mouse_position.x
			var y = mouse_position.y
			#position = mouse_position
			
			emit_signal("move_pressed", x, y)
		'''
		
		
func handle_movement_input_game_loop_mode(delta):
	var movement = (Input.get_vector("move_left", "move_right", "move_forward", "move_backward"))
	# Se apertar pra esquerda    o movement recebe (-1, 0)
	# Se apertar para cima       o movement recebe (0, -1)
	# Se apertar esquerda e cima o movement recebe (-0.75, -0.75)
	
	#print("AUTH POS: ", authoritative_position)
	#print("MY POS: ", position)
	#authoritative_cube.hide()
	if(last_sent_movement != movement):
		#position += movement * speed * 1.0/30.0
		emit_signal("move_pressed", movement.x, movement.y)
		last_sent_movement = movement

	#if(movement != Vector2.ZERO):
	position += movement * speed * delta
	authoritative_cube.position.x = authoritative_position.x
	authoritative_cube.position.y = authoritative_position.y
	
	if position.distance_to(authoritative_position) > 0.01:
		position = position.lerp(authoritative_position, 1)
	
