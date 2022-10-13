package main

import gl "vendor:OpenGL"

Color :: struct {
    r, g, b: f32
}

ColorRed :: Color { 255, 0, 0 }

RenderUnit :: struct {

}

draw_line :: proc(a, b: Vec2, color: Color) {
}
