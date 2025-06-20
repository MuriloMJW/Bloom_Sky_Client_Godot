extends Node2D
@export var player_scene: PackedScene
@export var enemy_scene: PackedScene

signal player_moved(x, y, id)

# Dictionary ID : Player Instance
var my_id = -1
var players_connected = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(my_id != -1):
		if(Input.is_action_just_pressed("shoot")):
			
			var mouse_position = get_global_mouse_position()
			var x = mouse_position.x
			var y = mouse_position.y
			#players_connected[my_id].position = mouse_position
			
			emit_signal("player_moved", x, y, my_id)
			
		#var mouse_position = get_global_mouse_position()
		
		#players_connected[my_id].position = mouse_position
		#var x = mouse_position.x
		#var y = mouse_position.y
		#emit_signal("player_moved", x, y, my_id)

func _on_mob_spawn_timer_timeout() -> void:
	spawn_enemy()
	
		
func spawn_enemy():
	var spawn_x = randi_range(0, get_viewport().get_visible_rect().size.x)
	var spawn_y = 0
	var enemy = enemy_scene.instantiate()
	enemy.position.x = spawn_x
	enemy.position.y = spawn_y
	
	add_child(enemy)
	

func spawn_player(spawn_x, spawn_y, id):
	var new_player = player_scene.instantiate()
	
	new_player.position.x = spawn_x
	new_player.position.y = spawn_y
	new_player.id = id
	
	players_connected[id] = new_player
	
	new_player.show_info()
	
	add_child(new_player)



# --- [ SINAIS RECEBIDOS ] --- #


func _on_client_player_connected(player_x: Variant, player_y: Variant, player_id: Variant) -> void:
	my_id = player_id
	spawn_player(player_x, player_y, player_id)


func _on_client_other_player_connected(other_player_x: Variant, other_player_y: Variant, other_player_id: Variant) -> void:
	spawn_player(other_player_x, other_player_y, other_player_id)


func _on_client_other_player_disconnected(other_player_id: Variant) -> void:
	players_connected[other_player_id].queue_free()
	players_connected.erase(other_player_id)


func _on_client_player_moved(player_x: Variant, player_y: Variant, id: Variant) -> void:
	players_connected[id].position.x = player_x
	players_connected[id].position.y = player_y


func _on_client_other_player_moved(other_player_x: Variant, other_player_y: Variant, other_player_id: Variant) -> void:
	players_connected[other_player_id].position.x = other_player_x
	players_connected[other_player_id].position.y = other_player_y
