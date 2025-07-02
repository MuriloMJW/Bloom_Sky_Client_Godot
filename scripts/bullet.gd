extends Area2D

@export
var speed = 500
var shooter_id = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#if(!is_moving_up):
	#	speed *= -1
	#print(is_moving_up)
	print("BULLET DIRECTION: ", self.rotation_degrees)

func _physics_process(delta):
		position -= transform.y * speed * delta
	
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if(area.id != shooter_id):
			queue_free()
		


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
