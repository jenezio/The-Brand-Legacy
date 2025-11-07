extends CharacterBody2D

# Velocidades configuráveis
@export var speed := 250.0
@export var jump_force := -450.0
@export var gravity := 900.0

func _physics_process(delta):
	# FÍSICA 
	if not is_on_floor():
		velocity.y += gravity * delta
		
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_force
		# print("Pulo iniciado") # Opcional

	# MOVIMENTO 
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * speed
		$AnimatedSprite2D.scale.x = direction
		# ISSO GERAVA CONFLITO: $AnimatedSprite2D.play("run")
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		# ISSO GERAVA CONFLITO: $AnimatedSprite2D.play("idle")
	
	# ANIMAÇÃO
	if not is_on_floor():
		# Prioridade máxima: se está no ar, é jump.
		if $AnimatedSprite2D.animation != "jump":
			$AnimatedSprite2D.play("jump")
	else:
		# Se está no chão, decide entre correr ou ficar parado.
		if direction:
			if $AnimatedSprite2D.animation != "run":
				$AnimatedSprite2D.play("run")
		else:
			if $AnimatedSprite2D.animation != "idle":
				$AnimatedSprite2D.play("idle")
		
	# APLICA MOVIMENTO
	move_and_slide()
