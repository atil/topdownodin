package main

import "core:fmt"
import "core:strings"
import "core:time"
import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import SDL "vendor:sdl2"
import SDL_IMG "vendor:sdl2/image"

Vec2 :: glm.vec2;
Vec2i :: glm.ivec2;

AssetDatabase :: struct {
    textures : map[string]^SDL.Surface,
}

GameConfig :: struct {
    screen_width : u32,
    screen_height : u32,
    player_speed : f32,
    cam_size : f32,

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
        player_speed = 50.0,
        cam_size = 5.0,
    };

    asset_db: AssetDatabase;
    asset_db.textures = make(map[string]^SDL.Surface);

    SDL.Init({.VIDEO});
	sdl_window := SDL.CreateWindow("Moving forward", 400, 200, cast(i32)config.screen_width, cast(i32)config.screen_height, {.OPENGL});
    gl_context := SDL.GL_CreateContext(sdl_window);
    SDL.GL_SetAttribute(.CONTEXT_PROFILE_MASK,  i32(SDL.GLprofile.CORE));
	SDL.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, 4);
	SDL.GL_SetAttribute(.CONTEXT_MINOR_VERSION, 6);
    gl.load_up_to(4, 6, SDL.gl_set_proc_address);

    asset_database_add_image(&asset_db, "Ball");
    asset_database_add_image(&asset_db, "Field");
    asset_database_add_image(&asset_db, "PadBlue");
    asset_database_add_image(&asset_db, "PadGreen");

    input: Input;

    game: Game;
    game_init(&game, &asset_db, &config, &input);

    render_context: RenderContext = ---;
    aspect := cast(f32)config.screen_width / cast(f32)config.screen_height;
    render_context.view = glm.mat4LookAt(glm.vec3 {0, 0, 0}, glm.vec3 {0, 0, -1}, glm.vec3 {0, 1, 0});
    render_context.proj = glm.mat4Ortho3d(-aspect * config.cam_size, aspect * config.cam_size, -config.cam_size, config.cam_size, -1, 1);

    prev := time.tick_now();
    main_loop: for {
        event: SDL.Event;
		for SDL.PollEvent(&event) {
            if (event.type == .QUIT) {
                break main_loop;
            }
            input_update_sdl(&input, event);
		}

        now := time.tick_now();
        dt := time.duration_seconds(time.tick_diff(prev, now));

        game_update(&game, cast(f32)dt);

        cam_target := glm.vec3 {game.cam_target.x, game.cam_target.y, 0};
        // fmt.println(game.player.position, cam_target); // start from here: figure out why the cam is centered around origin and not moving with the player
        render_context.view = glm.mat4LookAt(cam_target, cam_target + glm.vec3 {0, 0, -1}, glm.vec3 {0, 1, 0});

        game_render(&game, &render_context);

        debug_draw_flush(&render_context);
        
        SDL.GL_SwapWindow(sdl_window);

        prev = now;
    }

    game_deinit(&game);
    asset_database_deinit(&asset_db);

    SDL.GL_DeleteContext(gl_context);
    SDL.DestroyWindow(sdl_window);
    SDL.Quit();
}
