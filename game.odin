package main

import "core:fmt"
import "core:math/linalg"
import glm "core:math/linalg/glsl"
import SDL "vendor:sdl2"
import gl "vendor:OpenGL"

GameObject :: struct {
    position: Vec2,
    size: Vec2,
    texture_name: string,
    points: [dynamic]Vec2,
    texcoords: [dynamic]Vec2,
}

Game :: struct {
    config: ^GameConfig,
    db: ^AssetDatabase,
    input: ^Input,

    time_since_start: f32,
    gos: [dynamic]GameObject,

    world_corners: [4]Vec2,
    obstacles: [dynamic]GameObject,
    obstacle_corners: [dynamic]Vec2,
    obstacle_edges: [dynamic]LineSeg,
    visible_corners: [dynamic]Vec2,

    player: ^GameObject,
    cursor: ^GameObject,

    // TODO @TEMP
    vao, vbo: u32, // TODO @CLEANUP: Handle aliases for these u32's
    debug_shader: u32,
    debug_shader_uniforms: gl.Uniforms,
}

game_init :: proc(game: ^Game, asset_db: ^AssetDatabase, config: ^GameConfig, input: ^Input) {
    game.config = config;
    game.db = asset_db;
    game.input = input;

    game_add_quad(game, "PadBlue", Vec2 {100, 200}, Vec2 {100, 100});
    append(&game.obstacles, game.gos[len(game.gos) - 1]);

    // game_add_quad(game, "PadGreen", Vec2 {-100, -200}, Vec2 {50, 50});
    // append(&game.obstacles, game.gos[len(game.gos) - 1]);

    game_add_quad(game, "Ball", Vec2 {0, 0}, Vec2 {10, 10});
    game.cursor = &game.gos[len(game.gos) - 1];

    game_add_quad(game, "Ball", Vec2 {100, 100}, Vec2 {32, 32});
    game.player = &game.gos[len(game.gos) - 1];

    for obs in game.obstacles {
        corner_count := len(obs.points) - 1; // Last one is used to close the polygon
        obs_corners := make([]Vec2, corner_count);
        defer delete(obs_corners);

        for i in 0..<corner_count {
            corner := obs.points[i] + obs.position;
            append(&game.obstacle_corners, corner);

            line_seg := LineSeg { obs.position + obs.points[i], obs.position + obs.points[(i + 1) % corner_count] };
            append(&game.obstacle_edges, line_seg);
        }
    }

    WORLD_SIZE :: 1000.0 // TODO @CLEANUP: Move to config
    game.world_corners = {
        Vec2 {-WORLD_SIZE, -WORLD_SIZE},
        Vec2 {WORLD_SIZE, -WORLD_SIZE},
        Vec2 {WORLD_SIZE, WORLD_SIZE},
        Vec2 {-WORLD_SIZE, WORLD_SIZE},
    };

    debug_shader, debug_shader_ok := gl.load_shaders_file("assets/shaders/debug.vert", "assets/shaders/debug.frag");
    if (!debug_shader_ok) {
        fmt.eprintln("Shader error"); // TODO @INCOMPLETE: Handle fatal errors by crashing the thing
    }
    game.debug_shader = debug_shader;

    DebugVertex :: struct {
        pos: Vec2,
    }

    v1 : DebugVertex = DebugVertex {Vec2 { 0, 0 }};
    v2 : DebugVertex = DebugVertex {Vec2 { 1, 1 }};
    vertices := []DebugVertex {v1, v2};

    gl.GenVertexArrays(1, &game.vao);
    gl.BindVertexArray(game.vao);
    gl.GenBuffers(1, &game.vbo);

    gl.BindBuffer(gl.ARRAY_BUFFER, game.vbo);
    gl.EnableVertexAttribArray(0);
    gl.VertexAttribPointer(0, 2, gl.FLOAT, false, size_of(DebugVertex), offset_of(DebugVertex, pos));
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(DebugVertex), raw_data(vertices), gl.STATIC_DRAW);

    game.debug_shader_uniforms = gl.get_uniforms_from_program(game.debug_shader);

    model := glm.mat4{
          1, 0, 0, 0.1,
          0, 1, 0, 0,
          0, 0, 1, 0,
          0, 0, 0, 1,
    };

    aspect := cast(f32)(game.config.screen_width / game.config.screen_height);
    cam_size :: 1; // TODO @CLEANUP: Figure out what sort of metric is this, and move it to config

    cam_focus := glm.vec3 {0, 0, 0};
    view := glm.mat4LookAt(cam_focus, cam_focus + glm.vec3 {0, 0, -1}, glm.vec3 {0, 1, 0});
    fmt.println(view);
    proj := glm.mat4Ortho3d(-aspect * cam_size, aspect * cam_size, -cam_size, cam_size, -1, 1);

    u_transform := proj * view * model;
    gl.UseProgram(game.debug_shader);
    gl.UniformMatrix4fv(game.debug_shader_uniforms["u_transform"].location, 1, false, &u_transform[0, 0]);

    test_color := ColorBlue;
    gl.Uniform4fv(game.debug_shader_uniforms["u_color"].location, 1, &test_color.r);
}

game_add_quad :: proc(game: ^Game, tex_name: string, position: Vec2, size: Vec2) {
    go: GameObject;
    go.texture_name = tex_name;
    go.position = position;
    go.size = size;

    half_size := size / 2.0;
    go.points = { // Right handed, starting from top-left
        Vec2 {-half_size.x, -half_size.y},
        Vec2 {-half_size.x,  half_size.y},
        Vec2 { half_size.x,  half_size.y},
        Vec2 { half_size.x, -half_size.y},
    };

    go.texcoords = {
        Vec2 {0.0, 0.0},
        Vec2 {0.0, 1.0}, 
        Vec2 {1.0, 1.0}, 
        Vec2 {1.0, 0.0},
    };

    append(&game.gos, go);
}

game_update :: proc(game: ^Game, dt: f32) {

    move_dir := Vec2 {0, 0};
    if (input_is_key_down(game.input, KeyCode.W)) {
        move_dir += Vec2 {0, -1};
    } else if (input_is_key_down(game.input, KeyCode.S)) {
        move_dir += Vec2 {0, 1};
    }
    if (input_is_key_down(game.input, KeyCode.A)) {
        move_dir += Vec2 {-1, 0};
    } else if (input_is_key_down(game.input, KeyCode.D)) {
        move_dir += Vec2 {1, 0};
    }

    if linalg.vector_length2(move_dir) > 0.0001 {
        move_dir = linalg.vector_normalize(move_dir);
    }
    game.player.position += move_dir * (game.config.player_speed * dt);
    mouse_screen_pos := game.input.mouse_pos;

    // mouse_world_pos := rl.GetScreenToWorld2D(rl.GetMousePosition(), game.camera);
    // game.camera.target = linalg.mix(mouse_world_pos, game.player.position, 0.8);
    // game.cursor.position = mouse_world_pos;

    game_compute_visibility_shape(game);
}
 
game_draw :: proc(game: ^Game) {
    gl.Viewport(0, 0, cast(i32)game.config.screen_width, cast(i32)game.config.screen_height);
    gl.ClearColor(0.5, 0.7, 1.0, 1.0);
    gl.Clear(gl.COLOR_BUFFER_BIT);

    gl.BindVertexArray(game.vao);

    gl.DrawArrays(gl.LINES, 0, 2);
}

game_deinit :: proc(game: ^Game) {
    gl.DeleteProgram(game.debug_shader);
    gl.DeleteVertexArrays(1, &game.vao);
    gl.DeleteBuffers(1, &game.vbo);
    delete(game.debug_shader_uniforms);
}
