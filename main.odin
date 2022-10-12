package main

import "core:fmt"
import "core:strings"
import "core:time"
import glm "core:math/linalg/glsl"
import SDL "vendor:sdl2"
import SDL_IMG "vendor:sdl2/image"

Vec2 :: glm.vec2;

AssetDatabase :: struct {
    textures : map[string]^SDL.Surface,
}

GameConfig :: struct {
    screen_width : u32,
    screen_height : u32,
    player_speed : f32,
}

asset_database_add_image :: proc(db: ^AssetDatabase, name: string) {
    path := strings.concatenate([]string {"assets/", name, ".png"}[:] );
    surf := SDL_IMG.Load(strings.unsafe_string_to_cstring(path));
    db.textures[name] = surf;
}

asset_database_deinit :: proc(db: ^AssetDatabase) {
    for _, surf in db.textures {
        SDL.FreeSurface(surf);
    }
    delete(db.textures);
}

main :: proc() {
    config := GameConfig { 
        screen_width = 640,
        screen_height = 480,
        player_speed = 300.0,
    };

    asset_db: AssetDatabase;
    asset_db.textures = make(map[string]^SDL.Surface);
    defer asset_database_deinit(asset_db);

    SDL.Init({.VIDEO});
	sdl_window := SDL.CreateWindow("Moving forward", 0, 0, cast(i32)config.screen_width, cast(i32)config.screen_height, {.OPENGL});
    gl_context := SDL.GL_CreateContext(sdl_window);

    asset_database_add_image(&asset_db, "Ball");
    asset_database_add_image(&asset_db, "Field");
    asset_database_add_image(&asset_db, "PadBlue");
    asset_database_add_image(&asset_db, "PadGreen");

    game: Game;
    game_init(&game, &asset_db, &config);

    prev := time.tick_now();
    main_loop: for {
        event: SDL.Event;
		for SDL.PollEvent(&event) {
			#partial switch event.type {
			case .KEYDOWN:
				#partial switch event.key.keysym.sym {
				case .ESCAPE:
					break main_loop;
				}
			case .QUIT:
				break main_loop;
			}
		}

        now := time.tick_now();
        dt := time.duration_seconds(time.tick_diff(prev, now));

        game_update(&game, cast(f32)dt);
        game_draw(&game);

        prev = now;
    }

    SDL.GL_DeleteContext(gl_context);
    SDL.DestroyWindow(sdl_window);
    SDL.Quit();
}
