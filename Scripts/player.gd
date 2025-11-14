extends CharacterBody2D

# -----------------
# @ONREADY E EXPORTS
# -----------------
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $Area2D_Ataque

@export var speed := 120.0
@export var jump_force := -300.0
@export var gravity := 900.0
@export var max_vidas := 3

# -----------------
# VARIÁVEIS DE ESTADO
# -----------------
var is_attacking := false
var has_damaged := false
var vidas := 3
var is_dead := false 

# -----------------
# FUNÇÕES NATIVAS
# -----------------
func _ready():
	vidas = max_vidas
	attack_area.monitoring = false
	
	# Garante a conexão da animação via código
	if not anim.animation_finished.is_connected(_on_animated_sprite_2d_animation_finished):
		anim.animation_finished.connect(_on_animated_sprite_2d_animation_finished)

func _physics_process(delta):
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return 
	
	# === A LÓGICA DE SEGURANÇA FOI MOVIDA PARA CÁ (Linhas 40-43 anteriores) ===
	# --- Lógica de Segurança (Resetar ataque se a animação falhar) ---
	if is_attacking and anim.animation != "attack_model1":
		is_attacking = false
		attack_area.monitoring = false
		has_damaged = false
		
	# --- ATAQUE ---
	if Input.is_action_just_pressed("ataque") and is_on_floor() and not is_attacking:
		is_attacking = true
		has_damaged = false
		velocity.x = 0
		attack_area.monitoring = true
		anim.play("attack_model1")

	# --- MOVIMENTO (desativado durante ataque) ---
	if not is_attacking:
		# Pulo
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = jump_force

		# Andar
		var direction := Input.get_axis("ui_left", "ui_right")

		if direction:
			velocity.x = direction * speed
			anim.scale.x = direction
		else:
			velocity.x = move_toward(velocity.x, 0, speed)

		# ANIMAÇÕES
		if not is_on_floor():
			if anim.animation != "jump":
				anim.play("jump")
		else:
			if direction:
				if anim.animation != "walk":
					anim.play("walk")
			else:
				if anim.animation != "idle":
					anim.play("idle")

	# Gravidade
	if not is_on_floor():
		velocity.y += gravity * delta
		
	move_and_slide()

# -----------------
# FUNÇÕES DE ESTADO
# -----------------
# Reseta o estado de ataque
func _on_animated_sprite_2d_animation_finished():
	if anim.animation == "attack_model1":
		is_attacking = false
		attack_area.monitoring = false
		has_damaged = false
	
	# Morte do Player
	if anim.animation == "death":
		queue_free()

# Jogador toma dano
func take_damage(amount: int):
	if is_dead:
		return

	vidas -= amount
	print("Vidas restantes (Player): ", vidas)
	
	if vidas <= 0:
		is_dead = true
		velocity = Vector2.ZERO
		
		print("Player morreu")
		
		if anim.has_animation("death"):
			anim.play("death")
		else:
			queue_free()

# -----------------
# FUNÇÕES DE COLISÃO
# -----------------
# Dano no Inimigo (Conectado ao sinal 'body_entered' do Area2D_Ataque)
func _on_area_2d_ataque_body_entered(body: Node2D): 
	if is_attacking and not has_damaged:
		if body.is_in_group("Enemy"):
			var enemy = body as CharacterBody2D 
			if enemy != null and enemy.has_method("take_damage"):
				
				if !enemy.is_hitting and !enemy.is_dead: 
					enemy.take_damage(1)
					has_damaged = true
