extends CharacterBody3D

const mmoProto = preload("res://proto/serverRequest.gd")
var SocketIntegration = preload("res://mmo/socket_integration.gd").new()

@onready var camera_mount = $camera_mount
@onready var animation_player = $visuals/mixamo_base/AnimationPlayer
@onready var visuals = $visuals
const SPEED = 3.0

var seq_id: int = 0

const JUMP_VELOCITY = 4.5

@export var sens_horizontal = 0.5
@export var sens_vertical = 0.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	SocketIntegration.socket_connect()
	
func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * sens_horizontal))
		visuals.rotate_y(deg_to_rad(event.relative.x * sens_horizontal))
		camera_mount.rotate_x(deg_to_rad(-event.relative.y * sens_vertical))

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		if animation_player.current_animation != "walking":
			animation_player.play("walking")
			
		visuals.look_at(position + -direction)
		
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		if animation_player.current_animation != "idle":
			animation_player.play("idle")
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	var request := mmoProto.ServerRequest.new()
	request.set_type(mmoProto.ServerRequestTypeE.CHARACTER_UPDATE)
	request.set_seq_id(seq_id)
	SocketIntegration.send(request)
	seq_id += 1