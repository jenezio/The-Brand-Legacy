extends CharacterBody2D

# Velocidades configuráveis
@export var speed := 200.0
@export var jump_force := -450.0
@export var gravity := 900.0

func _physics_process(delta):
	# Aplicar gravidade
	if not is_on_floor():
		velocity.y += gravity * delta

	# Movimentação horizontal
	var input_dir = Input.get_axis("ui_left", "ui_right")
	velocity.x = input_dir * speed

	# Pulo
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_force
		print("Antes do pulo")
		$AnimatedSprite2D.play("jump")
		print("Depois do pulo")
		
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * speed
		$AnimatedSprite2D.scale.x = direction
		$AnimatedSprite2D.play("run")
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		$AnimatedSprite2D.play("idle")
	
	# Aplicar movimento final
	move_and_slide() 
