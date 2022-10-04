package main

import "core:fmt"
import "core:strings"
import "core:time"
import rl "vendor:raylib"

Vec2 :: rl.Vector2;

AssetDatabase :: struct {
    textures : map[string]rl.Texture,
}

GameConfig :: struct {
    screen_width : u32,
    screen_height : u32,
    player_speed : f32,
}

asset_database_add_image :: proc(db: ^AssetDatabase, name: string) {
    path := strings.concatenate([]string {"assets/", name, ".png"}[:] );
    img := rl.LoadImage(strings.unsafe_string_to_cstring(path));
    tex := rl.LoadTextureFromImage(img);
    db.textures[name] = tex;
    rl.UnloadImage(img)
}

main :: proc() {
    config := GameConfig { 
        screen_width = 640,
        screen_height = 480,
        player_speed = 300.0,
    };

    asset_db: AssetDatabase;
    asset_db.textures = make(map[string]rl.Texture);
    defer delete(asset_db.textures);

    rl.SetTraceLogLevel(rl.TraceLogLevel.ERROR);
    rl.InitWindow(cast(i32)config.screen_width, cast(i32)config.screen_height, "testing");
    rl.SetTargetFPS(60);

    asset_database_add_image(&asset_db, "Ball");
    asset_database_add_image(&asset_db, "Field");
    asset_database_add_image(&asset_db, "PadBlue");
    asset_database_add_image(&asset_db, "PadGreen");

    game: Game;
    game_init(&game, &asset_db, &config);

    prev := time.tick_now();
    for !rl.WindowShouldClose() {

        now := time.tick_now();
        dt := time.duration_seconds(time.tick_diff(prev, now));

        game_update(&game, cast(f32)dt);
        game_draw(&game);

        prev = now;
    }

    rl.CloseWindow();
}
