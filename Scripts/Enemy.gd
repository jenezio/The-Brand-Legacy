extends CharacterBody2D

# -----------------
# EXPORTS
# -----------------
@export var speed := 50.0
@export var gravity := 400.0
@export var patrol_distance := 120.0
@export var max_health := 3

# -----------------
# VARIÁVEIS DE ESTADO
# -----------------
var health := 3
var direction := -1 # -1 (esquerda), 1 (direita)
var start_position: float
var is_attacking := false
var is_hitting := false 
var is_dead := false 
var can_damage_player := true

# -----------------
# @ONREADY
# -----------------
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
# Nome do nó corrigido: Area2D_DanoPlayer
@onready var damage_area: Area2D = $Area2D_DanoPlayer 
@onready var damage_cooldown: Timer = Timer.new()
# Novo: RayCast para detecção de parede
@onready var wall_check: RayCast2D = $WallCheck # Assumindo que você adicionará um RayCast2D chamado WallCheck

# -----------------
# FUNÇÕES NATIVAS
# -----------------
func _ready():
	start_position = position.x
	health = max_health
	
	# Configuração do Timer
	damage_cooldown.wait_time = 0.5
	damage_cooldown.one_shot = true
	damage_cooldown.autostart = false
	damage_cooldown.timeout.connect(_on_damage_cooldown_timeout)
	add_child(damage_cooldown)
	
	# GARANTINDO AS CONEXÕES VIA CÓDIGO
	if not anim.animation_finished.is_connected(_on_animated_sprite_2d_animation_finished):
		anim.animation_finished.connect(_on_animated_sprite_2d_animation_finished)
	
	if not damage_area.body_entered.is_connected(_on_area_2d_body_entered):
		damage_area.body_entered.connect(_on_area_2d_body_entered)


func _physics_process(delta):
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Gravidade
	if not is_on_floor():
		velocity.y += gravity * delta

	# Movimento SÓ se não estiver sendo atingido
	if not is_hitting:
		velocity.x = direction * speed
		
		# Animação de Movimento
		if anim.animation != "Skeleton walk" and anim.animation != "hit":
			anim.play("Skeleton walk")
		
		anim.scale.x = direction
	else:
		velocity.x = 0

	# Lógica de Patrulha
	# 1. Virar ao atingir limite de distância
	if abs(position.x - start_position) >= patrol_distance:
		direction *= -1
		start_position = position.x
		
	# 2. NOVO: Virar ao bater em uma parede (Requer um RayCast2D chamado WallCheck)
	# O RayCast2D deve estar virado para a direção "direction"
	if is_on_floor():
		# Move o RayCast para a direção atual de movimento
		wall_check.target_position.x = direction * 10 
		
		if wall_check.is_colliding():
			direction *= -1

	move_and_slide()

# -----------------
# FUNÇÕES DE ESTADO
# -----------------

func _on_animated_sprite_2d_animation_finished():
	if anim.animation == "Skeleton Hit": 
		is_hitting = false
		if health <= 0:
			# Tenta tocar 'death' se a vida acabou durante o hit
			if anim.sprite_frames.has_animation("Skeleton Dead"): # Verifica a animação no SpriteFrames
				anim.play("Sketelon Dead")
			else:
				queue_free() 

	# MORTE DEFINITIVA: Remove o nó após o fim da animação de morte
	if anim.animation == "Skeleton Dead":
		queue_free()

# Cooldown de dano
func _on_damage_cooldown_timeout():
	can_damage_player = true

# -----------------
# FUNÇÕES DE COLISÃO E DANO
# -----------------

# Dano no jogador (Ataque do Inimigo)
func _on_area_2d_body_entered(body: Node2D):
	# ATAQUE SÓ OCORRE se for o Player e se o cooldown estiver pronto
	if body.is_in_group("Player") and not is_dead and not is_hitting: 
		if can_damage_player:
			# Toca animação de ataque se existir (Ex: anim.play("Skeleton attack"))
			if body.has_method("take_damage"):
				body.take_damage(1)
				can_damage_player = false
				damage_cooldown.start()
				print("Inimigo atacou o Player!")

# Inimigo toma dano (Definitivo)
func take_damage(amount: int):
	if is_dead:
		return
		
	if health > 0 and not is_hitting:
		health -= amount
		
		print("Inimigo recebeu dano. Vida: ", health)

		if health <= 0:
			# MORTE: Para movimento, seta flags e tenta tocar animação
			is_dead = true
			is_hitting = true 
			velocity = Vector2.ZERO
			
			if anim.sprite_frames.has_animation("Skeleton Dead"):
				anim.play("Skeleton Dead")
				
			elif anim.sprite_frames.has_animation("Skeleton Hit"):
				anim.play("Skeleton Hit")
			else:
				queue_free() 

		elif anim.sprite_frames.has_animation("hit"):
			# HIT: Toca animação de hit
			is_hitting = true
			anim.play("hit") 
		else:
			# Se não tem animação de hit, reseta o estado imediatamente para poder levar o próximo dano
			is_hitting = false
