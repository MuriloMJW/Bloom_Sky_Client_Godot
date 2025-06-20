extends Area2D

signal move

var id
var start_x
var start_y

var bullet_scene = load("res://bullet.tscn")


func _ready():
	#start_x = get_viewport().get_visible_rect().size.x / 2
	#start_y = get_viewport().get_visible_rect().size.y - 30
	#position = Vector2(start_x, start_y)
	
	$username.text = str(id)
	

func _process(delta):
	#var player_position = Vector2(get_global_mouse_position().x,  start_y)
	#position = player_position
	#print(player_position)
	
	if(Input.is_action_just_pressed("shoot")):
		shoot()
	
	
func shoot():
	var bullet = bullet_scene.instantiate()
	bullet.position = position
	get_parent().add_child(bullet)
	
	


func _on_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
