package main

import math "core:math"
import "core:fmt"
import "core:strings"

DebugDrawType :: enum {
    Line,
    Circle,
}

DebugDrawCommand :: struct {
    points: [dynamic]Vec2,
    color: Color,
    draw_type: DebugDrawType
}

DebugDrawTextCommand :: struct {
    content: string,
    world_position: Vec2,
    color: Color,
}

debug_draw_commands: [dynamic]DebugDrawCommand;
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
        points, color, DebugDrawType.Circle
    });
}

debug_draw_text :: proc(content: string, world_position: Vec2, color: Color) {
    append(&debug_draw_text_commands, DebugDrawTextCommand {
        content, world_position, color
    });
}

debug_draw_flush :: proc() {
    for command in debug_draw_commands {
        switch command.draw_type {
            case .Line: 
                draw_line_immediate(command.points[0], command.points[1], command.color);
            case .Circle: {
                point_count := len(command.points);
                for i in 0..<point_count {
                    // rl.DrawLineV(command.points[i], command.points[(i + 1) % point_count], command.color);
                }
            }
        }

        delete(command.points);
    }

    clear(&debug_draw_commands);

    for command in debug_draw_text_commands {
        // the_cstr: cstring = strings.clone_to_cstring(command.content);
        // rl.DrawText(the_cstr, cast(i32)command.world_position.x, cast(i32)command.world_position.y, 20, rl.RED);
    }

    clear(&debug_draw_text_commands);
}
