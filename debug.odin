package main

import rl "vendor:raylib"

DebugDrawType :: enum {
    Line,
}

DebugDrawCommand :: struct {
    points: [dynamic]Vec2,
    color: rl.Color,
    type: DebugDrawType
}

debug_draw_commands: [dynamic]DebugDrawCommand;

debug_draw_line :: proc(start: Vec2, end: Vec2, color: rl.Color) {
    append(&debug_draw_commands, DebugDrawCommand {
        {start, end}, color, DebugDrawType.Line
    });
}

debug_draw_flush :: proc() {
    for command in debug_draw_commands {
        switch command.type {
            case .Line: rl.DrawLineV(command.points[0], command.points[1], command.color);
        }
    }

    clear(&debug_draw_commands);
}
