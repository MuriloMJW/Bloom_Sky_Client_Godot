extends Area2D

signal move_pressed(x, y)
signal shoot_pressed(id)
signal damage_report(damaged_id, damager_id, damage_value)
signal respawn_pressed(id)
signal change_team_pressed()

var bullet_scene = load("res://scenes/bullet.tscn")

var id
var start_x
var start_y

var is_my_player = false
var team = ""
var team_id = -1
var is_team_up = false

var is_alive = false
var hp = -1

var can_move = true

var shoot_damage = 20

func setup(player_data):
	self.id = player_data.id
	self.position.x = player_data.x
	self.position.y = player_data.y
	self.team_id = player_data.team_id
	self.team = player_data.team
	self.is_alive = player_data.is_alive
	self.hp = player_data.hp
	

# Fazer uns getters e setter, por ex, set_is_alive,
# se falso, can_move = false, etc

func _ready():
	#is_alive = true
	$CollisionShape2D.disabled = false
	$ColorRect.show()
	$username.show()
	$username.text = str(id)
	$ProgressBar.show()
	$ProgressBar.value = self.hp

	if(team == "SKY"):
		#$username.add_theme_color_override("font_color", Color.AQUA)
		$ColorRect.color = Color.from_rgba8(99, 255, 255, 255)
		is_team_up = true
	else: # BLOOM
		#$username.add_theme_color_override("font_color", Color.DEEP_PINK)
		$ColorRect.color = Color.from_rgba8(255, 102, 250, 255)
		is_team_up = false
		
	if(is_alive == false):
		kill()

func _process(delta):
	#var player_position = Vector2(get_global_mouse_position().x,  start_y)
	#position = player_position
	#print(player_position)
	
	if(is_my_player and is_alive):
		if(Input.is_action_just_pressed("shoot")):
			
			var mouse_position = get_global_mouse_position()
			var x = mouse_position.x
			var y = mouse_position.y
			#position = mouse_position
			
			emit_signal("move_pressed", x, y)
			emit_signal("shoot_pressed", id)
	
		if(Input.is_action_just_pressed("die_input")):
			emit_signal("damage_report", id, 123, 100)
		
		if(Input.is_action_just_pressed("change_team_input")):
			emit_signal("change_team_pressed")
						
	if(is_my_player and !is_alive and Input.is_action_just_pressed("respawn_input")):
		#respawn(position.x, position.y)
		emit_signal("respawn_pressed", id)
	
	
func show_info():
	print("=== PLAYER INFO ===")
	# Informações básicas de identidade e posição
	print("ID: ", self.id, " | Posição: (", self.position.x, ", ", self.position.y, ")")
	# Informações de Time
	print("ID do Time: ", self.team_id, "| Time: ", self.team, " | É do time de cima? ", self.is_team_up)
	# Status de Combate
	print("HP: ", self.hp, " | Está Vivo? ", self.is_alive)	
	# Status Gerais do Jogador
	print("É o meu jogador local? ", self.is_my_player, " | Pode se mover? ", self.can_move)
	print("===================")


func shoot():
	if(is_alive):
		var bullet = bullet_scene.instantiate()
		bullet.position = position
		bullet.is_moving_up = is_team_up
		bullet.shooter_id = id
		get_parent().add_child(bullet)
		
	
func _on_area_entered(area: Area2D) -> void:
	
	if(is_my_player and area.is_in_group("bullet") and area.shooter_id != id):
		print("====GOT HIT====")
		print(hp)
		emit_signal("damage_report", id, area.shooter_id, shoot_damage)
		
func take_damage(damager_id, damage, player_hp):
	self.hp = player_hp
	$ProgressBar.value = self.hp

func kill():
	#set_process(false)
	self.hp = 0 # Não pode
	is_alive = false # Não pode
	$CollisionShape2D.disabled = true
	$ColorRect.hide()
	$username.hide()
	$ProgressBar.value = self.hp
	$ProgressBar.hide()
	
	
func respawn(x, y):
	#set_process(true)
	self.hp = 100 # Não pode
	is_alive = true # Não pode
	$CollisionShape2D.disabled = false
	$ColorRect.show()
	$username.show()
	position.x = x
	position.y = y
	$ProgressBar.value = self.hp
	$ProgressBar.show()
	
func change_team():	
	team_id = 1 if team_id == 0 else 0 # Não pode
	
	team = "SKY" if team_id == 0 else "BLOOM" # Não pode

	if(team == "SKY"):
		#$username.add_theme_color_override("font_color", Color.AQUA)
		$ColorRect.color = Color.from_rgba8(99, 255, 255, 255)
		is_team_up = true
	else: # BLOOM
		#$username.add_theme_color_override("font_color", Color.DEEP_PINK)
		$ColorRect.color = Color.from_rgba8(255, 102, 250, 255)
		is_team_up = false
	
