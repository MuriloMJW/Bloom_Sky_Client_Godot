extends Area2D

@export
var speed = 500
var is_moving_up = true
var shooter_id = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if(!is_moving_up):
		speed *= -1
	print(is_moving_up)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.y -= speed * delta


func _on_area_entered(area: Area2D) -> void:
	
	if(area.is_in_group("enemy")):
		queue_free()
		


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
