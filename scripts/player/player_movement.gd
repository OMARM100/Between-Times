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

# Lightweight first-person camera movement.
export(float) var camera_bob_amount = 0.035
export(float) var camera_bob_speed = 9.0
export(float) var camera_sway_amount = 0.012
export(float) var camera_sway_speed = 6.0
export(float) var camera_shake_amount = 0.015
export(float) var camera_lean_angle = 8.0
export(float) var camera_lean_speed = 10.0

var velocity = Vector3()
var look_angle = 0.0
var head = null
var camera = null
var head_base_position = Vector3()
var camera_bob_time = 0.0
var camera_shake_time = 0.0

func _ready():
    head = get_node_or_null("Head")
    if head != null:
        head_base_position = head.translation
        camera = head.get_node_or_null("Camera")

    if head != null:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
    if head == null:
        return

    if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * mouse_sensitivity)

        # Vertical mouse look: moving the mouse down looks down.
        look_angle -= event.relative.y * mouse_sensitivity
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
    update_camera_motion(delta, input_vector)

func update_camera_motion(delta, input_vector):
    if head == null:
        return

    var horizontal_speed = Vector2(velocity.x, velocity.z).length()
    var moving = is_on_floor() and horizontal_speed > 0.15

    if moving:
        var sprinting = Input.is_action_pressed("sprint")
        var speed_scale = 1.35 if sprinting else 1.0
        camera_bob_time += delta * camera_bob_speed * speed_scale

        var bob_x = cos(camera_bob_time * 0.5) * camera_sway_amount
        var bob_y = abs(sin(camera_bob_time)) * camera_bob_amount
        head.translation = head_base_position + Vector3(bob_x, bob_y, 0.0)
    else:
        camera_bob_time = lerp(camera_bob_time, 0.0, min(delta * 7.0, 1.0))
        head.translation = head.translation.linear_interpolate(
            head_base_position,
            min(delta * 8.0, 1.0)
        )

    # Very subtle rotational camera shake while moving.
    # This is intentionally small so the player does not lose visual control.
    var shake = camera_shake_amount if moving else 0.0
    var sway = sin(camera_bob_time * camera_sway_speed) * shake

    # PUBG-style neck lean: Q leans left, E leans right.
    var lean_direction = 0.0
    if Input.is_key_pressed(KEY_Q):
        lean_direction -= 1.0
    if Input.is_key_pressed(KEY_E):
        lean_direction += 1.0

    var target_lean = deg2rad(camera_lean_angle) * lean_direction
    var target_rotation = target_lean + sway

    if camera != null:
        camera.rotation.z = lerp(
            camera.rotation.z,
            target_rotation,
            min(delta * camera_lean_speed, 1.0)
        )
