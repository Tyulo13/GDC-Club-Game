extends Node2D
@export var player : CharacterBody2D
@export var grapplehook : RigidBody2D




func _on_grapple_hook_body_entered(body: Node) -> void:
	if is_instance_valid(player):
		
		$HitPoint.global_position = grapplehook.global_position
		$PinJoint2D.global_position = $HitPoint.global_position
		$HookPoint.global_position = player.global_position
		$HookPoint.gravity_scale = 1
		
		
		
		#player.reparent($HookPoint)
		grapplehook.reparent($HitPoint)
		grapplehook.gravity_scale = 0
		grapplehook.linear_velocity = Vector2.ZERO

		
		
func _physics_process(delta: float) -> void:
	var velocity = grapplehook.linear_velocity.normalized()
	grapplehook.global_rotation = velocity.angle()
	

	
	
	



	
	
