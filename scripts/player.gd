extends Area2D

signal move_pressed(x, y)
signal shoot_pressed(id)
signal damage_report(damaged_id, damager_id, damage_value)
signal respawn_pressed(id)
signal change_team_pressed()
signal sonic_pressed()

@onready var username_label = $username
@onready var hp_bar = $ProgressBar
@onready var hp_bar_style_box: StyleBoxFlat
@onready var box = $ColorRect
@onready var collision_shape = $CollisionShape2D
@onready var animation = $AnimationPlayer

var bullet_scene = load("res://scenes/bullet.tscn")

var id: int
var start_x: int
var start_y: int

var is_my_player: bool
var team: String
var team_id: int
var is_team_up: bool

var is_alive : bool: set = set_is_alive
var hp : int: set = set_hp



var shoot_damage := 20

# --- Variáveis de Animação
var is_dying: bool = false


func set_is_alive(value):
	if(self.is_alive == value):
		return
	
	is_alive = value
	if(is_node_ready()):
		if(!is_alive):
			self.kill()
		update_all_visuals()
		

func set_hp(value):
	hp = value
	
	# Se a barra de HP já está instanciada
	if(is_node_ready()):
		update_hp_visual()


func setup(player_data):
	self.id = player_data.id
	self.position.x = player_data.x
	self.position.y = player_data.y
	self.team_id = player_data.team_id
	self.team = player_data.team
	self.is_alive = player_data.is_alive
	self.hp = player_data.hp
	# self.is_sonicking = false

# Fazer uns getters e setter, por ex, set_is_alive,
# se falso, can_move = false, etc

func _ready():
	collision_shape.disabled = false
	box.show()
	username_label.show()
	username_label.text = str(id)
	
	# O StyleBox é um resource e resource é compartilhada entre os jogadores.
	# Para evitar que todos usem o mesmo stylebox, e criamos uma cópia única
	# dele apenas para este jogador.
	var shared_style_box = hp_bar.get_theme_stylebox("fill")
	self.hp_bar_style_box = shared_style_box.duplicate()
	hp_bar.add_theme_stylebox_override("fill", self.hp_bar_style_box)
	
	update_all_visuals()

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
			
		if(Input.is_action_just_pressed("sonic_input")):
			emit_signal("sonic_pressed")
						
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
	print("É o meu jogador local? ", self.is_my_player)
	print("===================")


func shoot():
	if(is_alive):
		var bullet = bullet_scene.instantiate()
		bullet.position = position
		bullet.is_moving_up = is_team_up
		bullet.shooter_id = id
		if(animation.current_animation == "sonic"):
			bullet.rotation = self.rotation
			#bullet.direction = Vector2.UP.rotated(global_rotation)
		get_parent().add_child(bullet)
		
	
func _on_area_entered(area: Area2D) -> void:
	
	if(is_my_player and area.is_in_group("bullet") and area.shooter_id != id and self.hp > 0):
		print("====GOT HIT====")
		print(hp)
		emit_signal("damage_report", id, area.shooter_id, shoot_damage)

		
func take_damage():
	pass
	
func respawn(x, y):
	#set_process(true)
	self.hp = 100 # Não pode
	is_alive = true # Não pode
	
	animation.play("RESET")
	collision_shape.disabled = false
	box.show()
	username_label.show()
	username_label.text = str(id)
	position.x = x
	position.y = y
	update_hp_visual()
	
func change_team():	
	team_id = 1 if team_id == 0 else 0 # Não pode
	team = "SKY" if team_id == 0 else "BLOOM" # Não pode
	update_team_visual()
	
func sonic():
	animation.play("sonic")
	
func kill():

	is_dying = true
	animation.play("death_anim")
	

func update_is_alive_visual():
	if(is_dying):
		await animation.animation_finished
		
	if(self.is_alive):
		collision_shape.disabled = false
		box.show()
		username_label.show()
	else:
		collision_shape.disabled = true
		box.hide()
		username_label.hide()

func update_hp_visual():
	hp_bar.value = self.hp
	
	if(self.is_alive):
		hp_bar.show()
	else:
		hp_bar.hide()
	
	if(self.hp > 50):
		hp_bar_style_box.bg_color = Color.GREEN
	elif(self.hp > 20):
		hp_bar_style_box.bg_color = Color.YELLOW
	else:
		hp_bar_style_box.bg_color = Color.RED
		
func update_team_visual():
	if(team == "SKY"):
		#$username.add_theme_color_override("font_color", Color.AQUA)
		box.color = Color.from_rgba8(99, 255, 255, 255)
		is_team_up = true
	else: # BLOOM
		#$username.add_theme_color_override("font_color", Color.DEEP_PINK)
		box.color = Color.from_rgba8(255, 102, 250, 255)
		is_team_up = false

func update_all_visuals():
	update_hp_visual()
	update_team_visual()
	update_is_alive_visual()
	
	
