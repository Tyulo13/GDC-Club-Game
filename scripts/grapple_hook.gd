extends Node2D
@export var player : CharacterBody2D
@export var grapplehook : RigidBody2D
@export var rope : Line2D



func _on_grapple_hook_body_entered(body: Node) -> void:
	if is_instance_valid(player):
		var playervelocity = player.get_real_velocity()
		$HitPoint.global_position = grapplehook.global_position
		$HookPoint.global_position = player.global_position
		$HookPoint.linear_velocity = playervelocity
		
		
		$HookPoint.gravity_scale = 1

		player.isHooked = true
		
		
		
		player.reparent($HookPoint)
		grapplehook.reparent($HitPoint)
		grapplehook.gravity_scale = 0
		grapplehook.linear_velocity = Vector2.ZERO
		
		$HitPoint.get_node("PinJoint2D").node_b = $HookPoint.get_path()

		
		
func _physics_process(delta: float) -> void:
	if is_instance_valid(grapplehook):
		var velocity = grapplehook.linear_velocity.normalized()
		grapplehook.global_rotation = velocity.angle()
		rope.points[0] = grapplehook.global_position * rope.global_transform
		rope.points[1] = player.global_position * rope.global_transform
	
	if player.isHooked  == true:
		for child in $HookPoint.get_children():
				if "position" in child:
					child.position = Vector2(0,0)
	else:
		$HookPoint.global_position = player.global_position
	
	
	



	
	
