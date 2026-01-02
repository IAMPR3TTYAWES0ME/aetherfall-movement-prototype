extends CharacterBody3D
@onready var camera_3d: Camera3D = $"Erika Archer/CameraPivot/SpringArm3D/Camera3D"
@onready var camera_pivot: Node3D = $"Erika Archer/CameraPivot"
@onready var spring_arm_3d: SpringArm3D = $"Erika Archer/CameraPivot/SpringArm3D"
@onready var character: Node3D = $"Erika Archer"
@onready var animation_handler: AnimationPlayer = $"Erika Archer/animation_handler"



const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var mouse_sensitivity := 0.003
var pitch := 0.0
var plrRotation := 0.0
var is_walking := false
var is_jumping := false
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_jumping = true
		
	# Handle zoom.
	if Input.is_action_just_pressed("scroll_back"):
		spring_arm_3d.spring_length += 0.1
	if Input.is_action_just_pressed("scroll_forward"):
		spring_arm_3d.spring_length -= 0.1
	var lock = clamp(spring_arm_3d.spring_length, 0.5, 5.0)
	spring_arm_3d.spring_length = lock
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("right", "left", "backward", "forward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		is_walking = true
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		is_walking = false
	
	if not is_on_floor():
		if animation_handler.current_animation != "jump":
			animation_handler.play("jump")
	elif is_walking:
		if animation_handler.current_animation != "walk":
			animation_handler.play("walk")
	else:
		if animation_handler.current_animation != "idle":
			animation_handler.play("idle")
	
	var cam := Input.get_vector("contollerCamera_L", "contollerCamera_R", "contollerCamera_F", "contollerCamera_B")
	if cam.length() > 0.15:
		var controller_sens := 2.5
		camera_pivot.rotation.y -= cam.x * controller_sens * delta
		pitch = clamp(pitch - cam.y * controller_sens * delta, deg_to_rad(-60), deg_to_rad(60))
		spring_arm_3d.rotation.x = pitch

	move_and_slide()
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion && Input.is_action_pressed("Orbit_Unlock"):
		var _mouse_x = event.relative.x
		var _mouse_y = event.relative.y
		camera_pivot.rotation.y -= _mouse_x * mouse_sensitivity
		spring_arm_3d.rotation.x -= _mouse_y * mouse_sensitivity
		pitch -= _mouse_y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(-60), deg_to_rad(60))
		spring_arm_3d.rotation.x = pitch
		
		
