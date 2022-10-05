package main

import math "core:math/linalg"

Vec2_Up :: Vec2 {0, -1};

Ray :: struct {
    origin: Vec2,
    dir: Vec2,
}

LineSeg :: struct {
    a: Vec2,
    b: Vec2,
}

// Taken from:
// https://rootllama.wordpress.com/2014/06/20/ray-line-segment-intersection-test-in-2d/
ray_line_intersection :: proc(ray: Ray, line: LineSeg) -> (bool, f32) {
    v1 := ray.origin - line.a;
    v2 := line.b - line.a;
    v3 := Vec2 { -ray.dir.y, ray.dir.x };

    t1 := math.cross(v2, v1) / math.dot(v2, v3);
    t2 := math.dot(v1, v3) / math.dot(v2, v3);

    EPS :: 0.00001;

    hit_time := t1;
    succ := t1 >= 0 && t2 + EPS >= 0 && t2 - EPS <= 1;

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

    t := cXa / aXb;
    u := cXb / aXb;

    EPS :: 0.001

    succ := (t - EPS > 0 && t + EPS < 1) && (u - EPS > 0 && u + EPS < 1);
    intersection := line1.a + (a_dir * t);

    return succ, intersection;
}
