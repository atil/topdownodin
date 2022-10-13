package main

import gl "vendor:OpenGL"

Color :: struct {
    r, g, b, a: f32 
}

ColorRed :: Color { 255, 0, 0, 255 }
ColorBlue :: Color { 0, 0, 255, 255 }

RenderUnit :: struct {

}

DebugRenderUnit :: struct {
    
}

draw_line :: proc(a, b: Vec2, color: Color) {
}
