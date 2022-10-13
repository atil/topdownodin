package main
import SDL "vendor:sdl2"

KeyCode :: enum u32 {
    W = 0,
    S,
    A,
    D,

    MAX,
}

Input :: struct {
    keys_prev: [KeyCode.MAX]bool,
    keys_curr: [KeyCode.MAX]bool,

    mouse_pos: Vec2i,
}

input_update_sdl :: proc(input: ^Input, event: SDL.Event) {
    copy_slice(input.keys_prev[:], input.keys_curr[:]);

    #partial switch event.type {
    case .KEYDOWN:
        #partial switch event.key.keysym.sym {
        case .W: input.keys_curr[cast(u32)KeyCode.W] = true;
        case .S: input.keys_curr[cast(u32)KeyCode.S] = true;
        case .A: input.keys_curr[cast(u32)KeyCode.A] = true;
        case .D: input.keys_curr[cast(u32)KeyCode.D] = true;
        }

    case .KEYUP:
        #partial switch event.key.keysym.sym {
        case .W: input.keys_curr[cast(u32)KeyCode.W] = false;
        case .S: input.keys_curr[cast(u32)KeyCode.S] = false;
        case .A: input.keys_curr[cast(u32)KeyCode.A] = false;
        case .D: input.keys_curr[cast(u32)KeyCode.D] = false;
        }
    case .MOUSEMOTION:
        x, y: i32;
        SDL.GetGlobalMouseState(&x, &y);
        input.mouse_pos = {x, y};
    }

}

input_is_key_down :: proc(input: ^Input, key: KeyCode) -> bool {
    return input.keys_curr[cast(u32)key];
}
