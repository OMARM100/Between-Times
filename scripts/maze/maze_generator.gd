extends Spatial
class_name StaticMaze

# Fixed prototype maze for Godot 3.5.
# The layout does not change between runs.
#
# # = wall
# . = path
# S = start
# E = exit

const CELL_SIZE = 4.0
const WALL_HEIGHT = 3.0

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
        CELL_SIZE * 0.5,
        WALL_HEIGHT * 0.5,
        CELL_SIZE * 0.5
    )
    collision.shape = box_shape

    var mesh = MeshInstance.new()
    mesh.name = "Mesh"
    wall.add_child(mesh)

    var cube = CubeMesh.new()
    cube.size = Vector3(CELL_SIZE, WALL_HEIGHT, CELL_SIZE)
    mesh.mesh = cube

    wall.translation = Vector3(
        x * CELL_SIZE,
        WALL_HEIGHT * 0.5,
        z * CELL_SIZE
    )
