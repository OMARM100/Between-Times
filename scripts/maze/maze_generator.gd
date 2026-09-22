extends Spatial

# Outer-region maze prototype.
# One large irregular maze with mixed corridors, halls and rooms.
# Geometry is optimized by merging contiguous wall cells into long wall segments.

export(float) var cell_size = 3.5
export(float) var wall_height = 4.6
export(float) var ceiling_height = 5.2

export(Color) var wall_color = Color(0.55, 0.58, 0.62)
export(Color) var floor_color = Color(0.16, 0.18, 0.20)
export(Color) var ceiling_color = Color(0.08, 0.09, 0.11)
export(Color) var light_color = Color(1.0, 0.92, 0.72)

export(int) var maze_width = 41
export(int) var maze_depth = 41
export(int) var room_light_count = 3

# Maze generation can stay deterministic for testing or use a random seed.
export(bool) var randomize_maze = false
export(int) var maze_seed = 20260922

# Player spawn room: medium-sized room with exactly one exit into the maze.
export(Vector2) var spawn_room_size = Vector2(9, 7)
export(Vector2) var spawn_room_origin = Vector2(16, 15)

# 0 = wall, 1 = corridor.
var layout = []

func _ready():
    build_maze()
    setup_player_spawn()

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

    # Main routes are narrower now so the player cannot read the whole layout at once.
    carve_rect(2, 3, maze_width - 8, 3)
    carve_rect(5, maze_depth - 6, maze_width - 10, 3)
    carve_rect(3, 4, 3, maze_depth - 10)
    carve_rect(maze_width - 7, 6, 3, maze_depth - 12)

    # Larger spaces exist, but they are separated by turns and narrow connectors.
    carve_rect(15, 5, 9, 6)
    carve_rect(10, 15, 7, 9)
    carve_rect(24, 15, 8, 10)
    carve_rect(16, 29, 9, 6)

    # Corridors with different widths and deliberate turns.
    carve_rect(5, 10, 10, 2)
    carve_rect(14, 10, 2, 8)
    carve_rect(20, 9, 2, 11)
    carve_rect(12, 25, 2, 10)
    carve_rect(27, 25, 2, 10)
    carve_rect(16, 23, 12, 2)

    # Branches and side paths create dead ends and blind corners.
    carve_rect(8, 6, 2, 7)
    carve_rect(31, 7, 2, 8)
    carve_rect(5, 31, 8, 2)
    carve_rect(29, 32, 7, 2)
    carve_rect(6, 13, 2, 5)
    carve_rect(34, 15, 2, 7)

    # Irregular room shapes made from overlapping spaces.
    carve_rect(7, 17, 7, 7)
    carve_rect(5, 19, 11, 3)
    carve_rect(10, 15, 3, 11)

    carve_rect(27, 18, 8, 7)
    carve_rect(25, 20, 12, 3)
    carve_rect(29, 16, 3, 11)

    # Small pockets and offset connectors break the obvious grid pattern.
    carve_rect(3, 14, 4, 2)
    carve_rect(34, 11, 3, 2)
    carve_rect(18, 3, 3, 2)
    carve_rect(20, 35, 3, 2)
    carve_rect(8, 27, 5, 2)
    carve_rect(32, 27, 4, 2)

    configure_spawn_room()

    # Optional seeded variation keeps the main blockout recognizable while
    # adding different side pockets when randomize_maze is enabled.
    if randomize_maze:
        add_seeded_variation()

    # Keep the outside boundary closed.
    for x in range(maze_width):
        layout[0][x] = 0
        layout[maze_depth - 1][x] = 0

    for z in range(maze_depth):
        layout[z][0] = 0
        layout[z][maze_width - 1] = 0

func configure_spawn_room():
    var room_x = int(spawn_room_origin.x)
    var room_z = int(spawn_room_origin.y)
    var room_width = int(spawn_room_size.x)
    var room_depth = int(spawn_room_size.y)

    # Clear the complete room first.
    for z in range(room_z, min(room_z + room_depth, maze_depth - 1)):
        for x in range(room_x, min(room_x + room_width, maze_width - 1)):
            layout[z][x] = 1

    # Close the room perimeter.
    for x in range(room_x - 1, room_x + room_width + 1):
        if x > 0 and x < maze_width - 1:
            layout[room_z - 1][x] = 0
            layout[room_z + room_depth][x] = 0

    for z in range(room_z - 1, room_z + room_depth + 1):
        if z > 0 and z < maze_depth - 1:
            layout[z][room_x - 1] = 0
            layout[z][room_x + room_width] = 0

    # One clearly readable exit on the south side.
    # The opening is wide enough to feel intentional, but it is still one exit.
    var exit_x = room_x + int(room_width * 0.5)
    for x in range(exit_x - 1, exit_x + 2):
        layout[room_z + room_depth][x] = 1

    # Build a short 3-cell-wide approach corridor before opening into the maze.
    for z in range(room_z + room_depth + 1, min(room_z + room_depth + 6, maze_depth - 1)):
        for x in range(exit_x - 1, exit_x + 2):
            layout[z][x] = 1

    # Open the end of the approach into a small transition hall.
    for z in range(room_z + room_depth + 5, min(room_z + room_depth + 8, maze_depth - 1)):
        for x in range(exit_x - 3, exit_x + 4):
            if x > 0 and x < maze_width - 1:
                layout[z][x] = 1

func add_seeded_variation():
    var rng = RandomNumberGenerator.new()
    rng.seed = maze_seed

    for index in range(6):
        var width = rng.randi_range(3, 6)
        var depth = rng.randi_range(3, 5)
        var start_x = rng.randi_range(3, maze_width - width - 4)
        var start_z = rng.randi_range(3, maze_depth - depth - 4)

        # Keep the spawn-room perimeter untouched.
        if start_x + width >= int(spawn_room_origin.x) - 2 and start_x <= int(spawn_room_origin.x + spawn_room_size.x) + 1:
            if start_z + depth >= int(spawn_room_origin.y) - 2 and start_z <= int(spawn_room_origin.y + spawn_room_size.y) + 1:
                continue

        carve_rect(start_x, start_z, width, depth)

func setup_player_spawn():
    var spawn_position = Vector3(
        (spawn_room_origin.x + spawn_room_size.x * 0.5) * cell_size,
        1.0,
        (spawn_room_origin.y + spawn_room_size.y * 0.5) * cell_size
    )

    var player = find_player()

    if player == null:
        var player_scene_path = "res://scenes/Player.tscn"
        if ResourceLoader.exists(player_scene_path):
            var player_scene = load(player_scene_path)
            if player_scene != null:
                player = player_scene.instance()
                get_parent().add_child(player)
        else:
            print("Player scene not found at ", player_scene_path)

    if player != null:
        player.global_transform.origin = get_global_transform().xform(spawn_position)
        print("Player spawn set to: ", spawn_position)

func find_player():
    var parent_node = get_parent()
    if parent_node != null:
        var player = parent_node.get_node_or_null("Player")
        if player != null:
            return player

    var direct_player = get_node_or_null("Player")
    if direct_player != null:
        return direct_player

    return null

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
    var processed = {}

    # Merge horizontal wall runs.
    for z in range(maze_depth):
        var x = 0
        while x < maze_width:
            if layout[z][x] == 0:
                var start_x = x
                while x + 1 < maze_width and layout[z][x + 1] == 0:
                    x += 1
                create_wall_segment(start_x, z, x - start_x + 1)
            x += 1

    # Add the missing vertical faces only where a corridor touches a wall.
    # This closes sightlines and makes the maze read as connected walls rather
    # than a set of flat horizontal strips.
    for z in range(1, maze_depth - 1):
        for x in range(1, maze_width - 1):
            if layout[z][x] == 1:
                if layout[z][x - 1] == 0:
                    create_wall_face(Vector3(x * cell_size - cell_size * 0.5, wall_height * 0.5, z * cell_size), true)
                if layout[z][x + 1] == 0:
                    create_wall_face(Vector3(x * cell_size + cell_size * 0.5, wall_height * 0.5, z * cell_size), true)

func create_wall_face(position, vertical):
    var wall = StaticBody.new()
    wall.name = "WallFace_%d_%d" % [int(position.x), int(position.z)]
    add_child(wall)

    var collision = CollisionShape.new()
    collision.name = "CollisionShape"
    wall.add_child(collision)

    var box_shape = BoxShape.new()
    box_shape.extents = Vector3(
        cell_size * 0.5 if vertical else cell_size * 0.5,
        wall_height * 0.5,
        0.12 if vertical else cell_size * 0.5
    )
    collision.shape = box_shape

    var mesh = MeshInstance.new()
    mesh.name = "Mesh"
    wall.add_child(mesh)

    var cube = CubeMesh.new()
    cube.size = Vector3(
        cell_size if vertical else cell_size,
        wall_height,
        0.24 if vertical else cell_size
    )
    mesh.mesh = cube
    mesh.material_override = create_material(wall_color)
    wall.translation = position

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

    # Lightweight spatial shader: subtle world-position variation and edge
    # response for a cleaner prototype look without textures or post-processing.
    var shader = Shader.new()
    shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : hint_color;
uniform float variation_strength = 0.035;
uniform float edge_strength = 0.08;

void fragment() {
    float n = sin(WORLD_MATRIX[3].x * 0.035 + WORLD_MATRIX[3].z * 0.021) * 0.5 + 0.5;
    vec3 varied = base_color.rgb * mix(1.0 - variation_strength, 1.0 + variation_strength, n);
    float edge = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), 3.0);
    ALBEDO = varied + edge * edge_strength;
    ROUGHNESS = 0.85;
}
"""
    var shader_material = ShaderMaterial.new()
    shader_material.shader = shader
    shader_material.set_shader_param("base_color", color)
    material = shader_material
    return material
