extends Area2D

@export
var enemy_speed = 100

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	enemy_speed = randi_range(100,200)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.y += enemy_speed * delta


func _on_area_entered(area: Area2D) -> void:
	
	if(area.is_in_group("bullet")):
		queue_free()
		


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
