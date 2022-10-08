package main

import "core:math/linalg"

game_is_visible :: proc(game: ^Game, line_seg: LineSeg) -> bool {

    for edge in game.obstacle_edges {
        succ, intersection := line_line_intersection(edge, line_seg);
        if succ do return false;
    }

    return true;
}

// TODO @CLEANUP: Make this "file" private
// TODO @CLEANUP: Send only the obstacle array, so that it'll be unit testable
game_visibility_query :: proc(game: ^Game, ray: Ray) -> Vec2 {
    MAX_VISIBILITY_DIST :: 999.0;

    min_dist: f32 = MAX_VISIBILITY_DIST;
    for edge in game.obstacle_edges {
        succ, hit_time := ray_line_intersection(ray, edge);
        if (succ && hit_time < min_dist) {
            min_dist = hit_time;
        }
    }

    return ray.origin + ray.dir * min_dist;
}

game_compute_visibility_shape :: proc(game: ^Game) {
    clear(&game.visible_corners);
    player_pos := game.player.position;

    for corner in game.obstacle_corners {

        ray := Ray { player_pos, linalg.vector_normalize(corner - player_pos) };

        if (game_is_visible(game, LineSeg { player_pos, corner })) {
            append(&game.visible_corners, corner);
            ray_delta1 := ray;
            ray_delta1.dir = vec2_rotate(ray_delta1.dir, 1);

            ray_delta2 := ray;
            ray_delta2.dir = vec2_rotate(ray_delta2.dir, -1);

            delta1 := game_visibility_query(game, ray_delta1);
            delta2 := game_visibility_query(game, ray_delta2);

            if (vec2_almost_same(delta1, corner, 0.1)) do append(&game.visible_corners, delta1);
            if (vec2_almost_same(delta2, corner, 0.1)) do append(&game.visible_corners, delta2);
        }
    }
}
