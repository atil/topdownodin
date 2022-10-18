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

BufferHandle :: u32; // These should be private, but "debug" uses them
ShaderHandle :: u32;

RenderUnit :: struct {
    vao, vbo, ebo: BufferHandle,
    shader: ShaderHandle,
    shader_uniforms: gl.Uniforms,
}

@(private="file")
RenderVertex :: struct {
    pos, texcoord: Vec2,
}

render_init_ru :: proc(points: []Vec2, texcoords: []Vec2, tex_name: string) -> RenderUnit {
    assert(len(points) == len(texcoords));

    ru: RenderUnit = ---;
    shader, shader_ok := gl.load_shaders_file("assets/shaders/world.vert", "assets/shaders/world.frag");
    if (!shader_ok) {
        fmt.eprintln("Shader error"); // TODO @INCOMPLETE: Handle fatal errors by crashing the thing
    }

    vert_count := len(points);
    render_verts := make([]RenderVertex, vert_count);
    defer delete(render_verts);

    for i in 0..<vert_count {
        render_verts[i].pos = points[i];
        render_verts[i].texcoord = texcoords[i];
    }
    
    gl.GenVertexArrays(1, &ru.vao);
    gl.BindVertexArray(ru.vao);
    gl.GenBuffers(1, &ru.vbo);

    gl.BindBuffer(gl.ARRAY_BUFFER, ru.vbo);
    gl.EnableVertexAttribArray(0);
    gl.EnableVertexAttribArray(1);
    gl.VertexAttribPointer(0, 2, gl.FLOAT, false, size_of(RenderVertex), offset_of(RenderVertex, pos));
    gl.VertexAttribPointer(1, 2, gl.FLOAT, false, size_of(RenderVertex), offset_of(RenderVertex, texcoord));
    
    gl.BufferData(gl.ARRAY_BUFFER, vert_count * size_of(RenderVertex), raw_data(render_verts), gl.STATIC_DRAW);

    return ru;
}

render_deinit_ru :: proc(ru: ^RenderUnit) {
    gl.DeleteProgram(ru.shader);
    gl.DeleteVertexArrays(1, &ru.vao);
    gl.DeleteBuffers(1, &ru.vbo);
    gl.DeleteBuffers(1, &ru.ebo);
    delete(ru.shader_uniforms);
}

game_render :: proc(game: ^Game, render_context: ^RenderContext) {
    gl.Viewport(0, 0, cast(i32)game.config.screen_width, cast(i32)game.config.screen_height);
    gl.ClearColor(0.5, 0.7, 1.0, 1.0);
    gl.Clear(gl.COLOR_BUFFER_BIT);

    player_data := &game.player.go_data;

    for _, i in player_data.points {
        p1 := player_data.position + player_data.points[i];
        p2 := player_data.position + player_data.points[(i + 1) % len(player_data.points)];

        debug_draw_line(p1, p2, ColorBlue);
    }

}
