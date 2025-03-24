package olive
import "core:fmt"
import "core:math"
import "core:os"
import "core:strings"

Color :: [4]u8

BACKGROUND_COLOR :: Color{0x20, 0x20, 0x20, 0xff}
FOREGROUND_COLOR :: Color{0xff, 0x20, 0x20, 0xff}
Rectangle :: struct {
	x0:     int,
	y0:     int,
	width:  uint,
	height: uint,
}
// Line :: struct{
// 	x1:int,
// 	y1:int,
// 	x2:int,
// 	y2:int,
// }
Point :: [2]int
Circle :: struct {
	cx:     int,
	cy:     int,
	radius: uint,
}

Error :: enum {
	None,
	Save_failed,
}
fill :: proc(pixels: [][]Color, color: Color) {
	for &row in pixels {
		for &col in row {
			col = color
		}

	}
}
fill_rect :: proc(pixels: [][]Color, rect: Rectangle, color: Color) {
	pixels_width := len(pixels[0])
	pixels_height := len(pixels)
	for dy := 0; dy < int(rect.height); dy += 1 {
		y := rect.y0 + dy
		if y < 0 || y > pixels_height do continue
		for dx := 0; dx < int(rect.width); dx += 1 {
			x := rect.x0 + dx
			if 0 <= x && x <= pixels_width {
				pixels[y][x] = color
			}

		}
	}
}
fille_circle :: proc(pixels: [][]Color, circle: Circle, color: Color) {
	pixels_width := len(pixels[0])
	pixels_height := len(pixels)

	x1 := circle.cx - int(circle.radius)
	y1 := circle.cy - int(circle.radius)
	x2 := circle.cx + int(circle.radius)
	y2 := circle.cy + int(circle.radius)

	for y := y1; y <= y2; y += 1 {
		if y < 0 || y > pixels_height do continue
		for x := x1; x <= x2; x += 1 {
			if x < 0 || x > pixels_width do continue
			dx := x - circle.cx
			dy := y - circle.cy
			if uint(dx * dx) + uint(dy * dy) < circle.radius * circle.radius {
				pixels[y][x] = color
			}
		}
	}

}
swap :: proc(x, y: int) -> (int, int) {
	return y, x
}

draw_line :: proc(pixels: [][]Color, p1: Point, p2: Point, color: Color) {

	pixels_width := len(pixels[0])
	pixels_height := len(pixels)

	dx := p2.x - p1.x
	dy := p2.y - p1.y

	if dx != 0 {
		k := f64(dy) / f64(dx)
		c := f64(p1.y) - k * f64(p1.x)
		x1 := p1.x
		x2 := p2.x
		if x1 > x2 {
			x1, x2 = swap(x1, x2)
		}
		for x := x1; x <= x2; x += 1 {
			if x < 0 || x >= pixels_width do continue
			y := int(k * f64(x) + c)
			sy1 := int(f64(dy) * f64(x) / f64(dx) + c)
			sy2 := int(f64(dy) * f64(x + 1) / f64(dx) + c)
			if sy1 > sy2 do sy1, sy2 = swap(sy1, sy2)
			for y := sy1; y <= sy2; y += 1 {
				if 0 <= y && y < pixels_height {
					pixels[y][x] = color
				}
			}
		}

	} else {
		if 0 <= p1.x && p1.x <= pixels_width {
			y1 := p1.y
			y2 := p2.y
			if y1 > y2 {
				y1, y2 = swap(y1, y2)
			}
			for y := y1; y <= y2; y += 1 {
				if 0 <= y && y < pixels_height {
					pixels[y][p1.x] = color
				}

			}

		}

	}

}
save_to_ppm :: proc(pixels: [][]Color, file_path: string) -> Error {
	sb, err := strings.builder_make_none(context.temp_allocator)
	if err != nil do return .Save_failed
	defer free_all(context.temp_allocator)
	fmt.sbprintf(&sb, "P6\n%d %d 255\n", len(pixels[0]), len(pixels))
	for row in pixels {
		for pixel in row {
			pixel_rgb := pixel.rgb
			append(&sb.buf, ..pixel_rgb[:])
		}
	}

	if !os.write_entire_file(file_path, sb.buf[:]) do return .Save_failed
	return nil
}

checker_example :: proc() {

	pixels: [][]Color = make([][]Color, HEIGHT, context.temp_allocator)
	defer free_all(context.temp_allocator)
	for i in 0 ..< HEIGHT {
		pixels[i] = make([]Color, WIDTH)
	}

	fill(pixels, BACKGROUND_COLOR)
	for y := 0; y < ROWS; y += 1 {
		for x := 0; x < COLS; x += 1 {
			color: Color
			if (x + y) % 2 == 0 {
				color = {0xff, 0, 0, 0xff}
			} else {
				color = {0, 0xff, 0, 0xff}
			}
			fill_rect(pixels, {x * CELL_WIDTH, y * CELL_HEIGHT, CELL_WIDTH, CELL_HEIGHT}, color)
		}
	}
	file_path := "checker.ppm"
	err := save_to_ppm(pixels, file_path)

	if err != nil {
		fmt.printfln("Error happened")
		fmt.panicf("%s %v", file_path, err)
	}
}

circle_example :: proc() {

	pixels: [][]Color = make([][]Color, HEIGHT, context.temp_allocator)
	defer free_all(context.temp_allocator)
	for i in 0 ..< HEIGHT {
		pixels[i] = make([]Color, WIDTH)
	}

	fill(pixels, BACKGROUND_COLOR)

	for y := 0; y < ROWS; y += 1 {
		for x := 0; x < COLS; x += 1 {
			u := f64(x) / COLS
			v := f64(y) / ROWS
			t := (u + v) / 2
			radius: f64 = CELL_WIDTH
			if (radius > CELL_HEIGHT) do radius = CELL_HEIGHT

			fille_circle(
				pixels,
				{
					x * CELL_WIDTH + CELL_WIDTH / 2,
					y * CELL_HEIGHT + CELL_HEIGHT / 2,
					uint(math.lerp(radius / 8, radius / 2, t)),
				},
				FOREGROUND_COLOR,
			)
		}
	}
	file_path := "circle.ppm"
	err := save_to_ppm(pixels, file_path)

	if err != nil {
		fmt.printfln("Error happened")
		fmt.panicf("%s %v", file_path, err)
	}
}
line_example :: proc() {
	pixels: [][]Color = make([][]Color, HEIGHT, context.temp_allocator)
	defer free_all(context.temp_allocator)
	for i in 0 ..< HEIGHT {
		pixels[i] = make([]Color, WIDTH)
	}
	fill(pixels, BACKGROUND_COLOR)

	draw_line(pixels, {0, 0}, {WIDTH, HEIGHT}, FOREGROUND_COLOR)
	draw_line(pixels, {WIDTH, 0}, {0, HEIGHT}, FOREGROUND_COLOR)
	draw_line(pixels, {0, 0}, {WIDTH / 4, HEIGHT}, {0x20, 0xff, 0x20, 0xff})
	draw_line(pixels, {WIDTH / 4, 0}, {0, HEIGHT}, {0x20, 0xff, 0x20, 0xff})
	draw_line(pixels, {WIDTH, 0}, {WIDTH / 4 * 3, HEIGHT}, {0x20, 0xff, 0x20, 0xff})
	draw_line(pixels, {WIDTH/4*3, 0}, {WIDTH , HEIGHT}, {0x20, 0xff, 0x20, 0xff})
	draw_line(pixels, {0, HEIGHT/2}, {WIDTH , HEIGHT/2}, {0x20, 0x20, 0xff, 0xff})
	draw_line(pixels, {WIDTH/2, 0}, {WIDTH/2 , HEIGHT}, {0x20, 0x20, 0xff, 0xff})

	file_path := "line.ppm"
	err := save_to_ppm(pixels, file_path)

	if err != nil {
		fmt.printfln("Error happened")
		fmt.panicf("%s %v", file_path, err)
	}

}
