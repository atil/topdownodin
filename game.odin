package main

import "core:fmt"
import "core:math/linalg"

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

    cam_target: Vec2,
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

    if (linalg.vector_length2(move_dir)) > 0.0001 {
        move_dir = linalg.vector_normalize(move_dir);
    }
    game.player.position += move_dir * (game.config.player_speed * dt);
    mouse_screen_pos := game.input.mouse_pos;

    fmt.println(mouse_screen_pos); // start from here: convert this to world pos

    // mouse_world_pos := rl.GetScreenToWorld2D(rl.GetMousePosition(), game.camera);
    // game.camera.target = linalg.mix(mouse_world_pos, game.player.position, 0.8);
    // game.cursor.position = mouse_world_pos;

    game_compute_visibility_shape(game);
}
 
game_deinit :: proc(game: ^Game) {

}
