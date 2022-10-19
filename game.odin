package main

import "core:fmt"
import "core:math/linalg"
import glm "core:math/linalg/glsl"

@(private="file")
GoData :: struct {
    position: Vec2,
    size: Vec2,
    points: [dynamic]Vec2,
    texcoords: [dynamic]Vec2,
}

@(private="file")
GameObject :: struct {
    go_data: GoData,
    render_unit: RenderUnit,
}

Game :: struct {
    config: ^GameConfig,
    db: ^AssetDatabase,
    input: ^Input,

    gameobjects: [dynamic]GameObject,

    world_corners: [4]Vec2,
    obstacles: [dynamic]^GameObject,
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

    // game_add_quad(game, "obstacle1", "PadBlue", Vec2 {100, 200}, Vec2 {100, 100});
    // append(&game.obstacles, &(game.gameobjects[len(game.gameobjects) - 1]));

    // game_add_quad(game, "cursor", "Ball", Vec2 {0, 0}, Vec2 {1, 1});
    // game.cursor = &game.gameobjects[len(game.gameobjects) - 1];

    game_add_quad(game, "player", "Ball", Vec2 {0, 0}, Vec2 {1, 1});
    game.player = &game.gameobjects[len(game.gameobjects) - 1];

    for _,i in game.obstacles {
        obs_data : ^GoData = &(game.obstacles[i].go_data);
        corner_count := len(obs_data.points);
        obs_corners := make([]Vec2, corner_count);
        defer delete(obs_corners);

        for i in 0..<corner_count {
            corner := obs_data.points[i] + obs_data.position;
            append(&game.obstacle_corners, corner);

            line_seg := LineSeg { obs_data.position + obs_data.points[i], 
                obs_data.position + obs_data.points[(i + 1) % corner_count] };
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

@(private="file")
game_init_go :: proc(position: Vec2, size: Vec2) -> GoData {
    go: GoData = ---;
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
    return go;
}

@(private="file")
game_add_quad :: proc(game: ^Game, go_name: string, tex_name: string, position: Vec2, size: Vec2) {
    go: GameObject = ---;
    go.go_data = game_init_go(position, size);    
    go.render_unit = render_init_ru(go.go_data.points[:], go.go_data.texcoords[:], tex_name, game.db);

    append(&game.gameobjects, go);
}

game_update :: proc(game: ^Game, dt: f32) {

    move_dir := Vec2 {0, 0};
    if (input_is_key_down(game.input, KeyCode.W)) {
        move_dir += Vec2 {0, 1};
    } else if (input_is_key_down(game.input, KeyCode.S)) {
        move_dir += Vec2 {0, -1};
    }
    if (input_is_key_down(game.input, KeyCode.A)) {
        move_dir += Vec2 {-1, 0};
    } else if (input_is_key_down(game.input, KeyCode.D)) {
        move_dir += Vec2 {1, 0};
    }

    if (linalg.vector_length2(move_dir)) > 0.0001 {
        move_dir = linalg.vector_normalize(move_dir);
    }
    game.player.go_data.position += move_dir * (game.config.player_speed * dt);

    mouse_screen_pos := Vec2 { cast(f32)game.input.mouse_pos.x, cast(f32)game.input.mouse_pos.y }; // Convert to float vector
    mouse_world_pos := game_screen_to_world(game, mouse_screen_pos);

    game.cam_target = glm.lerp(game.player.go_data.position, mouse_world_pos, 0.1);

    game_compute_visibility_shape(game);
}

@(private="file")
game_screen_to_world :: proc(game: ^Game, screen_pos: Vec2) -> Vec2 {
    corrected_screen_pos := Vec2 { cast(f32)screen_pos.x, cast(f32)game.config.screen_height - screen_pos.y } ;
    single_pixel_world_size := Vec2 { 2.0 / cast(f32)game.config.screen_width, 2.0 / cast(f32)game.config.screen_height } * game.config.cam_size;

    midpoint_screen_pos := Vec2 { cast(f32)game.config.screen_width / 2.0, cast(f32)game.config.screen_height / 2.0 };
    mid_to_mouse_screen := corrected_screen_pos - midpoint_screen_pos;
    world_pos := Vec2 { mid_to_mouse_screen.x * single_pixel_world_size.x, mid_to_mouse_screen.y * single_pixel_world_size.y };

    return world_pos;
}
 
game_deinit :: proc(game: ^Game) {
    for _,i in game.gameobjects {
        render_deinit_ru(&game.gameobjects[i].render_unit);
    }
}
