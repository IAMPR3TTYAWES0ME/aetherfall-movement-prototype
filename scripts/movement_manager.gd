extends CharacterBody3D
@onready var camera_3d: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm_3d: SpringArm3D = $CameraPivot/SpringArm3D
@onready var character: Node3D = $"Erika Archer"
@onready var animation_handler: AnimationPlayer = $"Erika Archer/animation_handler"
@onready var anim_tree: AnimationTree = $"Erika Archer/AnimationTree"
@onready var player: CharacterBody3D = $"."


var SPEED = 5.0
const JUMP_VELOCITY = 4.5
var mouse_sensitivity := 0.003
var pitch := 0.0
var plrRotation := 0.0
var playback: AnimationNodeStateMachinePlayback
var turn_speed := 10.0
var running := false
var zoom = 0
var death_height = -10
var con_scroll_enabled := false

func _ready() -> void:
	anim_tree.active = true
	playback = anim_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	if Input.is_action_pressed("sprint"):
		running = true
	elif Input.is_action_just_released("sprint"):
		running = false
	
	if Input.is_action_just_pressed("console_sprint"):
		running = true
	# Handle zoom.
	if Input.is_action_just_pressed("scroll_back"):
		con_scroll_enabled = false
		spring_arm_3d.spring_length += 0.1
	if Input.is_action_just_pressed("scroll_forward"):
		con_scroll_enabled = false
		spring_arm_3d.spring_length -= 0.1
	var lock = clamp(spring_arm_3d.spring_length, 0.5, 5.0)
	spring_arm_3d.spring_length = lock
	
	var input_dir := Input.get_vector("left", "right", "forward", "backward")

		# Camera axes in world space
	var cam_basis := camera_pivot.global_transform.basis
	var cam_right := -cam_basis.x
	var cam_forward := -cam_basis.z

	# Flatten (ignore pitch) BEFORE using them
	cam_right.y = 0
	cam_forward.y = 0
	cam_right = cam_right.normalized()
	cam_forward = cam_forward.normalized()

	# Build camera-relative movement direction (world space)
	var move_dir := cam_right * input_dir.x + cam_forward * input_dir.y

	if move_dir.length() > 0.001:
		move_dir = move_dir.normalized()

		velocity.x = move_dir.x * SPEED
		velocity.z = move_dir.z * SPEED

		# Face the direction you're actually moving
		var target_yaw := atan2(-move_dir.x, -move_dir.z)
		character.rotation.y = lerp_angle(character.rotation.y, target_yaw, turn_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

	# animation handler
	_update_animation(input_dir)

	
	var cam := Input.get_vector("contollerCamera_L", "contollerCamera_R", "contollerCamera_F", "contollerCamera_B")
	if cam.length() > 0.15:
		var controller_sens := 2.5
		camera_pivot.rotation.y -= cam.x * controller_sens * delta
		pitch = clamp(pitch - cam.y * controller_sens * delta, deg_to_rad(-60), deg_to_rad(60))
		spring_arm_3d.rotation.x = pitch
	if Input.is_action_just_pressed("Zoom_for_console"):
		zoom += 1
		con_scroll_enabled = true #Later add a setting in the menu to turn it off
	if zoom == 0  && con_scroll_enabled:
		spring_arm_3d.spring_length = 1.0
	elif zoom == 1  && con_scroll_enabled:
		spring_arm_3d.spring_length = 2.5
	elif zoom == 2  && con_scroll_enabled:
		spring_arm_3d.spring_length = 5.0
	elif zoom > 2  && con_scroll_enabled:
		zoom = 0
		
	_death(death_height)
	move_and_slide()
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion && Input.is_action_pressed("Orbit_Unlock"):
		var _mouse_x = event.relative.x
		var _mouse_y = event.relative.y
		
		#left and right
		camera_pivot.rotation.y -= _mouse_x * mouse_sensitivity
		#up and down
		spring_arm_3d.rotation.x -= _mouse_y * mouse_sensitivity
		
		pitch -= _mouse_y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(-60), deg_to_rad(60))
		spring_arm_3d.rotation.x = pitch
		
var last_target: StringName = &""

func _update_animation(input_dir: Vector2) -> void:
	var target: StringName

	if Input.is_action_just_pressed("Jump"): #not is_on_floor():
		target = &"jump"
	elif input_dir.length() > 0.1 && running == true:
		target = &"run"
		SPEED = 7.5
	elif input_dir.length() > 0.1 && running == false:
		target = &"walk"
		SPEED = 5.0
	else:
		target = &"idle"
	
	if input_dir.length() < 0.1:
		running = false

	# Only send travel if the target changed since last frame
	if target != last_target:
		last_target = target
		playback.travel(target)
		
func _death(death: float):
		if player.position.y <= death:
			get_tree().reload_current_scene()
