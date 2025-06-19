extends Node
@export var player_scene: PackedScene
@export var enemy_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_mob_spawn_timer_timeout() -> void:
	spawn_enemy()
	
func spawn_player(id, spawn_x, spawn_y):
	var player = player_scene.instantiate()
	player.id = id
	player.position.x = spawn_x
	player.position.y = spawn_y
	
	add_child(player)
		
func spawn_enemy():
	var spawn_x = randi_range(0, get_viewport().get_visible_rect().size.x)
	var spawn_y = 0
	var enemy = enemy_scene.instantiate()
	enemy.position.x = spawn_x
	enemy.position.y = spawn_y
	
	add_child(enemy)




func _on_client_player_connected(id: Variant, x: Variant, y: Variant) -> void:
	spawn_player(id, x, y)
