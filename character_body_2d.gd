extends CharacterBody2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

# Velocidades configuráveis
@export var speed := 120.0
@export var jump_force := -300.0
@export var gravity := 900.0
var is_attacking := false

func _physics_process(delta):
	# FÍSICA 
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if Input.is_action_just_pressed("ataque") and is_on_floor() and not is_attacking:
		is_attacking = true
		velocity.x = 0
		anim.play("attack_model1") 
	
	# MOVIMENTO 

	if not is_attacking:
		# PULO
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = jump_force
			# print("Pulo iniciado") # Opcional
		var direction := Input.get_axis("ui_left", "ui_right")
		if direction:
			velocity.x = direction * speed
			anim.scale.x = direction
			# ISSO GERAVA CONFLITO: $AnimatedSprite2D.play("run")
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			# ISSO GERAVA CONFLITO: $AnimatedSprite2D.play("idle")
			
		# ANIMAÇÃO
		if not is_on_floor():
			# Prioridade máxima: se está no ar, é jump.
			if anim.animation != "jump":
				anim.play("jump")
		else:
			# Se está no chão, decide entre correr ou ficar parado.
			if direction:
				if anim.animation != "walk":
					anim.play("walk")
			else:
				if anim.animation != "idle":
					anim.play("idle")
		
	# APLICA MOVIMENTO
	move_and_slide()

func _on_animated_sprite_2d_animation_finished():
	if anim.animation == "attack_model1":
		is_attacking = false
		
		
