extends KinematicBody2D

var direction = Vector2.RIGHT
var velocity = Vector2.ZERO

func should_reverse():
	if is_on_wall() or (not $LedgeCheckRight.is_colliding() or not $LedgeCheckLeft.is_colliding()):
		return true
	return false

func _physics_process(delta):
	if should_reverse():
		direction *= -1
		$AnimatedSprite.flip_h = direction.x > 0
	velocity = direction * 25
	move_and_slide(velocity, Vector2.UP)
