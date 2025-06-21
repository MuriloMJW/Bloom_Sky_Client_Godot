extends Area2D

signal move

signal player_died(id)
signal player_shoot(id)

var id
var start_x
var start_y

var bullet_scene = load("res://bullet.tscn")

var is_my_player = false
var is_team_up = true

var is_alive = false

func _ready():
	is_alive = true
	$CollisionShape2D.disabled = false
	$ColorRect.show()
	$username.show()
	$username.text = str(id)
	
	if(is_my_player):
		emit_signal("shoot", id)
		
	

func _process(delta):
	#var player_position = Vector2(get_global_mouse_position().x,  start_y)
	#position = player_position
	#print(player_position)
	
	if(is_my_player and is_alive):
		if(Input.is_action_just_pressed("shoot")):
			
			var mouse_position = get_global_mouse_position()
			var x = mouse_position.x
			var y = mouse_position.y
			position = mouse_position
			
			
			
	
	if(Input.is_action_just_pressed("shoot")):
		shoot()
	
func show_info():
	print("===PLAYER INFO===")
	print("ID: ", self.id,
		  " X: ", self.position.x,
		  " Y: ", self.position.y)


func shoot():
	if(is_my_player and is_alive):
		var bullet = bullet_scene.instantiate()
		bullet.position = position
		bullet.is_moving_up = is_team_up
		bullet.shooter_id = id
		get_parent().add_child(bullet)
		
		emit_signal("player_shoot", id)
		
	
func _on_area_entered(area: Area2D) -> void:
	
	if(is_my_player and area.is_in_group("bullet") and area.shooter_id != id):
		print("GOT HIT=======================")


func die():
	set_process(false)
	is_alive = false
	$CollisionShape2D.disabled = true
	$ColorRect.hide()
	$username.hide()
	
	emit_signal("player_died", id)
	
func respawn(x, y):
	set_process(true)
	is_alive = true
	$CollisionShape2D.disabled = false
	$ColorRect.show()
	$username.show()


func _on_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
