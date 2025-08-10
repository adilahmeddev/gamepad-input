#+feature dynamic-literals
package odin

import "base:intrinsics"
import "core:fmt"
import "core:reflect"
import "core:slice"
import "core:strings"
import rl "vendor:raylib"
reduce :: slice.reduce
mapper :: slice.mapper
filter :: slice.filter

ICON_SIZE :: 16
WINDOW_WIDTH :: 1920
WINDOW_HEIGHT :: 1080
INPUT_HISTORY_SIZE :: 10

ButtonCombination :: struct {
	buttons: []rl.GamepadButton,
	frames:  f64,
}

Input :: struct {
	name: cstring,
	x:    int,
	y:    int,
}

buttons := map[rl.GamepadButton]Input {
	.LEFT_FACE_UP     = {"LEFT_FACE_UP", 0, 1},
	.LEFT_FACE_LEFT   = {"LEFT_FACE_LEFT", 1, 1},
	.LEFT_FACE_DOWN   = {"LEFT_FACE_DOWN", 2, 1},
	.LEFT_FACE_RIGHT  = {"LEFT_FACE_RIGHT", 3, 1},
	.RIGHT_FACE_UP    = {"RIGHT_FACE_UP", 0, 0},
	.RIGHT_FACE_LEFT  = {"RIGHT_FACE_LEFT", 1, 0},
	.RIGHT_FACE_DOWN  = {"RIGHT_FACE_DOWN", 2, 0},
	.RIGHT_FACE_RIGHT = {"RIGHT_FACE_RIGHT", 3, 0},
}
InputArray :: [INPUT_HISTORY_SIZE]ButtonCombination

main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Gamepad Input Display - Raylib")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	icon_texture := rl.LoadTexture("sprites/icons.png")
	defer rl.UnloadTexture(icon_texture)


	inputs := InputArray{}
	for !rl.WindowShouldClose() {

		old_inputs := copy_inputs(inputs)
		if rl.IsGamepadAvailable(0) {
			gamepad_name := rl.GetGamepadName(0)
			rl.SetWindowTitle(fmt.ctprintf("FPS: %v | Gamepad: %s", rl.GetFPS(), gamepad_name))

			current_buttons := get_pressed_buttons()

			update_input_history(&inputs, current_buttons)

			if !slice_eq(inputs, old_inputs, proc(a, b: ButtonCombination) -> bool {
				return slice.equal(a.buttons, b.buttons)
			}) {
				button_names := mapper(inputs[:], button_combination_to_string)
				pressed_button_names, err := filter(button_names, proc(s: string) -> bool {
					return s != ""
				})
				assert(err == nil)
				fmt.printfln("%#v", pressed_button_names)
			}
		} else {
			rl.SetWindowTitle(fmt.ctprintf("FPS: %v | No gamepad detected", rl.GetFPS()))
		}

		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.ClearBackground(rl.LIGHTGRAY)
		draw_input_history(icon_texture, inputs)
	}

}

get_pressed_buttons :: proc() -> []rl.GamepadButton {
	btns, err := slice.map_keys(buttons)
	assert(err == nil)

	return filter(btns, proc(button: rl.GamepadButton) -> bool {
		return rl.IsGamepadButtonDown(0, button)
	})
}

update_input_history :: proc(inputs: ^InputArray, current_buttons: []rl.GamepadButton) {
	last_input := &inputs[INPUT_HISTORY_SIZE - 1]

	if !slice.equal(current_buttons[:], last_input.buttons[:]) {
		for i := 0; i < INPUT_HISTORY_SIZE - 1; i += 1 {
			inputs[i] = inputs[i + 1]
		}

		inputs[INPUT_HISTORY_SIZE - 1] = ButtonCombination {
			buttons = current_buttons,
			frames  = 1,
		}
	} else {
		last_input.frames += 1
	}
}

draw_button_icon :: proc(texture: rl.Texture2D, button: ^Input, x, y: f32) {
	if button == nil do return

	source_rect := rl.Rectangle {
		x      = auto_cast button.x * ICON_SIZE,
		y      = auto_cast button.y * ICON_SIZE,
		width  = auto_cast ICON_SIZE,
		height = auto_cast ICON_SIZE,
	}

	position := rl.Vector2{x, y}
	rl.DrawTextureRec(texture, source_rect, position, rl.RAYWHITE)
}

draw_input_history :: proc(icon_texture: rl.Texture2D, inputs: InputArray) {
	for input, index in inputs {
		y_pos := 660 - f32(index) * 70

		rl.DrawText(fmt.ctprintf("%.0f: ", input.frames), 20, i32(y_pos), 10, rl.RAYWHITE)

		for button_code, button_index in input.buttons {
			button, ok := buttons[button_code]
			if !ok {
				continue
			}

			x_pos := 40 + f32(ICON_SIZE * button_index)
			draw_button_icon(icon_texture, &button, x_pos, y_pos)
		}
	}
}

copy_inputs :: proc(inputs: InputArray) -> InputArray {
	copy := InputArray{}
	for input, i in inputs {
		copy[i].buttons = input.buttons
	}
	return copy
}

slice_eq :: proc(a, b: [INPUT_HISTORY_SIZE]$E, cmp: proc(_, _: E) -> bool) -> bool {
	if len(a) != len(b) {
		return false
	}
	eq := true
	for i := 0; i < len(a); i += 1 {
		eq &= cmp(a[i], b[i])
	}

	return eq
}

reduce_strings_fn :: proc(acc: string, val: rl.GamepadButton) -> string {
	builder, err := strings.builder_make()
	assert(err == nil)
	return fmt.sbprintf(&builder, "%s + %s", acc, buttons[val].name)
}

button_combination_to_string :: proc(it: ButtonCombination) -> string {
	return reduce(it.buttons, "", reduce_strings_fn)
}
