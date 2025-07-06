extends Node2D
@export var player_scene: PackedScene
@export var enemy_scene: PackedScene

@onready var client = $"../Client"
@onready var mob_spawn_timer = $"../MobSpawnTimer"

# Dictionary ID : Player Instance
var my_id = -1
var players_connected = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

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
		# Ligando sinais do player no client
		new_player.move_pressed.connect(client._on_player_move_pressed)
		new_player.shoot_pressed.connect(client._on_player_shoot_pressed)
		#new_player.damage_report.connect(client._on_player_damage_report)
		new_player.respawn_pressed.connect(client._on_respawn_pressed)
		new_player.change_team_pressed.connect(client._on_player_change_team_pressed)
		new_player.sonic_pressed.connect(client._on_player_sonic_pressed)
		client.focus_changed.connect(new_player._on_client_focus_changed)

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


func _on_client_player_shoot(shooter_id, bullet_speed, bullet_direction) -> void:
	players_connected[shooter_id].shoot(bullet_speed, bullet_direction)


func _on_client_player_damaged(damaged_id: Variant, damager_id: Variant, damage: Variant, player_hp: Variant) -> void:
	players_connected[damaged_id].hp = player_hp
	#players_connected[damaged_id].take_damage()
	


func _on_client_player_killed(killed_id: Variant, damager_id: Variant, damage: Variant, player_is_alive, player_hp: Variant) -> void:
	players_connected[killed_id].hp = player_hp
	players_connected[killed_id].is_alive = player_is_alive
	
	# Não descartei a ideia de chamar animações por aqui
	


func _on_client_player_respawned(player_respawned_id: Variant, player_respawned_x: Variant, player_respawned_y: Variant) -> void:
	#players_connected[player_respawned_id].respawn(player_respawned_x, player_respawned_y)
	pass


func _on_client_player_changed_team(player_changed_team_id: Variant) -> void:
	players_connected[player_changed_team_id].change_team()


func _on_client_player_sonicked(player_sonicked_id: Variant) -> void:
	players_connected[player_sonicked_id].sonic()


func _on_client_player_updated(player_data: PlayerData) -> void:
	players_connected[player_data.id].setup(player_data)


func _on_client_rat_attacked() -> void:
	spawn_enemy()
	
