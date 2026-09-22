extends KinematicBody
class_name لاعب

# حركة اللاعب — Godot 3.5

export(float) var سرعة_المشي = 5.0
export(float) var سرعة_الجري = 8.0
export(float) var تسارع = 20.0
export(float) var تسارع_في_الهواء = 7.0
export(float) var قوة_القفز = 5.5
export(float) var الجاذبية = 18.0

export(float) var حساسية_الفأرة = 0.0025
export(float) var زاوية_النظر_القصوى = 89.0

onready var الرأس = $الرأس

var السرعة = Vector3()
var زاوية_الرأس = 0.0

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
    if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * حساسية_الفأرة)

        زاوية_الرأس -= event.relative.y * حساسية_الفأرة
        زاوية_الرأس = clamp(
            زاوية_الرأس,
            deg2rad(-زاوية_النظر_القصوى),
            deg2rad(زاوية_النظر_القصوى)
        )
        الرأس.rotation.x = زاوية_الرأس

    if event is InputEventKey and event.pressed and event.scancode == KEY_ESCAPE:
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

    if event is InputEventMouseButton and event.pressed:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
    if not is_on_floor():
        السرعة.y -= الجاذبية * delta
    elif السرعة.y < 0.0:
        السرعة.y = -0.5

    if Input.is_action_just_pressed("jump") and is_on_floor():
        السرعة.y = قوة_القفز

    var الإدخال = Vector2(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
        Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
    )

    var الاتجاه = (transform.basis * Vector3(الإدخال.x, 0, الإدخال.y)).normalized()
    var السرعة_المطلوبة = سرعة_الجري if Input.is_action_pressed("sprint") else سرعة_المشي
    var السرعة_المستهدفة = الاتجاه * السرعة_المطلوبة
    var معدل_التسارع = تسارع if is_on_floor() else تسارع_في_الهواء

    السرعة.x = move_toward(السرعة.x, السرعة_المستهدفة.x, معدل_التسارع * delta)
    السرعة.z = move_toward(السرعة.z, السرعة_المستهدفة.z, معدل_التسارع * delta)

    السرعة = move_and_slide(السرعة, Vector3.UP)
