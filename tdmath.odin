package main

import "core:testing"

// TODO: replace these with the core package procs
dot :: proc (a: Vec2, b: Vec2) -> f32 {
    return a.x * b.x + a.y * b.y;
}

cross :: proc(a: Vec2, b: Vec2) -> f32 {
    return a.x * b.y - a.y * b.x;
}

ray_line_intersection :: proc(origin: Vec2, dir: Vec2, a: Vec2, b: Vec2) -> (bool, f32) {
    v1 := origin - a;
    v2 := b - a;
    v3 := Vec2 { -dir.y, dir.x };

    t1 := cross(v2, v1) / dot(v2, v3);
    t2 := dot(v1, v3) / dot(v2, v3);

    EPS :: 0.00001;

    hit_time := t1;
    succ := t1 >= 0 && t2 + EPS >= 0 && t2 - EPS <= 1;

    return succ, hit_time;
}

@(test)
ray_test_1 :: proc(t: ^testing.T) {
    testing.expect(t, true);
}
