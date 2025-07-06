extends Area2D


var speed
var shooter_id = -1
var velocity = Vector2()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#if(!is_moving_up):
	#	speed *= -1
	#print(is_moving_up)
	print("BULLET DIRECTION: ", self.rotation_degrees)
	
	velocity = Vector2.UP.rotated(rotation) * speed
	
	rotation = 0

func _physics_process(delta):
		position += velocity * delta
	
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if(area.get_parent().id != shooter_id):
			queue_free()
			
	if area.is_in_group("enemy"):
		queue_free()
	
	if area.is_in_group("bullet"):
		if(area.shooter_id != shooter_id):
			queue_free()
		


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
