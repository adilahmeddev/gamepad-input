package odin

import "core:fmt"
import "core:slice"
import rl "vendor:raylib"

buttonCombination :: struct {
	buttons: [dynamic]rl.GamepadButton,
	frames:  f64,
}
Input :: struct {
	code: rl.GamepadButton,
	name: cstring,
	x:    int,
	y:    int,
}

icon_size := 16

buttons := [8]Input {
	{code = .LEFT_FACE_UP, name = cstring("LEFT_FACE_UP"), x = 0, y = 1},
	{code = .LEFT_FACE_LEFT, name = cstring("LEFT_FACE_LEFT"), x = 1, y = 1},
	{code = .LEFT_FACE_DOWN, name = cstring("LEFT_FACE_DOWN"), x = 2, y = 1},
	{code = .LEFT_FACE_RIGHT, name = cstring("LEFT_FACE_RIGHT"), x = 3, y = 1},
	{code = .RIGHT_FACE_UP, name = cstring("RIGHT_FACE_UP"), x = 0, y = 0},
	{code = .RIGHT_FACE_LEFT, name = cstring("RIGHT_FACE_LEFT"), x = 1, y = 0},
	{code = .RIGHT_FACE_DOWN, name = cstring("RIGHT_FACE_DOWN"), x = 2, y = 0},
	{code = .RIGHT_FACE_RIGHT, name = cstring("RIGHT_FACE_RIGHT"), x = 3, y = 0},
}

get_button :: proc(button: rl.GamepadButton) -> ^Input {
	for &b in buttons {
		if b.code == button {
			return &b
		}
	}
	return nil
}
main :: proc() {
	rl.InitWindow(1920, 1080, "pad - raylib")
	rl.SetTargetFPS(60)
	icon_texture: rl.Texture2D = rl.LoadTexture("sprites/icons.png")

	inputs := [10]buttonCombination{}
	for !rl.WindowShouldClose() {
		output := cstring("")
		padIsAvailable := rl.IsGamepadAvailable(0)
		if padIsAvailable {
			output = rl.GetGamepadName(0)
			currentlyPressed := [dynamic]rl.GamepadButton{}
			for button in buttons {
				if rl.IsGamepadButtonDown(0, button.code) {
					append(&currentlyPressed, button.code)
				}
			}
			rl.SetWindowTitle(fmt.ctprintf("%v: (%s)", rl.GetFPS(), output))
			if !slice.equal(currentlyPressed[:], inputs[9].buttons[:]) {

				for i := 0; i < 9; i += 1 {
					inputs[i] = inputs[i + 1]
				}
				inputs[9] = buttonCombination {
					buttons = currentlyPressed,
					frames  = 1,
				}
			} else {
				inputs[9].frames += 1
			}

		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.LIGHTGRAY)
		for input, index in inputs {
			col := rl.RAYWHITE
			i := i32(index)

			for b, button_index in input.buttons {
				button := get_button(b)
				if button == nil {
					fmt.printfln("button %#v is nil(%#v)", b, button)
					continue
				}
				rl.DrawTextureRec(
					icon_texture,
					{
						x = f32(button.x * icon_size),
						y = f32(button.y * icon_size),
						width = f32(icon_size),
						height = f32(icon_size),
					},
					{f32(40 + icon_size * button_index), f32(660 - i * 70)},
					rl.RAYWHITE,
				)
			}
			rl.DrawText(fmt.ctprintf("%v: ", input.frames), 20, 660 - i * 70, 10, col)

		}
		rl.EndDrawing()
	}
	rl.CloseWindow()
}
