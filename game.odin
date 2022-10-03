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
    obstacles: [dynamic]GameObject,
    player: ^GameObject,
    camera: rl.Camera2D,
}

game_init :: proc(game: ^Game, asset_db: ^AssetDatabase, config: ^GameConfig) {
    game.config = config;
    game.db = asset_db;

    game_add_quad(game, "PadBlue", Vec2 {100, 200}, Vec2 {100, 100});
    append(&game.obstacles, game.gos[len(game.gos) - 1]);

    game_add_quad(game, "PadGreen", Vec2 {-100, -200}, Vec2 {50, 50});
    append(&game.obstacles, game.gos[len(game.gos) - 1]);

    game_add_quad(game, "Ball", Vec2 {100, 100}, Vec2 {32, 32});

    game.player = &game.gos[len(game.gos) - 1];

    game.camera = rl.Camera2D{};
    game.camera.target = Vec2 {10, 10};
    game.camera.offset = Vec2 {cast(f32)config.screen_width / 2.0, cast(f32)config.screen_height / 2.0};
    game.camera.rotation = 0.0;
    game.camera.zoom = 1.0;
}

game_add_quad :: proc(game: ^Game, tex_name: string, position: Vec2, size: Vec2) {
    go: GameObject;
    go.texture_name = tex_name;
    go.position = position;
    go.size = size;

    half_size := size / 2.0;
    go.points = { // Right handed
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
    fmt.printf("%s %v\n", tex_name, go.points[0]);
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

    mouse_pos := rl.GetMousePosition();

    t: f32 = 0.8;// TODO @CLEANUP: use mix() proc
    look_at_pos := (game.player.position * t) + mouse_pos * (1 - t);

    game.camera.target = look_at_pos;

    game_do_visibility_stuff(game);
}

game_do_visibility_stuff :: proc(game: ^Game) {
    player_pos := game.player.position;

    for obs in game.obstacles {
        obs_corners := make([]Vec2, len(obs.points));

        for i in 0..<len(obs.points) { // TODO @SPEED: We can cache this for fixed obstacles
            obs_corners[i] = obs.points[i] + obs.position;
        }

        for corner in obs_corners {
            // @HERE. this isn't in the BeginMode2D(game.camera) block.
            rl.DrawLineV(player_pos, corner, rl.GREEN);
        }
    }

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

    for go in game.gos {
        for i := 0; i < len(go.points); i += 1 {
            p1 := go.position + go.points[i];
            p2 := go.position + go.points[(i + 1) % len(go.points)];

            rl.DrawLineV(p1, p2, rl.RAYWHITE);
        }
    }

    rl.EndMode2D();
    rl.EndDrawing();
}
