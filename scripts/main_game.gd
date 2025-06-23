extends Node2D
@export var player_scene: PackedScene
@export var enemy_scene: PackedScene

@onready var client = $"../Client"

# Dictionary ID : Player Instance
var my_id = -1
var players_connected = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass
	
	
			#players_connected[my_id].position = mouse_position
			
			#emit_signal("player_moved", x, y, my_id)
			
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
	

func spawn_player(player_data):
	var new_player = player_scene.instantiate()
	
	
	new_player.id = player_data.id
	new_player.position.x = player_data.x
	new_player.position.y = player_data.y
	new_player.team_id = player_data.team_id
	new_player.is_alive = player_data.is_alive
	new_player.hp = player_data.hp
	
	new_player.is_my_player = (my_id == player_data.id)
	
	players_connected[new_player.id] = new_player
	
	new_player.show_info()

	add_child(new_player)
	
	if(new_player.is_my_player):
		# Ligando sinais do player no client
		new_player.move_pressed.connect(client._on_player_move_pressed)
		new_player.shoot_pressed.connect(client._on_player_shoot_pressed)
		new_player.damage_report.connect(client._on_player_damage_report)
		new_player.respawn_pressed.connect(client._on_respawn_pressed)
		new_player.change_team_pressed.connect(client._on_player_change_team_pressed)



# --- [ SINAIS RECEBIDOS ] --- #


func _on_client_player_connected(player_data: PlayerData) -> void:
	my_id = player_data.id
	spawn_player(player_data)


func _on_client_other_player_connected(other_player_data: PlayerData) -> void:
	spawn_player(other_player_data)

func _on_client_other_player_disconnected(other_player_id: Variant) -> void:
	players_connected[other_player_id].queue_free()
	players_connected.erase(other_player_id)


func _on_client_player_moved(player_x: Variant, player_y: Variant) -> void:
	players_connected[my_id].position.x = player_x
	players_connected[my_id].position.y = player_y




func _on_client_other_player_moved(other_player_x: Variant, other_player_y: Variant, other_player_id: Variant) -> void:
	players_connected[other_player_id].position.x = other_player_x
	players_connected[other_player_id].position.y = other_player_y


func _on_client_player_shoot() -> void:
	players_connected[my_id].shoot()


func _on_client_other_player_shoot(other_player_id: Variant) -> void:
	players_connected[other_player_id].shoot()


func _on_client_player_damaged(damaged_id: Variant, damager_id: Variant, damage: Variant) -> void:
	players_connected[damaged_id].take_damage(damaged_id, damager_id, damage)


func _on_client_player_killed(killed_id: Variant) -> void:
	players_connected[killed_id].kill()


func _on_client_player_respawned(player_respawned_id: Variant, player_respawned_x: Variant, player_respawned_y: Variant) -> void:
	players_connected[player_respawned_id].respawn(player_respawned_x, player_respawned_y)


func _on_client_player_changed_team(player_changed_team_id: Variant) -> void:
	players_connected[player_changed_team_id].change_team()
