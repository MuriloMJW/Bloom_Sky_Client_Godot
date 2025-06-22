extends Area2D

signal move_pressed(x, y)
signal shoot_pressed(id)
signal damage_report(damaged_id, damager_id, damage_value)
signal respawn_pressed(id)

var bullet_scene = load("res://bullet.tscn")

var id
var start_x
var start_y

var is_my_player = false
var is_team_up = true
var is_alive = false
var can_move = true

# Fazer uns getters e setter, por ex, set_is_alive,
# se falso, can_move = false, etc

func _ready():
	is_alive = true
	$CollisionShape2D.disabled = false
	$ColorRect.show()
	$username.show()
	$username.text = str(id)
	
		
	

func _process(delta):
	#var player_position = Vector2(get_global_mouse_position().x,  start_y)
	#position = player_position
	#print(player_position)
	
	if(is_my_player and is_alive and can_move):
		if(Input.is_action_just_pressed("shoot")):
			
			var mouse_position = get_global_mouse_position()
			var x = mouse_position.x
			var y = mouse_position.y
			#position = mouse_position
			
			emit_signal("move_pressed", x, y)
			emit_signal("shoot_pressed", id)
	
		if(Input.is_action_just_pressed("die_input")):
			emit_signal("damage_report", id, 123, 100)
			pass
			
	if(is_my_player and !is_alive and Input.is_action_just_pressed("respawn_input")):
		#respawn(position.x, position.y)
		emit_signal("respawn_pressed", id)
		
	
func show_info():
	print("===PLAYER INFO===")
	print("ID: ", self.id,
		  " X: ", self.position.x,
		  " Y: ", self.position.y)


func shoot():
	if(is_alive):
		var bullet = bullet_scene.instantiate()
		bullet.position = position
		bullet.is_moving_up = is_team_up
		bullet.shooter_id = id
		get_parent().add_child(bullet)
		
		
	
func _on_area_entered(area: Area2D) -> void:
	
	if(is_my_player and area.is_in_group("bullet") and area.shooter_id != id):
		print("====GOT HIT=====")
		emit_signal("damage_report", id, area.shooter_id, 100)
		

func kill():
	#set_process(false)
	is_alive = false
	$CollisionShape2D.disabled = true
	$ColorRect.hide()
	$username.hide()
	
	
func respawn(x, y):
	#set_process(true)
	is_alive = true
	$CollisionShape2D.disabled = false
	$ColorRect.show()
	$username.show()
