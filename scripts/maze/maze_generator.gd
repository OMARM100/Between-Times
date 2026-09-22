extends Spatial

# Fixed prototype maze for Godot 3.5.
# The layout is predefined and does not change between runs.

export(float) var cell_size = 4.0
export(float) var wall_height = 3.0

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
    for z in range(MAZE.size()):
        var row = MAZE[z]

        for x in range(row.length()):
            if row[x] == "#":
                create_wall(x, z)

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

    wall.translation = Vector3(
        x * cell_size,
        wall_height * 0.5,
        z * cell_size
    )
