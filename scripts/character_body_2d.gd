extends CharacterBody2D
@export var HEALTH : float = 10.0
@export var IFRAMES : float = 0.0

const SPEED = 120.0
const JUMP_VELOCITY = -200.0
const DASH_VELOCITY = 500

var isHITSTOP := false
var coyote_time_activated := false

var GRAVITY := 0

var DIRECTION := 1
var InputDIRECTION := 1

var canDOUBLEJUMP := true

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
	
	if !is_on_wall_only():
		if velocity.y < 0:
			GRAVITY = 600 # rise gravity
		elif velocity.y < 100:
			GRAVITY = 500 # apex gravity
		else:
			GRAVITY = 1000 # fall gravity
	elif !direction:
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
	if Input.is_action_just_pressed("dash") and canDASH and !is_on_wall_only():
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
	
	# all animations
	if isDASHING:
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
