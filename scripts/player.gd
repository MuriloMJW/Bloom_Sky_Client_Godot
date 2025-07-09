extends Node2D

signal move_pressed(x, y)
signal shoot_pressed(id)
signal damage_report(damaged_id, damager_id, damage_value)
signal respawn_pressed(id)
signal change_team_pressed()
signal sonic_pressed()

@onready var username_label = $username
@onready var hp_bar = $ProgressBar
@onready var hp_bar_style_box: StyleBoxFlat
@onready var player_body = $PlayerBody
@onready var box = $PlayerBody/ColorRect
@onready var collision_shape = $PlayerBody/CollisionShape2D
@onready var animation = $AnimationPlayer
@onready var shoot_cooldown_timer = $ShootCooldownTimer
@onready var timer = $Timer
@onready var player_sprite = $PlayerBody/Sprite


var ship_sky_frames = load("res://resources/ship_sky_frames.tres")
var ship_bloom_frames = load("res://resources/ship_bloom_frames.tres")
var bullet_scene = load("res://scenes/bullet.tscn")
var authoritative_cube_scene = load("res://scenes/authoritative_cube.tscn")
var authoritative_cube = null

var id: int 
var username: String
var start_x: float
var start_y: float

var is_my_player: bool

var team_id: int: set = set_team_id
var team: String: set = set_team

var is_alive: bool: set = set_is_alive
var hp : int: set = set_hp

var total_kills: int: set = set_total_kills

var speed: float: set = set_speed

var shoot_cooldown: float: set = set_shoot_cooldown
var shoot_damage := 20


# --- Variáveis de Animação
var is_dying: bool = false

var game_focused

var authoritative_position = position

#================= SETTERS =============== #

func set_team_id(value):
	if(self.team_id == value):
		return
	
	team_id = value
	if(is_node_ready()):
		pass
		
func set_team(value):
	if(self.team == value):
		return
	
	team = value
	if(is_node_ready()):
		update_all_visuals()

func set_is_alive(value):
	if(self.is_alive == value):
		return
	
	is_alive = value
	if(is_node_ready()):
		if(!is_alive):
			self.kill()
		else:
			self.respawn()
		update_all_visuals()
		

func set_hp(value):
	hp = value
	# Se a barra de HP já está instanciada
	if(is_node_ready()):
		update_hp_visual()

func set_total_kills(value):
	total_kills = value
	#increase_size()
	
func set_speed(value):
	speed = value

func set_shoot_cooldown(value):
	shoot_cooldown = value
	if(is_node_ready()):
		shoot_cooldown_timer.wait_time = value

# ================== INICIO ====================== #

func setup(player_data):
	if player_data.id != null:
		self.id = player_data.id

	if player_data.x != null:
		self.authoritative_position.x = player_data.x
	if player_data.y != null:
		self.authoritative_position.y = player_data.y
	if player_data.team_id != null:
		self.team_id = player_data.team_id
	if player_data.team != null:
		self.team = player_data.team
	if player_data.is_alive != null:
		self.is_alive = player_data.is_alive
	if player_data.hp != null:
		self.hp = player_data.hp
	if player_data.total_kills != null:
		self.total_kills = player_data.total_kills
	if player_data.speed != null:
		self.speed = player_data.speed
	if player_data.shoot_cooldown != null:
		self.shoot_cooldown = player_data.shoot_cooldown
	if player_data.username != null:
		self.username = player_data.username
	
	# self.is_sonicking = false

func _ready():
	collision_shape.disabled = false
	#box.hide()
	player_sprite.hide()
	username_label.show()
	username_label.text = "["+str(id)+"] "+username
	
	# O StyleBox é um resource e resource é compartilhada entre os jogadores.
	# Para evitar que todos usem o mesmo stylebox, e criamos uma cópia única
	# dele apenas para este jogador.
	var shared_style_box = hp_bar.get_theme_stylebox("fill")
	self.hp_bar_style_box = shared_style_box.duplicate()
	hp_bar.add_theme_stylebox_override("fill", self.hp_bar_style_box)
	
	update_all_visuals()
	
	authoritative_cube = authoritative_cube_scene.instantiate()
	get_parent().add_child(authoritative_cube)
	
	game_focused = true
	
	if(is_my_player):
		username_label.add_theme_color_override("font_color", Color.GOLD)


func _physics_process(delta):
	
	
	# Se é meu jogador e se está vivo
	if(is_my_player and is_alive and game_focused):
		# === MOVIMENTO == #
		handle_movement_input(delta)
		#handle_movement_input_game_loop_mode(delta)
	
		# === TIRO === #
		if(Input.is_action_pressed("shoot")):
			handle_shoot_input()
	
		if(Input.is_action_just_pressed("die_input")):
			emit_signal("damage_report", id, id, 10)
		
		if(Input.is_action_just_pressed("change_team_input")):
			emit_signal("change_team_pressed")
			
		if(Input.is_action_just_pressed("sonic_input")):
			emit_signal("sonic_pressed")
	
	if(!is_my_player and is_alive):
		handle_other_player_moved(delta)
			
	# Se é meu jogador e está morto e apertou respawn
	if(is_my_player and !is_alive and Input.is_action_just_pressed("respawn_input") and game_focused):
		#respawn(position.x, position.y)
		emit_signal("respawn_pressed", id)

	
func handle_movement_input(delta):
	var movement = (Input.get_vector("move_left", "move_right", "move_forward", "move_backward"))
	# Se apertar pra esquerda    o movement recebe (-1, 0)
	# Se apertar para cima       o movement recebe (0, -1)
	# Se apertar esquerda e cima o movement recebe (-0.75, -0.75)
	
	authoritative_cube.hide()
	
	var new_animation = "default"

	if movement != Vector2.ZERO:
		
		# --- DIAGONAIS ---
		if movement.x < 0 and movement.y < 0: # Cima-Esquerda
			new_animation = "move_backward_sided"
			player_sprite.flip_h = false if self.team_id == 0 else true
		elif movement.x > 0 and movement.y < 0: # Cima-Direita
			new_animation = "move_backward_sided"
			player_sprite.flip_h = true if self.team_id == 0 else false
		elif movement.x < 0 and movement.y > 0: # Baixo-Esquerda
			new_animation = "move_forward_sided"
			player_sprite.flip_h = false if self.team_id == 0 else true
		elif movement.x > 0 and movement.y > 0: # Baixo-Direita
			new_animation = "move_forward_sided"
			player_sprite.flip_h = true if self.team_id == 0 else false
		elif movement.x < 0:
			new_animation = "move_sideway"
			player_sprite.flip_h = false if self.team_id == 0 else true
		elif movement.x > 0:
			new_animation = "move_sideway"
			player_sprite.flip_h = true if self.team_id == 0 else false
		elif movement.y < 0:
			new_animation = "move_backward"
		elif movement.y > 0:
			new_animation = "move_forward"


	if player_sprite.animation != new_animation :
		player_sprite.play(new_animation)
	
	if movement != Vector2.ZERO:
		emit_signal("move_pressed", movement.x, movement.y)
		#position += movement * (speed-speed) * delta
	authoritative_cube.position.x = authoritative_position.x
	authoritative_cube.position.y = authoritative_position.y
	
	if position.distance_to(authoritative_position) > 1:
		position = position.lerp(authoritative_position, 0.36)

		
var last_authoritative_position = Vector2.ZERO	
var time_since_last_update = 0.0
	
func handle_other_player_moved(delta):
	time_since_last_update+= delta
	
	var movement_vector = authoritative_position - last_authoritative_position

	position = position.lerp(authoritative_position, 0.36)
	
	authoritative_cube.show()
	authoritative_cube.position = position
	
	var new_animation = "default"

	#Se o player se moveu, aplica a lógica de animação
	if movement_vector.length_squared() > 0.0001:
		time_since_last_update = 0.0
		# Normaliza o vetor para obter apenas a direção, como o Input.get_vector() faz
		var direction = movement_vector.normalized()
		

		if direction.x < -0.4 and direction.y < -0.4: # Cima-Esquerda
			new_animation = "move_backward_sided"
			player_sprite.flip_h = false if self.team_id == 0 else true
		elif direction.x > 0.4 and direction.y < -0.4: # Cima-Direita
			new_animation = "move_backward_sided"
			player_sprite.flip_h = true if self.team_id == 0 else false
		elif direction.x < -0.4 and direction.y > 0.4: # Baixo-Esquerda
			new_animation = "move_forward_sided"
			player_sprite.flip_h = false if self.team_id == 0 else true
		elif direction.x > 0.4 and direction.y > 0.4: # Baixo-Direita
			new_animation = "move_forward_sided"
			player_sprite.flip_h = true if self.team_id == 0 else false
		# --- RETAS ---
		elif direction.x < 0:
			new_animation = "move_sideway"
			player_sprite.flip_h = false if self.team_id == 0 else true
		elif direction.x > 0:
			new_animation = "move_sideway"
			player_sprite.flip_h = true if self.team_id == 0 else false
		elif direction.y < 0:
			new_animation = "move_backward"
		elif direction.y > 0:
			new_animation = "move_forward"
	
	
		# Toca a nova animação apenas se ela for diferente da atual
		if player_sprite.animation != new_animation:
			player_sprite.play(new_animation)
		
	elif time_since_last_update > 0.10:
		if player_sprite.animation != "default":
			player_sprite.play("default")

	last_authoritative_position = authoritative_position

func handle_shoot_input():
	
	# Redundancia pra não ficar enviando packet atoa
	if shoot_cooldown_timer.is_stopped():
		emit_signal("shoot_pressed", id)
		shoot_cooldown_timer.start(shoot_cooldown)

func shoot(bullet_speed, bullet_direction):
	
	
	#if shoot_cooldown_timer.is_stopped():
	
	var bullet = bullet_scene.instantiate()
	bullet.position = self.position
	bullet.speed = bullet_speed
	bullet.rotation = deg_to_rad(bullet_direction)
	bullet.shooter_id = id
	get_parent().add_child(bullet)
	shoot_cooldown_timer.start(shoot_cooldown)
	

		
func take_damage():
	pass
	
func respawn():
	# TODO: Fazer isso no código,
	# ao invés de animação de reset
	animation.play("RESET")
	await animation.animation_finished
	update_all_visuals()

func kill():
	is_dying = true
	animation.play("death_anim")
	

func sonic():
	animation.play("sonic")
	
func increase_size():
	scale *= Vector2(1.3, 1.3)

func reset_size():
	scale = Vector2(1, 1)

func update_is_alive_visual():
	if(is_dying):
		await animation.animation_finished
		
	if(self.is_alive):
		reset_size()
		collision_shape.disabled = false
		#box.show()
		player_sprite.show()
		username_label.show()
	else:
		collision_shape.disabled = true
		box.hide()
		player_sprite.hide()
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
		team_id = 0
		print("FUI CHAMADO ROTATION")
		player_body.set_rotation_degrees(180)
		player_sprite.sprite_frames = ship_sky_frames
		player_sprite.flip_v = false
		hp_bar.position.y = -80
		username_label.position.y = -74
		
		
	else: # BLOOM
		#$username.add_theme_color_override("font_color", Color.DEEP_PINK)
		box.color = Color.from_rgba8(255, 102, 250, 255)
		team_id = 1
		player_body.set_rotation_degrees(0)
		player_sprite.sprite_frames = ship_bloom_frames
		player_sprite.flip_v = true
		hp_bar.position.y = 57
		username_label.position.y = 63
func update_all_visuals():
	update_hp_visual()
	update_team_visual()
	update_is_alive_visual()
	
	
	
func show_info():
	print("=== PLAYER INFO ===")
	# Informações básicas de identidade e posição
	print("ID: ", self.id, " | Posição: (", self.position.x, ", ", self.position.y, ")")
	# Informações de Time
	print("ID do Time: ", self.team_id, "| Time: ", self.team)
	# Status de Combate
	print("HP: ", self.hp, " | Está Vivo? ", self.is_alive)	
	# Status Gerais do Jogador
	print("É o meu jogador local? ", self.is_my_player)
	print("===================")


func _on_player_body_area_entered(area: Area2D) -> void:
	if(is_my_player and area.is_in_group("bullet") and area.shooter_id != id and self.hp > 0):
		print("====GOT HIT====")
		#emit_signal("damage_report", id, area.shooter_id, shoot_damage)

func _on_ui_focus_changed(game_focus):
	game_focused = game_focus
	print("FUI CHAMADO ", game_focused)
