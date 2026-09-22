extends KinematicBody
class_name Player

# Player movement and camera look — Godot 3.5

export(float) var walk_speed = 5.0
export(float) var sprint_speed = 8.0
export(float) var acceleration = 20.0
export(float) var air_acceleration = 7.0
export(float) var jump_force = 5.5
export(float) var gravity = 18.0

export(float) var mouse_sensitivity = 0.0025
export(float) var look_up_limit = 75.0
export(float) var look_down_limit = 60.0

var velocity = Vector3()
var look_angle = 0.0
var head = null

func _ready():
    head = get_node_or_null("Head")

    if head != null:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
    if head == null:
        return

    if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * mouse_sensitivity)

        look_angle += event.relative.y * mouse_sensitivity
        look_angle = clamp(
            look_angle,
            deg2rad(-look_up_limit),
            deg2rad(look_down_limit)
        )

        head.rotation.x = look_angle

    if event is InputEventKey and event.pressed and event.scancode == KEY_ESCAPE:
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

    if event is InputEventMouseButton and event.pressed:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
    if not is_on_floor():
        velocity.y -= gravity * delta
    elif velocity.y < 0.0:
        velocity.y = -0.5

    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_force

    var input_vector = Vector2(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
        Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
    )

    var direction = (transform.basis * Vector3(input_vector.x, 0, input_vector.y)).normalized()
    var target_speed = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
    var target_velocity = direction * target_speed
    var acceleration_rate = acceleration if is_on_floor() else air_acceleration

    velocity.x = move_toward(velocity.x, target_velocity.x, acceleration_rate * delta)
    velocity.z = move_toward(velocity.z, target_velocity.z, acceleration_rate * delta)

    velocity = move_and_slide(velocity, Vector3.UP)
