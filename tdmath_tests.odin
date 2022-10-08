package main

import "core:testing"
import "core:fmt"
import "core:math"

@(test)
test_vector_rotate :: proc(t: ^testing.T) {
    v := Vec2 {1, 0};
    v_rotated := vec2_rotate(v, 90);
    v_rotated.x = math.round(v_rotated.x); // FP imprecision
    testing.expect(t, v_rotated == Vec2 {0, 1});
}

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

@(test)
test_line_line_intersect_basic :: proc(t: ^testing.T) {
    line1 := LineSeg { Vec2 {0, 0}, Vec2 {2, 0} };
    line2 := LineSeg { Vec2 {1, -1}, Vec2 {1, 1} };

    succ, intersection := line_line_intersection(line1, line2);

    testing.expect(t, succ);
    testing.expect(t, intersection == Vec2 {1, 0} );
}

@(test)
test_line_line_intersect_colinear_1 :: proc(t: ^testing.T) {
    line1 := LineSeg { Vec2 {0, 0}, Vec2 {1, 0} };
    line2 := LineSeg { Vec2 {1, 0}, Vec2 {2, 0} };

    succ, intersection := line_line_intersection(line1, line2);

    testing.expect(t, succ);
    testing.expect(t, intersection == Vec2 {1, 0} );
}

@(test)
test_line_line_intersect_colinear_2 :: proc(t: ^testing.T) {
    line1 := LineSeg { Vec2 {0, 0}, Vec2 {2, 0} };
    line2 := LineSeg { Vec2 {1, 0}, Vec2 {2, 0} };

    succ, intersection := line_line_intersection(line1, line2);

    testing.expect(t, succ);
    fmt.println(intersection);
    testing.expect(t, intersection == Vec2 {1, 0} );
}

@(test)
test_line_line_intersect_same :: proc(t: ^testing.T) {
    line1 := LineSeg { Vec2 {1, 0}, Vec2 {2, 0} };
    line2 := LineSeg { Vec2 {1, 0}, Vec2 {2, 0} };

    succ, intersection := line_line_intersection(line1, line2);

    testing.expect(t, succ);
    testing.expect(t, intersection == Vec2 {1, 0});
}

@(test)
test_line_line_intersect_negative :: proc(t: ^testing.T) {
    line1 := LineSeg { Vec2 {0, 0}, Vec2 {1, 0} };
    line2 := LineSeg { Vec2 {2, 0}, Vec2 {3, 0} };

    succ, intersection := line_line_intersection(line1, line2);

    testing.expect(t, !succ);
}

