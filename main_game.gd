extends Node2D
@export var player_scene: PackedScene
@export var enemy_scene: PackedScene

signal player_moved(x, y, id)

# Dictionary ID : Instance
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
			players_connected[my_id].position = mouse_position
			emit_signal("player_moved", x, y, my_id)
			
		#var mouse_position = get_global_mouse_position()
		
		#players_connected[my_id].position = mouse_position
		#var x = mouse_position.x
		#var y = mouse_position.y
		#emit_signal("player_moved", x, y, my_id)


func _on_mob_spawn_timer_timeout() -> void:
	spawn_enemy()
	
func spawn_player(spawn_x, spawn_y, id):
	var player = player_scene.instantiate()
	player.id = id
	player.position.x = spawn_x
	player.position.y = spawn_y
	
	players_connected[id] = player
	print("Spawnando player: ", player.id,
						 " X: ", player.position.x,
						 " Y: ", player.position.y)
	add_child(player)
		
func spawn_enemy():
	var spawn_x = randi_range(0, get_viewport().get_visible_rect().size.x)
	var spawn_y = 0
	var enemy = enemy_scene.instantiate()
	enemy.position.x = spawn_x
	enemy.position.y = spawn_y
	
	add_child(enemy)
	
func _move_players(x, y, id):
	pass



func _on_client_player_joined(x: Variant, y: Variant, id: Variant) -> void:
	print("Spawnando OUTRO player")
	spawn_player(x, y, id)

func _on_client_player_moved(x: Variant, y: Variant, id: Variant) -> void:
	players_connected[id].position = Vector2(x, y)


func _on_client_player_connected(x: Variant, y: Variant, id: Variant) -> void:
	spawn_player(x, y, id)
	my_id = id


func _on_client_player_disconnected(id: Variant) -> void:
	players_connected[id].queue_free()
	players_connected.erase(id)
	
