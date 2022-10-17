package main

import "core:fmt"
import gl "vendor:OpenGL"
import glm "core:math/linalg/glsl"

Color :: struct {
    r, g, b, a: f32 
}

ColorRed :: Color { 255, 0, 0, 255 }
ColorGreen :: Color { 0, 255, 0, 255 }
ColorBlue :: Color { 0, 0, 255, 255 }

RenderContext :: struct {
    view: glm.mat4,
    proj: glm.mat4,
}

RenderUnit :: struct {

}

DebugRenderUnit :: struct {
    vao, vbo: u32, // TODO @CLEANUP: Handle aliases for these u32's
    debug_shader: u32,
    debug_shader_uniforms: gl.Uniforms,
}

DebugRenderVertex :: struct {
    pos: Vec2,
}

draw_line_immediate :: proc(a, b: Vec2, color: Color, render_context: ^RenderContext) {
    ru: DebugRenderUnit = ---;

    debug_shader, debug_shader_ok := gl.load_shaders_file("assets/shaders/debug.vert", "assets/shaders/debug.frag");
    if (!debug_shader_ok) {
        fmt.eprintln("Shader error"); // TODO @INCOMPLETE: Handle fatal errors by crashing the thing
    }
    ru.debug_shader = debug_shader;

    vertices := []DebugRenderVertex {DebugRenderVertex {a}, DebugRenderVertex {b}};

    gl.GenVertexArrays(1, &ru.vao);
    gl.BindVertexArray(ru.vao);
    gl.GenBuffers(1, &ru.vbo);

    gl.BindBuffer(gl.ARRAY_BUFFER, ru.vbo);
    gl.EnableVertexAttribArray(0);
    gl.VertexAttribPointer(0, 2, gl.FLOAT, false, size_of(DebugRenderVertex), offset_of(DebugRenderVertex, pos));
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(DebugRenderVertex), raw_data(vertices), gl.STATIC_DRAW);

    ru.debug_shader_uniforms = gl.get_uniforms_from_program(ru.debug_shader);

    u_transform := render_context.proj * render_context.view * glm.identity(glm.mat4);
    
    gl.UseProgram(ru.debug_shader);
    gl.UniformMatrix4fv(ru.debug_shader_uniforms["u_transform"].location, 1, false, &u_transform[0, 0]);

    col := color; // Can't take the address of the parameter
    gl.Uniform4fv(ru.debug_shader_uniforms["u_color"].location, 1, &col.r);

    // Draw
    gl.BindVertexArray(ru.vao);
    gl.DrawArrays(gl.LINES, 0, 2);

    // Deinit
    gl.DeleteProgram(ru.debug_shader);
    gl.DeleteVertexArrays(1, &ru.vao);
    gl.DeleteBuffers(1, &ru.vbo);
    delete(ru.debug_shader_uniforms);
}

game_render :: proc(game: ^Game, render_context: ^RenderContext) {
    gl.Viewport(0, 0, cast(i32)game.config.screen_width, cast(i32)game.config.screen_height);
    gl.ClearColor(0.5, 0.7, 1.0, 1.0);
    gl.Clear(gl.COLOR_BUFFER_BIT);

    for _, i in game.player.points {
        p1 := game.player.position + game.player.points[i];
        p2 := game.player.position + game.player.points[(i + 1) % len(game.player.points)];

        debug_draw_line(p1, p2, ColorBlue);
    }

}
