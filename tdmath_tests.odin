package main

import "core:testing"

@(test)
test_ray_basic_1 :: proc(t: ^testing.T) {
    ray_origin := Vec2 {0, 0};
    ray_dir := Vec2 {1, 0};

    ls1 := Vec2 {1, 1};
    ls2 := Vec2 {1, -1};

    succ, hit_time := ray_line_intersection(ray_origin, ray_dir, ls1, ls2);

    testing.expect(t, succ);
    testing.expect(t, hit_time == 1);
}

@(test)
test_ray_basic_2 :: proc(t: ^testing.T) {
    ray_origin := Vec2 {0, 0};
    ray_dir := Vec2 {1, 0};

    ls1 := Vec2 {2, 1};
    ls2 := Vec2 {2, -1};

    succ, hit_time := ray_line_intersection(ray_origin, ray_dir, ls1, ls2);

    testing.expect(t, succ);
    testing.expect(t, hit_time == 2);
}

@(test)
test_ray_edge_1 :: proc(t: ^testing.T) {
    ray_origin := Vec2 {0, 0};
    ray_dir := Vec2 {1, 0};
    ls1 := Vec2 {2, 1};
    ls2 := Vec2 {2, 0};

    succ, hit_time := ray_line_intersection(ray_origin, ray_dir, ls1, ls2);

    testing.expect(t, succ);
    testing.expect(t, hit_time == 2);
}
