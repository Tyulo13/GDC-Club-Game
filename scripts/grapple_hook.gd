extends RigidBody2D
@export var player : CharacterBody2D


func _on_body_entered(body: Node) -> void:
	if is_instance_valid(player):
		print("hit")
		$HookPoint.add_child(player)
		freeze = true
		self.linear_velocity = Vector2.ZERO
		
		
func _physics_process(delta: float) -> void:
	var velocity = self.linear_velocity.normalized()
	self.global_rotation = velocity.angle()
	
	if freeze == false:
		if is_instance_valid(player):
			$HookPoint.global_position = player.global_position
	
	
	



	
	
