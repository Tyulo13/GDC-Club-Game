extends CharacterBody2D
@export var HEALTH : float = 10.0
@export var IFRAMES : float = 0.0
@export var grapplehook : PackedScene
@export var level : Node2D

const SPEED = 120.0
const JUMP_VELOCITY = -200.0
const DASH_VELOCITY = 500
const GRAPPLE_VELOCITY = 300
const HOOK_LENGTH = 150

var isHITSTOP := false
var coyote_time_activated := false

var GRAVITY := 0

var DIRECTION := 1
var InputDIRECTION := 1

var canDOUBLEJUMP := true
var canATTACK : bool = true
var attacking : bool = false

var canHook : bool = true	
var hookclone = null

var isDASHING := false
var canDASH := true
var canRegainDASH := true

var isWALLRUN := false

var isDIVING := false

func hitstop(timeScale, duration):
	Engine.time_scale = timeScale
	isHITSTOP = true
	await(get_tree().create_timer(duration, true, false, true).timeout)
	Engine.time_scale = 1
	isHITSTOP = false

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	
	if IFRAMES > 0:
		$AnimatedSprite2D.modulate = Color(1, 0, 0)
		IFRAMES -= delta
	else:
		$AnimatedSprite2D.modulate = Color(1, 1,1)
		IFRAMES = 0
	
	if !is_on_wall_only() or !direction:
		if velocity.y < 0:
			GRAVITY = 600 # rise gravity
		elif velocity.y < 100:
			GRAVITY = 500 # apex gravity
		else:
			GRAVITY = 1000 # fall gravity
	
	# adding gravity
	if !is_on_floor():
		velocity.y += GRAVITY * delta
	# jump buffer
	if Input.is_action_just_pressed("jump"):
		$JumpBuffer.start()
	
	# coyote time
	if is_on_floor():
		canDOUBLEJUMP = true
		if canRegainDASH:
			canDASH = true
		if coyote_time_activated:
			coyote_time_activated = false
			$CoyoteTime.stop()
	else:
		if !coyote_time_activated:
			$CoyoteTime.start()
			coyote_time_activated = true
	
	# jumping
	if !$JumpBuffer.is_stopped() and (is_on_floor() or !$CoyoteTime.is_stopped() or canDOUBLEJUMP) and !Input.is_action_pressed("move_down"):
		$JumpBuffer.stop()
		coyote_time_activated = true
		if !is_on_floor() and $CoyoteTime.is_stopped() and canDOUBLEJUMP:
			canDOUBLEJUMP = false
		$CoyoteTime.stop()
		velocity.y = JUMP_VELOCITY
	# releasing jump
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y = JUMP_VELOCITY / 3
	
	if Input.is_action_just_pressed("move_left"):
		InputDIRECTION = -1
	if Input.is_action_just_pressed("move_right"):
		InputDIRECTION = 1
	
	
	# dive kick
	if Input.is_action_just_pressed("jump") and Input.is_action_pressed("move_down") and !is_on_floor():
		isDIVING = true
		if direction:
			velocity.x = 170 * direction
		else:
			velocity.x = 0
		velocity.y = -100
		await(get_tree().create_timer(0.1, true, false, true).timeout)
		velocity.y = 900
	else:
		isDIVING = false
		
	if Input.is_action_just_pressed("attack") and canATTACK == true and is_on_floor() and isDASHING == false:
		canATTACK = false
		attacking = true
		$SliceAnim.play("default")
		await(get_tree().create_timer(0.15, true, false, true).timeout)
		attacking = false
		await(get_tree().create_timer(0.1, true, false, true).timeout)
		canATTACK = true
	
	# moves the player left and right
	if direction and !isWALLRUN:
		if abs(velocity.x) > 250:
			velocity.x = move_toward(velocity.x, direction * SPEED, 20)
			# if high velocity, slowly decelerates the player to walking speed
		else:
			velocity.x = move_toward(velocity.x, direction * SPEED, 40)
			# if low velocity, quickly deccelerates the player to walking speed
	else:
		if abs(velocity.x) > 250:
			velocity.x = move_toward(velocity.x, 0, 20)
			# if high velocity, slowly decelerates the player to stop
		else:
			velocity.x = move_toward(velocity.x, 0, 40)
			# if low velocity, quickly deccelerates the player to stop
	
	# dash input
	if Input.is_action_just_pressed("dash") and canDASH and !is_on_wall_only() and velocity.x != 0:
		isDASHING = true
		velocity.y = velocity.y - velocity.y
		velocity.x = velocity.x / 100
		await(get_tree().create_timer(0.083, true, false, true).timeout)
		velocity.y = velocity.y - velocity.y - 50
		velocity.x = InputDIRECTION * (abs(velocity.x) + 550) # 550 = dash strength
		canDASH = false
		canRegainDASH = false
		
		velocity.y = 0
		
		await(get_tree().create_timer(0.247, true, false, true).timeout)
		canRegainDASH = true
		isDASHING = false
		
		if is_on_floor() or !is_on_floor():
			canDASH = true
	
	
	# wall slide
	if is_on_wall_only() and direction:
		if velocity.y > 0 and !isWALLRUN:
			velocity.y = 20
		if Input.is_action_pressed("dash") and !isWALLRUN:
			isWALLRUN = true
			velocity.y = -300
			await(get_tree().create_timer(0.2, true, false, true).timeout)
			if is_on_wall_only():
				hitstop(0.01, 0.02)
				await(get_tree().create_timer(0.02, true, false, true).timeout)
				canDOUBLEJUMP = true
				isWALLRUN = false
				velocity.y = -200
				velocity.x = 300 * -direction
	
	if (!is_on_wall_only() or Input.is_action_just_released("dash")) and isWALLRUN:
		hitstop(0.01, 0.05)
		await(get_tree().create_timer(0.05, true, false, true).timeout)
		canDOUBLEJUMP = true
		isWALLRUN = false
		velocity.y = -200
		
	if Input.is_action_just_pressed("grappling_hook"):
		var direction_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if canHook:
			canHook = false
			
			hookclone = grapplehook.instantiate()
			
			hookclone.global_position = self.global_position
			hookclone.global_rotation = direction_vector.angle()
			level.add_child(hookclone)
			print(hookclone.name)
			hookclone.player = self
			hookclone.get_node("GrappleHook").apply_central_impulse((direction_vector * GRAPPLE_VELOCITY) + self.get_real_velocity())
			
	if Input.is_action_just_released("grappling_hook"):
		self.reparent(level)
		if is_instance_valid(hookclone):
			var hookdecal = hookclone.grapplehook
			hookdecal.freeze = true
			while is_instance_valid(hookclone) and (hookdecal.global_position - self.global_position).length() > 20: # keeps drawing the hookclone closer as long as the distance between player and hook is larger than 20
				if is_instance_valid(hookclone):	
					var gdirection = (hookdecal.global_position - self.global_position).normalized()
					hookdecal.global_position -= gdirection * 10
					await(get_tree().process_frame)
			canHook = true
			if is_instance_valid(hookclone):	
				hookclone.queue_free()
			
			
	
	# flips the players direction
	if direction > 0:
		$AnimatedSprite2D.flip_h = false
		if is_on_wall_only():
			$AnimatedSprite2D.flip_h = true
		DIRECTION = 1
	elif direction < 0:
		$AnimatedSprite2D.flip_h = true
		if is_on_wall_only():
			$AnimatedSprite2D.flip_h = false
		DIRECTION = -1
	$SliceAnim.flip_h = $AnimatedSprite2D.flip_h
	
	# all animations
	if attacking:
		$AnimatedSprite2D.animation = "attack"
	elif isDASHING:
		$AnimatedSprite2D.animation = "dash"
	elif is_on_floor():
		if direction:
			$AnimatedSprite2D.animation = "run"
		else:
			$AnimatedSprite2D.animation = "idle"
	elif is_on_wall_only():
		if isWALLRUN:
			$AnimatedSprite2D.animation = "wallrun"
		else: 
			$AnimatedSprite2D.animation = "slide"
	else:
		if velocity.y < 0:
			$AnimatedSprite2D.animation = "rising"
		else:
			$AnimatedSprite2D.animation = "falling"

	
	
	$AnimatedSprite2D.play()

	move_and_slide()
