extends Node2D

signal move_pressed(x, y)
signal shoot_pressed(id)
signal damage_report(damaged_id, damager_id, damage_value)
signal respawn_pressed(id)
signal change_team_pressed()
signal sonic_pressed()
signal enter_pressed()

@onready var username_label = $username
@onready var hp_bar = $ProgressBar
@onready var hp_bar_style_box: StyleBoxFlat
@onready var player_body = $PlayerBody
@onready var box = $PlayerBody/ColorRect
@onready var collision_shape = $PlayerBody/CollisionShape2D
@onready var animation = $AnimationPlayer
@onready var shoot_cooldown_timer = $ShootCooldownTimer
@onready var timer = $Timer
var tick_count = 0

var bullet_scene = load("res://scenes/bullet.tscn")
var authoritative_cube_scene = load("res://scenes/authoritative_cube.tscn")
var authoritative_cube = null

var id: int
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


# --- Variáveis de Animação --- $
var is_dying: bool = false

# --- Variaveis de predição de movimento --- #
var authoritative_position = position
var last_sent_movement = Vector2.ZERO

var correction_speed := 500
var tolerance := 1.0
var snapshot_buffer := []
var max_buffer_time := 1.0


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
	increase_size()
	
func set_speed(value):
	speed = value

func set_shoot_cooldown(value):
	shoot_cooldown = value

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
	
	# self.is_sonicking = false

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
	
	authoritative_cube = authoritative_cube_scene.instantiate()
	get_parent().add_child(authoritative_cube)
	
	if(self.team_id == 0):
		position.x = 100
		position.y = 100
	else:
		position.x = 100
		position.y = 500


func _physics_process(delta):
	
	var now = Time.get_ticks_msec() / 1000.0
	snapshot_buffer.append({"time": now, "pos": authoritative_position})
	
	while snapshot_buffer.size() > 0 and now - snapshot_buffer[0].time > max_buffer_time:
		snapshot_buffer.pop_front()
		
	var ping = 0.150
	var render_time = now - ping*0.5
	position = interpolate_snapshot(render_time)
	
	tick_count += 1
	# Se é meu jogador e se está vivo
	if(is_my_player and is_alive):
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
	if(is_my_player and !is_alive and Input.is_action_just_pressed("respawn_input")):
		#respawn(position.x, position.y)
		emit_signal("respawn_pressed", id)


var idle_time := 0.0
var lerp_delay := 0.170

var rtt := 150
var buffer_delay := (rtt / 1000.0)

func interpolate_snapshot(target_time: float) -> Vector2:
	if snapshot_buffer.size() < 2:
		return authoritative_position
	# encontra o intervalo no buffer
	for i in range(snapshot_buffer.size() - 1):
		var a = snapshot_buffer[i]
		var b = snapshot_buffer[i + 1]
		if a.time <= target_time and target_time <= b.time:
			var t = (target_time - a.time) / (b.time - a.time)
			return a.pos.lerp(b.pos, t)
	return snapshot_buffer.back().pos

func handle_movement_input(delta):
	var movement = (Input.get_vector("move_left", "move_right", "move_forward", "move_backward"))
	
	#authoritative_cube.position.x = authoritative_position.x
	#authoritative_cube.position.y = authoritative_position.y
	
	#print(idle_time)
	
	if movement != Vector2.ZERO:
		idle_time = 0
		position += movement * speed * delta
		emit_signal("move_pressed", movement.x, movement.y)
	
	var dist = position.distance_to(authoritative_position)
	if dist > tolerance:
		var ping = 0.150
		var strength = clamp(delta / max(ping, 0.01), 0.0, 1.0)
		position = position.move_toward(authoritative_position, correction_speed * delta)
	
	
	
		#if position.distance_to(authoritative_position) > 0.1:
		#	position = position.lerp(authoritative_position, 0.1)
	
func handle_movement_input_game_loop_mode(delta):
	var movement = (Input.get_vector("move_left", "move_right", "move_forward", "move_backward"))
	# Se apertar pra esquerda    o movement recebe (-1, 0)
	# Se apertar para cima       o movement recebe (0, -1)
	# Se apertar esquerda e cima o movement recebe (-0.75, -0.75)
	
	#print("AUTH POS: ", authoritative_position)
	#print("MY POS: ", position)
	#authoritative_cube.hide()
	#position += movement * speed * delta
	if(last_sent_movement != movement):
	
		#position += movement * speed * 1.0/30.0
		emit_signal("move_pressed", movement.x, movement.y)
		last_sent_movement = movement
	#print(speed)
	#position.x = authoritative_position.x
	#position.y = authoritative_position.y
	#if(movement != Vector2.ZERO):
	position += movement * speed * delta
	authoritative_cube.position.x = authoritative_position.x
	authoritative_cube.position.y = authoritative_position.y
	#print("XX Player: x: ", position.x, "y: ", position.y)
	if position.distance_to(authoritative_position) > 0.01:
		position = position.lerp(authoritative_position, 1)
		#pass
			
func handle_other_player_moved(delta):
	position = authoritative_position


func handle_shoot_input():
	
	#fire_cooldown_timer.start(fire_cooldown)
	#and fire_cooldown_timer.is_stopped()
	'''
	var bullet = bullet_scene.instantiate()
	bullet.position = self.position
	bullet.rotation = player_body.rotation
	bullet.is_moving_up = self.team_id == 0
	bullet.shooter_id = id
	get_parent().add_child(bullet)
	'''
	emit_signal("shoot_pressed", id)
	
	'''
	if(is_alive):
		var bullet = bullet_scene.instantiate()
		bullet.position = position
		bullet.is_moving_up = is_team_up
		bullet.shooter_id = id
		if(animation.current_animation == "sonic"):
			bullet.rotation = self.rotation
			#bullet.direction = Vector2.UP.rotated(global_rotation)
		get_parent().add_child(bullet)
	'''

func shoot():
	
	
	#if shoot_cooldown_timer.is_stopped():
		
	var bullet = bullet_scene.instantiate()
	bullet.position = self.position
	bullet.rotation = player_body.rotation
	bullet.is_moving_up = self.team_id == 0
	bullet.shooter_id = id
	get_parent().add_child(bullet)
	get_parent().add_child(authoritative_cube)
	shoot_cooldown_timer.start(shoot_cooldown)
	

		
func take_damage():
	pass
	
func respawn():
	animation.play("RESET")

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
		team_id = 0
		player_body.set_rotation_degrees(180)
	else: # BLOOM
		#$username.add_theme_color_override("font_color", Color.DEEP_PINK)
		box.color = Color.from_rgba8(255, 102, 250, 255)
		team_id = 1
		player_body.set_rotation_degrees(0)

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
		print(hp)
		emit_signal("damage_report", id, area.shooter_id, shoot_damage)


func _on_timer_timeout() -> void:
	pass # Replace with function body.
	#print("------ GODOT UPDATES POR SEGUNDO: ", tick_count)
	tick_count = 0
