extends KinematicBody2D

const SPEED = 70
const GRAVITY = 10

var jump_power = -250
var move_dir = Vector2()
var sprite_dir = "idle"
var player_facing = "right"
const floor_val = Vector2(0, -1)

func _physics_process(delta):
	input_control()
	movement_loop()
	$player_sprite/anim.play("idle")
	sprite_dir_loop()



func input_control():
	var LEFT = Input.is_action_pressed("ui_left")
	var RIGHT = Input.is_action_pressed("ui_right")
	
	if is_on_floor():
		$player_shadow.show()
		if Input.is_action_just_pressed("ui_jump"):
			move_dir.y = jump_power
	else:
		$player_shadow.hide()

	move_dir.y += GRAVITY
	move_dir.x = (-int(LEFT) + int(RIGHT)) * SPEED


func movement_loop():
	move_dir = move_and_slide(move_dir, floor_val)
	

func sprite_dir_loop():
	match move_dir:
		Vector2(-70,0):
			$player_sprite.set_flip_h(true)
		Vector2(70,0):
			$player_sprite.set_flip_h(false)







