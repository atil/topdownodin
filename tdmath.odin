package main

import math "core:math/linalg"

Vec2_Up :: Vec2 {0, -1};

// Taken from:
// https://rootllama.wordpress.com/2014/06/20/ray-line-segment-intersection-test-in-2d/
ray_line_intersection :: proc(origin: Vec2, dir: Vec2, a: Vec2, b: Vec2) -> (bool, f32) {
    v1 := origin - a;
    v2 := b - a;
    v3 := Vec2 { -dir.y, dir.x };

    t1 := math.cross(v2, v1) / math.dot(v2, v3);
    t2 := math.dot(v1, v3) / math.dot(v2, v3);

    EPS :: 0.00001;

    hit_time := t1;
    succ := t1 >= 0 && t2 + EPS >= 0 && t2 - EPS <= 1;

    return succ, hit_time;
}
