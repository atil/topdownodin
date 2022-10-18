package main

import "core:math"
import "core:math/linalg"
import "core:fmt"
import "core:sort"

@(private="file")
game_is_visible :: proc(obstacle_edges: ^[dynamic]LineSeg, line_seg: LineSeg) -> bool {

    for edge in obstacle_edges {
        succ, intersection := line_line_intersection(edge, line_seg);
        if succ do return false;
    }

    return true;
}

@(private="file")
game_visibility_query :: proc(obstacle_edges: ^[dynamic]LineSeg, ray: Ray) -> Vec2 {
    MAX_VISIBILITY_DIST :: 999.0;

    min_dist: f32 = MAX_VISIBILITY_DIST;
    for edge in obstacle_edges {
        succ, hit_time := ray_line_intersection(ray, edge);
        if (succ && hit_time < min_dist) {
            min_dist = hit_time;
        }
    }

    return ray.origin + ray.dir * min_dist;
}

game_compute_visibility_shape :: proc(game: ^Game) {
    clear(&game.visible_corners);
    player_pos := game.player.go_data.position;

    for corner in game.obstacle_corners {

        if (!game_is_visible(&game.obstacle_edges, LineSeg { player_pos, corner })) do continue;

        append(&game.visible_corners, corner);

        ray := Ray { player_pos, linalg.vector_normalize(corner - player_pos) };
    
        ray_delta1 := ray;
        ray_delta1.dir = vec2_rotate(ray_delta1.dir, 1);

        ray_delta2 := ray;
        ray_delta2.dir = vec2_rotate(ray_delta2.dir, -1);

        delta1 := game_visibility_query(&game.obstacle_edges, ray_delta1);
        delta2 := game_visibility_query(&game.obstacle_edges, ray_delta2);

        EPS :: 10.0
        if (!vec2_almost_same(delta1, corner, EPS)) do append(&game.visible_corners, delta1);
        if (!vec2_almost_same(delta2, corner, EPS)) do append(&game.visible_corners, delta2);
    }

    for world_corner in game.world_corners {
        if (game_is_visible(&game.obstacle_edges, LineSeg { player_pos, world_corner })) {
            append(&game.visible_corners, world_corner);
        }
    }

    clockwise_sort_lambda :: proc(a: Vec2, b: Vec2) -> int {
        angle_a := math.atan2(a.y, a.x);
        angle_b := math.atan2(b.y, b.x);
        if (angle_a == angle_b) do return 0;
        if (angle_a > angle_b) do return -1;
        return 1;
    }

    // Switching to local space (of the player) when sorting the corners,
    // because Odin doesn't have captures, so we can't pass in the player position.

    visible_corners_local := make([]Vec2, len(game.visible_corners));
    defer delete(visible_corners_local);
    copy(visible_corners_local, game.visible_corners[:]);
    for _, i in game.visible_corners {
        visible_corners_local[i] = game.visible_corners[i] - player_pos;
    }

    sort.quick_sort_proc(visible_corners_local, clockwise_sort_lambda);

    for _, i in visible_corners_local {
        game.visible_corners[i] = visible_corners_local[i] + player_pos;
    }

}
