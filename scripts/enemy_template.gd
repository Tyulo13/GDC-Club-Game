extends CharacterBody2D
@export var player: CharacterBody2D
var SPEED: float = 50.0
var GRAVITY: float = 500.0
var JUMP_STRENGTH: float = -200.0
var SIGHT_RANGE : float = 200.0
var KNOCKBACK : float = 300.0

func _process(delta: float) -> void:
	var distance = (global_position - player.global_position).length() # Gets the distance between enemy and player
	
	if distance < SIGHT_RANGE:
		if distance > 250.0:
			$AnimatedSprite2D.play("alert")
		
		var direction = (global_position - player.global_position).normalized() # Gets the direction from the enemy to the player
		velocity.x = -direction.x * SPEED  #moves enemy toward the player, only worries about the x-axis (so the enemy doesn't fly)
		
		
		$AnimatedSprite2D.flip_h = global_position.x < player.global_position.x #flips the enemy to face the player. If the enemy's x position is greater than the player's, then the enemy is to the right of the player
		
		
		if is_on_floor():
			if direction.y > 0:
				velocity.y = JUMP_STRENGTH # if the player is on the floor AND at least 5 pixels above the enemy, enemy will jump
	else:
		velocity.x = 0 # if the player is out of sight, stop moving
	
	if velocity.x == 0 and velocity.y == 0: #animation handling
		$AnimatedSprite2D.play("idle")
	elif velocity.y == 0:
		$AnimatedSprite2D.play("walk")
	else:
		$AnimatedSprite2D.play("jump")
	
	if !is_on_floor():
		velocity.y += GRAVITY * delta  #  apply gravity
			
	move_and_slide()
	
	var overlapping = $Area2D.get_overlapping_bodies()
	for body in overlapping:
		if body == player:
			if player.IFRAMES == 0: # if the player hasn't been hit recently (invincibility frames)
				player.velocity += -(global_position - player.global_position).normalized() *  KNOCKBACK 
				player.HEALTH -= 1
				player.IFRAMES = 0.2
