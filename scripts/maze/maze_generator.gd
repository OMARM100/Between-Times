extends Spatial

# Outer-region maze prototype.
# One large irregular maze with mixed corridors, halls and rooms.
# Geometry is optimized by merging contiguous wall cells into long wall segments.

export(float) var cell_size = 4.0
export(float) var wall_height = 4.0
export(float) var ceiling_height = 7.0

export(Color) var wall_color = Color(0.55, 0.58, 0.62)
export(Color) var floor_color = Color(0.16, 0.18, 0.20)
export(Color) var ceiling_color = Color(0.08, 0.09, 0.11)
export(Color) var light_color = Color(1.0, 0.92, 0.72)

export(int) var maze_width = 41
export(int) var maze_depth = 41
export(int) var room_light_count = 3

# 0 = wall, 1 = corridor.
var layout = []

func _ready():
    build_maze()

func build_maze():
    generate_layout()
    create_floor()
    create_ceiling()
    create_merged_walls()
    create_room_lighting()

func generate_layout():
    layout.clear()

    for z in range(maze_depth):
        var row = []
        for x in range(maze_width):
            row.append(0)
        layout.append(row)

    # Broad outer routes.
    carve_rect(2, 2, maze_width - 3, 4)
    carve_rect(2, maze_depth - 6, maze_width - 3, 4)
    carve_rect(2, 2, 4, maze_depth - 3)
    carve_rect(maze_width - 6, 2, 4, maze_depth - 3)

    # Large irregular halls and rooms.
    carve_rect(15, 5, 11, 7)
    carve_rect(9, 15, 8, 13)
    carve_rect(24, 14, 9, 14)
    carve_rect(16, 28, 10, 7)

    # Corridors with different widths.
    carve_rect(5, 10, 16, 3)
    carve_rect(20, 10, 3, 12)
    carve_rect(12, 25, 3, 11)
    carve_rect(27, 25, 3, 11)
    carve_rect(15, 21, 13, 3)

    # Branches and side paths.
    carve_rect(7, 6, 3, 9)
    carve_rect(31, 7, 4, 10)
    carve_rect(5, 30, 10, 3)
    carve_rect(28, 32, 8, 3)

    # Irregular room shapes made from overlapping spaces.
    carve_rect(7, 17, 7, 7)
    carve_rect(5, 19, 11, 3)
    carve_rect(10, 15, 3, 11)

    carve_rect(27, 18, 8, 7)
    carve_rect(25, 20, 12, 3)
    carve_rect(29, 16, 3, 11)

    # Extra pockets to avoid a rigid grid appearance.
    carve_rect(3, 13, 5, 3)
    carve_rect(34, 12, 4, 3)
    carve_rect(17, 3, 4, 3)
    carve_rect(20, 35, 4, 3)

    # Keep the outside boundary closed.
    for x in range(maze_width):
        layout[0][x] = 0
        layout[maze_depth - 1][x] = 0

    for z in range(maze_depth):
        layout[z][0] = 0
        layout[z][maze_width - 1] = 0

func carve_rect(start_x, start_z, width, depth):
    var end_x = min(start_x + width, maze_width - 1)
    var end_z = min(start_z + depth, maze_depth - 1)

    for z in range(start_z, end_z):
        for x in range(start_x, end_x):
            if x > 0 and z > 0 and x < maze_width - 1 and z < maze_depth - 1:
                layout[z][x] = 1

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

    var cube = CubeMesh.new()
    cube.size = Vector3(
        maze_width * cell_size,
        0.1,
        maze_depth * cell_size
    )
    mesh.mesh = cube
    mesh.material_override = create_material(floor_color)

    floor_body.translation = Vector3(
        (maze_width - 1) * cell_size * 0.5,
        -0.05,
        (maze_depth - 1) * cell_size * 0.5
    )

func create_ceiling():
    var ceiling_body = StaticBody.new()
    ceiling_body.name = "Ceiling"
    add_child(ceiling_body)

    var collision = CollisionShape.new()
    collision.name = "CollisionShape"
    ceiling_body.add_child(collision)

    var ceiling_shape = BoxShape.new()
    ceiling_shape.extents = Vector3(
        maze_width * cell_size * 0.5,
        0.05,
        maze_depth * cell_size * 0.5
    )
    collision.shape = ceiling_shape

    var mesh = MeshInstance.new()
    mesh.name = "Mesh"
    ceiling_body.add_child(mesh)

    var cube = CubeMesh.new()
    cube.size = Vector3(
        maze_width * cell_size,
        0.1,
        maze_depth * cell_size
    )
    mesh.mesh = cube
    mesh.material_override = create_material(ceiling_color)

    ceiling_body.translation = Vector3(
        (maze_width - 1) * cell_size * 0.5,
        ceiling_height,
        (maze_depth - 1) * cell_size * 0.5
    )

func create_merged_walls():
    for z in range(maze_depth):
        var x = 0

        while x < maze_width:
            if layout[z][x] == 0:
                var start_x = x

                while x + 1 < maze_width and layout[z][x + 1] == 0:
                    x += 1

                create_wall_segment(start_x, z, x - start_x + 1)

            x += 1

func create_wall_segment(start_x, z, length):
    var wall = StaticBody.new()
    wall.name = "Wall_%d_%d_Length_%d" % [start_x, z, length]
    add_child(wall)

    var collision = CollisionShape.new()
    collision.name = "CollisionShape"
    wall.add_child(collision)

    var box_shape = BoxShape.new()
    box_shape.extents = Vector3(
        length * cell_size * 0.5,
        wall_height * 0.5,
        cell_size * 0.5
    )
    collision.shape = box_shape

    var mesh = MeshInstance.new()
    mesh.name = "Mesh"
    wall.add_child(mesh)

    var cube = CubeMesh.new()
    cube.size = Vector3(
        length * cell_size,
        wall_height,
        cell_size
    )
    mesh.mesh = cube
    mesh.material_override = create_material(wall_color)

    wall.translation = Vector3(
        (start_x + length * 0.5) * cell_size,
        wall_height * 0.5,
        z * cell_size
    )

func create_room_lighting():
    var room_centers = [
        Vector3(11, 5.5, 11),
        Vector3(29, 5.5, 11),
        Vector3(21, 5.5, 21)
    ]

    var count = min(room_light_count, room_centers.size())

    for index in range(count):
        var light = OmniLight.new()
        light.name = "RoomLight_%d" % index
        light.light_color = light_color
        light.light_energy = 1.1
        light.omni_range = 16.0

        # Shadows are intentionally disabled for the prototype.
        # Several shadow-casting omni lights are expensive in Godot 3.5.
        light.shadow_enabled = false

        add_child(light)
        light.translation = room_centers[index]

func create_material(color):
    var material = SpatialMaterial.new()
    material.albedo_color = color
    material.roughness = 0.85
    return material
