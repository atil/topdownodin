package main

import math "core:math"
import "core:fmt"
import "core:strings"
import gl "vendor:OpenGL"
import glm "core:math/linalg/glsl"

@(private="file")
DebugDrawType :: enum {
    Line,
    Circle,
}

@(private="file")
DebugDrawCommand :: struct {
    points: [dynamic]Vec2,
    color: Color,
    draw_type: DebugDrawType
}

@(private="file")
DebugDrawTextCommand :: struct {
    content: string,
    world_position: Vec2,
    color: Color,
}

@(private="file")
debug_draw_commands: [dynamic]DebugDrawCommand;

@(private="file")
debug_draw_text_commands: [dynamic]DebugDrawTextCommand;

debug_draw_line :: proc(start: Vec2, end: Vec2, color: Color) {
    append(&debug_draw_commands, DebugDrawCommand {
        {start, end} /* We don't use make() here? */, color, DebugDrawType.Line
    });
}

debug_draw_circle :: proc(center: Vec2, radius: f32, color: Color) {
    POINT_COUNT :: 20;

    angle_step_rad: f32 = (360 / POINT_COUNT) * math.RAD_PER_DEG;
    points := make([dynamic]Vec2, POINT_COUNT);
    for i in 0..<POINT_COUNT {
        x := math.cos(angle_step_rad * cast(f32)i) * radius;
        y := math.sin(angle_step_rad * cast(f32)i) * radius;
        points[i] = center + Vec2 {x, y};
    }

    append(&debug_draw_commands, DebugDrawCommand {
        points, color, DebugDrawType.Circle });
}

debug_draw_text :: proc(content: string, world_position: Vec2, color: Color) {
    append(&debug_draw_text_commands, DebugDrawTextCommand {
        content, world_position, color });
}

debug_draw_flush :: proc(render_context: ^RenderContext) {
    for command in debug_draw_commands {
        switch command.draw_type {
            case .Line: 
                draw_line_immediate(command.points[0], command.points[1], command.color, render_context);
            case .Circle: {
                point_count := len(command.points);
                for i in 0..<point_count {
                    draw_line_immediate(command.points[i], command.points[(i + 1) % point_count], command.color, render_context);
                }
            }
        }

        delete(command.points);
    }

    clear(&debug_draw_commands);

    for command in debug_draw_text_commands {
        // TODO @INCOMPLETE: Drawing text
        // the_cstr: cstring = strings.clone_to_cstring(command.content);
        // rl.DrawText(the_cstr, cast(i32)command.world_position.x, cast(i32)command.world_position.y, 20, rl.RED);
    }

    clear(&debug_draw_text_commands);
}

@(private="file")
DebugRenderUnit :: struct {
    vao, vbo: BufferHandle,
    debug_shader: ShaderHandle,
    debug_shader_uniforms: gl.Uniforms,
}

@(private="file")
DebugRenderVertex :: struct {
    pos: Vec2,
}

@(private="file")
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
