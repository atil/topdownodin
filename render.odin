package main

import "core:fmt"
import "core:strings"
import gl "vendor:OpenGL"
import glm "core:math/linalg/glsl"
import SDL "vendor:sdl2"
import SDL_TTF "vendor:sdl2/ttf"

Color :: struct {
    r, g, b, a: f32 
}

ColorRed :: Color { 255, 0, 0, 255 }
ColorGreen :: Color { 0, 255, 0, 255 }
ColorBlue :: Color { 0, 0, 255, 255 }
ColorGray :: Color { 100, 100, 100, 255 }
ColorYellow :: Color { 255, 255, 0, 255 }

RenderContext :: struct {
    view: glm.mat4,
    proj: glm.mat4,
}

BufferHandle :: u32; // These should be private, but "debug" uses them
ShaderHandle :: u32;
TextureHandle :: u32;

RenderUnit :: struct {
    vao, vbo, ebo: BufferHandle,
    shader: ShaderHandle,
    shader_uniforms: gl.Uniforms,
    index_count: u32,
    texture: TextureHandle,
}

@(private="file")
RenderVertex :: struct {
    pos, texcoord: Vec2,
}

render_init :: proc(render_context: ^RenderContext, config: ^GameConfig) {
    gl.Enable(gl.BLEND);
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

    aspect := cast(f32)config.screen_width / cast(f32)config.screen_height;
    cam := config.cam_size;
    render_context.view = glm.mat4LookAt(glm.vec3 {0, 0, 0}, glm.vec3 {0, 0, -1}, glm.vec3 {0, 1, 0});
    render_context.proj = glm.mat4Ortho3d(-aspect * cam, aspect * cam, -cam, cam, -1, 1);
}

render_init_ru :: proc(points: []Vec2, texcoords: []Vec2, tex_name: string, db: ^AssetDatabase) -> RenderUnit {

    assert(len(points) == len(texcoords));

    ru: RenderUnit = ---;
    shader, shader_ok := gl.load_shaders_file("assets/shaders/world.vert", "assets/shaders/world.frag");
    assert(shader_ok, "Shader error");

    ru.shader = shader;
    ru.shader_uniforms = gl.get_uniforms_from_program(ru.shader);

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
    gl.GenBuffers(1, &ru.ebo);

    gl.BindBuffer(gl.ARRAY_BUFFER, ru.vbo);
    gl.BufferData(gl.ARRAY_BUFFER, vert_count * size_of(RenderVertex), raw_data(render_verts), gl.STATIC_DRAW);
    gl.EnableVertexAttribArray(0);
    gl.EnableVertexAttribArray(1);
    gl.VertexAttribPointer(0, 2, gl.FLOAT, false, size_of(RenderVertex), offset_of(RenderVertex, pos));
    gl.VertexAttribPointer(1, 2, gl.FLOAT, false, size_of(RenderVertex), offset_of(RenderVertex, texcoord));

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ru.ebo);
	indices := []u16 { // TODO @INCOMPLETE: We assume these to be quads for now
		0, 1, 2,
		2, 3, 0,
	};	
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(indices)*size_of(indices[0]), raw_data(indices), gl.STATIC_DRAW);
    ru.index_count = cast(u32)len(indices);

    tex: TextureHandle = ---;
    gl.GenTextures(1, &tex);
    gl.BindTexture(gl.TEXTURE_2D, tex);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

    surf, ok := db.textures[tex_name]; assert(ok, "Texture should be there");

    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, surf.w, surf.h, 0, gl.RGBA, gl.UNSIGNED_BYTE, surf.pixels);

    gl.UseProgram(ru.shader);
    gl.Uniform1i(ru.shader_uniforms["u_texture"].location, 0);
    ru.texture = tex;

    return ru;
}

render_deinit_ru :: proc(ru: ^RenderUnit) {
    gl.DeleteProgram(ru.shader);
    gl.DeleteVertexArrays(1, &ru.vao);
    gl.DeleteBuffers(1, &ru.vbo);
    gl.DeleteBuffers(1, &ru.ebo);
    delete(ru.shader_uniforms);
}

render_init_text_ru :: proc(world_pos: Vec2, size: f32, content: string, color: Color, font: ^SDL_TTF.Font) -> RenderUnit {

    ru: RenderUnit = ---;
    shader, shader_ok := gl.load_shaders_file("assets/shaders/ui.vert", "assets/shaders/ui.frag");
    assert(shader_ok, "UI shader error");

    ru.shader = shader;
    ru.shader_uniforms = gl.get_uniforms_from_program(ru.shader);

    half_size := size / 2.0;
    render_verts: []RenderVertex = {
        RenderVertex { Vec2 {-half_size, -half_size}, Vec2 {0.0, 0.0} },
        RenderVertex { Vec2 {-half_size,  half_size}, Vec2 {0.0, 1.0} },
        RenderVertex { Vec2 { half_size,  half_size}, Vec2 {1.0, 1.0} },
        RenderVertex { Vec2 { half_size, -half_size}, Vec2 {1.0, 0.0} },
    };

    gl.GenVertexArrays(1, &ru.vao);
    gl.BindVertexArray(ru.vao);
    gl.GenBuffers(1, &ru.vbo);
    gl.GenBuffers(1, &ru.ebo);

    gl.BindBuffer(gl.ARRAY_BUFFER, ru.vbo);
    gl.BufferData(gl.ARRAY_BUFFER, 4 * size_of(RenderVertex), raw_data(render_verts), gl.STATIC_DRAW);
    gl.EnableVertexAttribArray(0);
    gl.EnableVertexAttribArray(1);
    gl.VertexAttribPointer(0, 2, gl.FLOAT, false, size_of(RenderVertex), offset_of(RenderVertex, pos));
    gl.VertexAttribPointer(1, 2, gl.FLOAT, false, size_of(RenderVertex), offset_of(RenderVertex, texcoord));

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ru.ebo);
	indices := []u16 { 0, 1, 2, 2, 3, 0, };	
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(indices) * size_of(indices[0]), raw_data(indices), gl.STATIC_DRAW);
    ru.index_count = cast(u32)len(indices);

    tex: TextureHandle = ---;
    gl.GenTextures(1, &tex);
    gl.BindTexture(gl.TEXTURE_2D, tex);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

    content_cstr: cstring = strings.clone_to_cstring(content); // TODO @LEAK: Should we free cstr's?
    text_surf := SDL_TTF.RenderText_Blended(font, content_cstr, SDL.Color {255, 255, 255, 255});
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, text_surf.w, text_surf.h, 0, gl.BGRA, gl.UNSIGNED_BYTE, text_surf.pixels); // start from here: make this work
    SDL.FreeSurface(text_surf);

    gl.UseProgram(ru.shader);
    gl.Uniform1i(ru.shader_uniforms["u_texture"].location, 0);
    col := Color { 0, 0, 1, 1};
    gl.Uniform4fv(ru.shader_uniforms["u_color"].location, 1, &col.r);
    ru.texture = tex;

    return ru;
}

game_render :: proc(game: ^Game, render_context: ^RenderContext) {
    gl.Viewport(0, 0, cast(i32)game.config.screen_width, cast(i32)game.config.screen_height); // TODO @CLEANUP: can this be moved to init?
    gl.ClearColor(0.5, 0.7, 1.0, 1.0);
    gl.Clear(gl.COLOR_BUFFER_BIT);

    // for _,i in game.gameobjects {
    //     go := &game.gameobjects[i];
    //     gl.BindVertexArray(go.render_unit.vao);
    //     gl.UseProgram(go.render_unit.shader);

    //     gl.ActiveTexture(gl.TEXTURE0);
    //     gl.BindTexture(gl.TEXTURE_2D, go.render_unit.texture);

    //     model := glm.mat4Translate(glm.vec3 {go.go_data.position.x , go.go_data.position.y, 0});

    //     u_transform := render_context.proj * render_context.view * model;
    //     loc := go.render_unit.shader_uniforms["u_transform"].location;
    //     gl.UniformMatrix4fv(loc, 1, false, &u_transform[0, 0]);
    //     gl.DrawElements(gl.TRIANGLES, cast(i32)go.render_unit.index_count, gl.UNSIGNED_SHORT, nil);
    // }


    // TODO @TEMP

    ru := &game.test_text_ru;
    gl.BindVertexArray(ru.vao);
    gl.UseProgram(ru.shader);

    gl.ActiveTexture(gl.TEXTURE0);
    gl.BindTexture(gl.TEXTURE_2D, ru.texture);

    model := glm.mat4Translate(glm.vec3 {0, 0, 0});

    u_transform := render_context.proj * render_context.view * model;
    loc := ru.shader_uniforms["u_transform"].location;
    gl.UniformMatrix4fv(loc, 1, false, &u_transform[0, 0]);
    gl.DrawElements(gl.TRIANGLES, cast(i32)ru.index_count, gl.UNSIGNED_SHORT, nil);


    // player_data := &game.player.go_data;
    // for _, i in player_data.points {
    //     p1 := player_data.position + player_data.points[i];
    //     p2 := player_data.position + player_data.points[(i + 1) % len(player_data.points)];
    //     debug_draw_line(p1, p2, ColorBlue);
    // }

}
