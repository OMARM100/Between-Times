extends KinematicBody
class_name Player

# Basic player movement — Godot 3.5

export(float) var walk_speed = 5.0
export(float) var sprint_speed = 8.0
export(float) var acceleration = 20.0
export(float) var air_acceleration = 7.0
export(float) var jump_force = 5.5
export(float) var gravity = 18.0

var velocity = Vector3()

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

    var direction = Vector3(input_vector.x, 0, input_vector.y).normalized()
    var target_speed = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
    var target_velocity = direction * target_speed
    var acceleration_rate = acceleration if is_on_floor() else air_acceleration

    velocity.x = move_toward(velocity.x, target_velocity.x, acceleration_rate * delta)
    velocity.z = move_toward(velocity.z, target_velocity.z, acceleration_rate * delta)

    velocity = move_and_slide(velocity, Vector3.UP)
