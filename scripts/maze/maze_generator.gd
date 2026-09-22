extends Spatial

# First-region prototype: the outer "Wall Maria" area.
# The stage is intentionally irregular rather than circular, square, or rectangular.
# The full stage will eventually contain three large nested regions/walls.
# This script currently builds only the outer region.

export(float) var cell_size = 4.0
export(float) var wall_height = 3.0
export(Color) var wall_color = Color(0.55, 0.58, 0.62)
export(Color) var floor_color = Color(0.18, 0.20, 0.22)

export(int) var maze_width = 31
export(int) var maze_depth = 31

# The outer wall is a deliberately uneven, organic perimeter.
# Each value is a normalized radius multiplier for a side of the shape.
const OUTER_PROFILE = [
    0.88, 0.94, 1.02, 1.10, 1.05, 0.97, 0.92, 0.98,
    1.08, 1.14, 1.07, 0.96, 0.90, 0.95, 1.04, 1.10,
    1.03, 0.94, 0.89, 0.96, 1.06, 1.13, 1.08, 0.98,
    0.91, 0.94, 1.01, 1.09, 1.04, 0.95, 0.89, 0.93
]

func _ready():
    build_maze()

func build_maze():
    create_floor()

    var center = Vector2(
        (maze_width - 1) * 0.5,
        (maze_depth - 1) * 0.5
    )

    var outer_radius = min(maze_width, maze_depth) * 0.47

    for z in range(maze_depth):
        for x in range(maze_width):
            if is_outer_wall_cell(x, z, center, outer_radius):
                create_wall(x, z)

func is_outer_wall_cell(x, z, center, outer_radius):
    var point = Vector2(x, z)
    var offset = point - center
    var distance = offset.length()

    if distance < outer_radius * 0.82 or distance > outer_radius * 1.18:
        return false

    if distance <= 0.01:
        return false

    var angle = atan2(offset.y, offset.x)
    var normalized_angle = fposmod(angle + PI * 2.0, PI * 2.0)
    var sector = int(normalized_angle / (PI * 2.0) * OUTER_PROFILE.size())
    sector = clamp(sector, 0, OUTER_PROFILE.size() - 1)

    var local_radius = outer_radius * OUTER_PROFILE[sector]

    # A thick wall band follows the irregular perimeter.
    return abs(distance - local_radius) <= 0.95

func create_floor():
    var floor_body = StaticBody.new()
    floor_body.name = "Floor"
    add_child(floor_body)

    var collision = CollisionShape.new()
    collision.name = "CollisionShape"
    floor_body.add_child(collision)

    var floor_shape = BoxShape.new()
    floor_shape.extents = Vector3(
        maze_width * cell_size * 0.5,
        0.05,
        maze_depth * cell_size * 0.5
    )
    collision.shape = floor_shape

    var mesh = MeshInstance.new()
    mesh.name = "Mesh"
    floor_body.add_child(mesh)

    var plane = CubeMesh.new()
    plane.size = Vector3(
        maze_width * cell_size,
        0.1,
        maze_depth * cell_size
    )
    mesh.mesh = plane
    mesh.material_override = create_material(floor_color)

    floor_body.translation = Vector3(
        (maze_width - 1) * cell_size * 0.5,
        -0.05,
        (maze_depth - 1) * cell_size * 0.5
    )

func create_wall(x, z):
    var wall = StaticBody.new()
    wall.name = "Wall_%d_%d" % [x, z]
    add_child(wall)

    var collision = CollisionShape.new()
    collision.name = "CollisionShape"
    wall.add_child(collision)

    var box_shape = BoxShape.new()
    box_shape.extents = Vector3(
        cell_size * 0.5,
        wall_height * 0.5,
        cell_size * 0.5
    )
    collision.shape = box_shape

    var mesh = MeshInstance.new()
    mesh.name = "Mesh"
    wall.add_child(mesh)

    var cube = CubeMesh.new()
    cube.size = Vector3(cell_size, wall_height, cell_size)
    mesh.mesh = cube
    mesh.material_override = create_material(wall_color)

    wall.translation = Vector3(
        x * cell_size,
        wall_height * 0.5,
        z * cell_size
    )

func create_material(color):
    var material = SpatialMaterial.new()
    material.albedo_color = color
    material.roughness = 0.85
    return material
