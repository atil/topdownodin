package main

import "core:testing"

@(test)
test_ray_basic_1 :: proc(t: ^testing.T) {
    ray := Ray { Vec2 {0, 0},Vec2 {1, 0} };
    ls := LineSeg { Vec2{1, 1}, Vec2 {1, -1} };

    succ, hit_time := ray_line_intersection(ray, ls);

    testing.expect(t, succ);
    testing.expect(t, hit_time == 1);
}

@(test)
test_ray_basic_2 :: proc(t: ^testing.T) {
    ray := Ray { Vec2 {0, 0},Vec2 {1, 0} };
    ls := LineSeg { Vec2 {2, 1}, Vec2 {2, -1} };

    succ, hit_time := ray_line_intersection(ray, ls);

    testing.expect(t, succ);
    testing.expect(t, hit_time == 2);
}

@(test)
test_ray_edge_1 :: proc(t: ^testing.T) {
    ray := Ray { Vec2 {0, 0},Vec2 {1, 0} };
    ls := LineSeg { Vec2 {2, 1}, Vec2 {2, 0} };

    succ, hit_time := ray_line_intersection(ray, ls);

    testing.expect(t, succ);
    testing.expect(t, hit_time == 2);
}
