package main

import "core:fmt"
import "core:math/linalg"

Vec2_Up :: Vec2 {0, -1};

Ray :: struct {
    origin: Vec2,
    dir: Vec2,
}

LineSeg :: struct {
    a: Vec2,
    b: Vec2,
}

vec2_rotate :: proc(v: Vec2, deg: f32) -> Vec2 {
    rads := deg * linalg.RAD_PER_DEG;
    x := v.x * linalg.cos(rads) - v.y * linalg.sin(rads);
    y := v.x * linalg.sin(rads) + v.y * linalg.cos(rads);
    return Vec2 {x, y};
}

vec2_almost_same :: proc(v1: Vec2, v2: Vec2, eps: f32) -> bool {
    return linalg.vector_length2(v1 - v2) < eps * eps;
}

// Taken from:
// https://rootllama.wordpress.com/2014/06/20/ray-line-segment-intersection-test-in-2d/
ray_line_intersection :: proc(ray: Ray, line: LineSeg) -> (bool, f32) {
    v1 := ray.origin - line.a;
    v2 := line.b - line.a;
    v3 := Vec2 { -ray.dir.y, ray.dir.x };

    t1 := linalg.cross(v2, v1) / linalg.dot(v2, v3);
    t2 := linalg.dot(v1, v3) / linalg.dot(v2, v3);

    EPS :: 0.00001;

    hit_time := t1;
    succ := t1 >= 0 && t2 + EPS >= 0 && t2 - EPS <= 1; // Points included

    return succ, hit_time;
}

// Taken from:
// https://stackoverflow.com/questions/563198/how-do-you-detect-where-two-line-segments-intersect/1201356#comment19165734_565282
line_line_intersection :: proc(line1: LineSeg, line2: LineSeg) -> (bool, Vec2) {
    c := line2.a - line1.a;
    a_dir := line1.b - line1.a;
    b_dir := line2.b - line2.a;

    cXa := c.x * a_dir.y - c.y * a_dir.x;
    cXb := c.x * b_dir.y - c.y * b_dir.x;
    aXb := a_dir.x * b_dir.y - a_dir.y * b_dir.x;

    if (cXa == 0 && cXb == 0) {

        // One point is common. Return that one
        EPS :: 0.00001
        if (vec2_almost_same(line1.a, line2.a, EPS)) do return true, line1.a;
        if (vec2_almost_same(line1.a, line2.b, EPS)) do return true, line1.a;
        if (vec2_almost_same(line1.b, line2.a, EPS)) do return true, line1.b;
        if (vec2_almost_same(line1.b, line2.b, EPS)) do return true, line1.b;

        // Check if they're overlapping
        overlap_x := (line2.a.x - line1.a.x < 0.0) != (line2.a.x - line1.b.x < 0.0);
        overlap_y := (line2.a.y - line1.a.y < 0.0) != (line2.a.y - line1.b.y < 0.0);

        if (overlap_x || overlap_y) do return true, line2.a;
    }

    if (aXb == 0) do return false, Vec2 {0, 0}; // Lines are parallel

    t := cXa / aXb;
    u := cXb / aXb;

    EPS :: 0.001

    succ := (t - EPS > 0 && t + EPS < 1) && (u - EPS > 0 && u + EPS < 1); // Points excluded
    intersection := line1.a + (a_dir * t);

    return succ, intersection;
}
