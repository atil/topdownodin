package main

import "core:fmt"
import "core:math/linalg"
import "core:testing"
import rl "vendor:raylib"

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
    gos: [dynamic]GameObject,

    world_corners: [4]Vec2,
    obstacles: [dynamic]GameObject,
    obstacle_corners: [dynamic]Vec2,
    obstacle_edges: [dynamic]LineSeg,
    visible_corners: [dynamic]Vec2,

    player: ^GameObject,
    cursor: ^GameObject,
    camera: rl.Camera2D,
}

game_init :: proc(game: ^Game, asset_db: ^AssetDatabase, config: ^GameConfig) {
    game.config = config;
    game.db = asset_db;

    game_add_quad(game, "PadBlue", Vec2 {100, 200}, Vec2 {100, 100});
    append(&game.obstacles, game.gos[len(game.gos) - 1]);

    game_add_quad(game, "PadGreen", Vec2 {-100, -200}, Vec2 {50, 50});
    append(&game.obstacles, game.gos[len(game.gos) - 1]);

    game_add_quad(game, "Ball", Vec2 {0, 0}, Vec2 {10, 10});
    game.cursor = &game.gos[len(game.gos) - 1];

    game_add_quad(game, "Ball", Vec2 {100, 100}, Vec2 {32, 32});
    game.player = &game.gos[len(game.gos) - 1];

    game.camera = rl.Camera2D{};
    game.camera.target = Vec2 {10, 10};
    game.camera.offset = Vec2 {cast(f32)config.screen_width / 2.0, cast(f32)config.screen_height / 2.0};
    game.camera.rotation = 0.0;
    game.camera.zoom = 1.0;

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

    WORLD_SIZE :: 1000.0
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
        Vec2 {-half_size.x, -half_size.y}, // Close the poly
    };

    go.texcoords = {
        Vec2 {0.0, 0.0},
        Vec2 {0.0, 1.0}, 
        Vec2 {1.0, 1.0}, 
        Vec2 {1.0, 0.0},
        Vec2 {0.0, 0.0}, // Close the poly
    };

    append(&game.gos, go);
}

game_update :: proc(game: ^Game, dt: f32) {
    move_dir := Vec2 {0, 0};
    if rl.IsKeyDown(rl.KeyboardKey.W) {
        move_dir += Vec2 {0, -1};
    } else if rl.IsKeyDown(rl.KeyboardKey.S) {
        move_dir += Vec2 {0, 1};
    }
    if rl.IsKeyDown(rl.KeyboardKey.A) {
        move_dir += Vec2 {-1, 0};
    } else if rl.IsKeyDown(rl.KeyboardKey.D) {
        move_dir += Vec2 {1, 0};
    }

    if linalg.vector_length2(move_dir) > 0.0001 {
        move_dir = linalg.vector_normalize(move_dir);
    }
    game.player.position += move_dir * (game.config.player_speed * dt);

    mouse_world_pos := rl.GetScreenToWorld2D(rl.GetMousePosition(), game.camera);

    game.camera.target = linalg.mix(mouse_world_pos, game.player.position, 0.8);
    game.cursor.position = mouse_world_pos;

    game_compute_visibility_shape(game);
}
 
game_draw :: proc(game: ^Game) {
    rl.BeginDrawing();
    rl.ClearBackground(rl.BLACK);

    rl.BeginMode2D(game.camera);

    for i := 0; i < len(game.gos); i += 1 {
        go := game.gos[i];

        tex: ^rl.Texture = &game.db.textures[go.texture_name];
        rl.DrawTexturePoly(tex^, go.position, raw_data(go.points), raw_data(go.texcoords), 
            cast(i32)len(go.points), rl.RAYWHITE);

    }

    for line in game.obstacle_edges {
        debug_draw_line(line.a, line.b, rl.RAYWHITE);
    }

    debug_draw_flush();

    rl.EndMode2D();
    rl.EndDrawing();
}
