extends KinematicBody2D
class_name Player

enum {
	MOVE,
	CLIMB,
}

export(Resource) var move_data = preload("res://DefaultPlayerMovementData.tres") as PlayerMovementData

var velocity = Vector2.ZERO
var state = MOVE
var double_jump = move_data.DOUBLE_JUMP_COUNT
var buffered_jump = false
var coyote_jump = false
onready var animated_sprite = $AnimatedSprite
onready var ladder_check = $LadderCheck
onready var jump_buffer = $JumpBuffer
onready var coyote_jump_timer = $CoyoteJumpTimer

func _physics_process(delta):
	var input = Vector2.ZERO
	input.x = Input.get_axis("ui_left", "ui_right")
	input.y = Input.get_axis("ui_up", "ui_down")


	match state:
		MOVE: move_state(input)
		CLIMB: climb_state(input)

func move_state(input):
	if is_on_ladder() and Input.is_action_pressed("ui_up"):
		state = CLIMB
	apply_gravity()
	
	if not has_horizontal_input(input):
		apply_friction()
	else:
		apply_acceleration(input.x)

	if is_on_floor():
		reset_double_jump()
	else:
		animated_sprite.animation = "Jump"

	if can_jump():
		standard_jump()
	else:
		jump_release()
		double_jump()
		buffered_jump()
		fall_faster()
	
	var was_in_air = not is_on_floor()
	var was_on_floor = is_on_floor()

	velocity = move_and_slide(velocity, Vector2.UP)
	
	fix_landing_animation(was_in_air)
	coyote_jump_check(was_on_floor)
	
	

func coyote_jump_check(was_on_floor):
	var just_left_ground = not is_on_floor() and was_on_floor
	if just_left_ground and velocity.y >= 0:
		coyote_jump = true
		coyote_jump_timer.start()

func fix_landing_animation(was_in_air):
	if is_on_floor() and was_in_air: # we landed
		animated_sprite.animation = "Run"
		animated_sprite.frame = 1

func buffered_jump():
	if Input.is_action_just_pressed("ui_up"):
		buffered_jump = true
		jump_buffer.start()

func fall_faster():
	if velocity.y > 0:
		velocity.y += move_data.ADDITIONAL_FALL_GRAVITY # fall faster after a jump

func double_jump():
	if Input.is_action_just_pressed("ui_up") and double_jump > 0:
		velocity.y = move_data.JUMP_HEIGHT
		double_jump -= 1

func jump_release():
	if Input.is_action_just_released("ui_up") and velocity.y < move_data.JUMP_RELEASE_FORCE:
		velocity.y = move_data.JUMP_RELEASE_FORCE

func has_horizontal_input(input):
	return input.x != 0

func can_jump():
	return is_on_floor() or coyote_jump

func reset_double_jump():
	double_jump = move_data.DOUBLE_JUMP_COUNT

func standard_jump():
	if Input.is_action_just_pressed("ui_up") or buffered_jump:
		velocity.y = move_data.JUMP_HEIGHT
		buffered_jump = false

func climb_state(input):
	if not is_on_ladder():
		state = MOVE
	if input.length() != 0:
		animated_sprite.animation = "Run"
	else:
		animated_sprite.animation = "Idle"
	velocity = input * move_data.CLIMB_SPEED
	velocity = move_and_slide(velocity, Vector2.UP)

func is_on_ladder():
	if not ladder_check.is_colliding():
		return false
	var collider = ladder_check.get_collider()
	if not collider is Ladder: 
		return false
	return true	
	
func apply_gravity():
	velocity.y = min(velocity.y + move_data.GRAVITY, move_data.MAX_GRAVITY)
		
func apply_friction():
	velocity.x = move_toward(velocity.x, 0, move_data.FRICTION)
	animated_sprite.animation = "Idle"

func apply_acceleration(amount):
	velocity.x = move_toward(velocity.x, move_data.MAX_SPEED*amount, move_data.ACCELERATION)
	animated_sprite.animation = "Run"
	animated_sprite.flip_h = amount > 0

func _on_JumpBuffer_timeout():
	buffered_jump = false

func _on_CoyoteJumpTimer_timeout():
	coyote_jump = false
