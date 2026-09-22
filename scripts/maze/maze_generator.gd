extends Spatial

# Fixed prototype maze for Godot 3.5.
# The layout is predefined and does not change between runs.

export(float) var cell_size = 4.0
export(float) var wall_height = 3.0
export(Color) var wall_color = Color(0.55, 0.58, 0.62)
export(Color) var floor_color = Color(0.18, 0.20, 0.22)

const MAZE = [
    "###############",
    "#S............#",
    "#############.#",
    "#.............#",
    "#.#############",
    "#.............#",
    "#############.#",
    "#.............#",
    "#.#############",
    "#............E#",
    "###############"
]

func _ready():
    build_maze()

func build_maze():
    create_floor()

    for z in range(MAZE.size()):
        var row = MAZE[z]

        for x in range(row.length()):
            if row[x] == "#":
                create_wall(x, z)

func create_floor():
    var floor_body = StaticBody.new()
    floor_body.name = "Floor"
    add_child(floor_body)

    var collision = CollisionShape.new()
    collision.name = "CollisionShape"
    floor_body.add_child(collision)

    var floor_shape = BoxShape.new()
    floor_shape.extents = Vector3(
        MAZE[0].length() * cell_size * 0.5,
        0.05,
        MAZE.size() * cell_size * 0.5
    )
    collision.shape = floor_shape

    var mesh = MeshInstance.new()
    mesh.name = "Mesh"
    floor_body.add_child(mesh)

    var plane = CubeMesh.new()
    plane.size = Vector3(
        MAZE[0].length() * cell_size,
        0.1,
        MAZE.size() * cell_size
    )
    mesh.mesh = plane
    mesh.material_override = create_material(floor_color)

    floor_body.translation = Vector3(
        (MAZE[0].length() - 1) * cell_size * 0.5,
        -0.05,
        (MAZE.size() - 1) * cell_size * 0.5
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
