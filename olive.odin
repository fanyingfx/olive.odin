package olive
import "core:fmt"
import "core:image/png"
import "core:math"
import "core:os"
import "core:strings"
import stbi "vendor:stb/image"

Color :: [4]u8

BACKGROUND_COLOR :: Color{0x20, 0x20, 0x20, 0xff}
FOREGROUND_COLOR :: Color{0xff, 0x20, 0x20, 0xff}
Rectangle :: struct {
	x0:     int,
	y0:     int,
	width:  uint,
	height: uint,
}
Point :: [2]int
Vec :: [2]int
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
swap :: proc(x, y: $T) -> (T, T) {
	return y, x
}

draw_line :: proc(pixels: [][]Color, p1: Point, p2: Point, color: Color) {

	pixels_width := len(pixels[0])
	pixels_height := len(pixels)
	p1, p2 := p1, p2
	if p1.y < p2.y {
		p1, p2 = p2, p1
	}
	v := p2 - p1
	dx := f64(v.x) / f64(abs(v.y))
	for y := p1.y; y >= p2.y; y -= 1 {
		x := int(f64(p1.x) + dx * (f64(p1.y) - f64(y)))
		if 0 < x && x < pixels_width && 0 < y && y < pixels_height {
			pixels[y][x] = color
		}
	}

}
sort_triangle_points_by_y :: proc(p1: Point, p2: Point, p3: Point) -> (Point, Point, Point) {
	p1 := p1
	p2 := p2
	p3 := p3
	if p1.y > p2.y {
		p1, p2 = swap(p1, p2)
	}
	if p2.y > p3.y {
		p2, p3 = swap(p2, p3)
	}
	if p1.y > p2.y {
		p1, p2 = swap(p1, p2)
	}

	return p3,p2,p1

}
fill_triangle :: proc(pixels: [][]Color, p1: Point, p2: Point, p3: Point, color: Color) {
	pixels_width := len(pixels[0])
	pixels_height := len(pixels)
	p1, p2, p3 := sort_triangle_points_by_y(p1, p2, p3)
	v1, v2: Vec

	if p2.x < p3.x {
		v1 = p2 - p1
		v2 = p3 - p1
	} else {
		v1 = p3 - p1
		v2 = p2 - p1
	}
	dx1 := f64(v1.x) / abs(f64(v1.y))
	dx2 := f64(v2.x) / abs(f64(v2.y))

	for y := p1.y; y >= p2.y; y -= 1 {
		x1 := int(f64(p1.x) + dx1 * (f64(p1.y) - f64(y)))
		x2 := int(f64(p1.x) + dx2 * (f64(p1.y) - f64(y)))
		for x := x1; x <= x2; x += 1 {
			if 0 < x && x < pixels_width && 0 < y && y < pixels_height {
				pixels[y][x] = color
			}

		}
	}
	v3,v4 :Vec
	if p1.x < p2.x{
		v3 = p1-p3
		v4 = p2-p3
	}else{
		v3 = p2-p3
		v4 = p1-p3
	}
	dx3 := f64(v3.x) / abs(f64(v3.y))
	dx4 := f64(v4.x) / abs(f64(v4.y))

	for y := p3.y; y < p2.y; y += 1 {
		x3 := int(f64(p3.x) + dx3 * (f64(y) - f64(p3.y)))
		x4 := int(f64(p3.x) + dx4 * (f64(y) - f64(p3.y)))
		for x := x3; x <= x4; x += 1 {
			if 0 < x && x < pixels_width && 0 < y && y < pixels_height {
				pixels[y][x] = color
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
save_to_png :: proc(pixels: [][]Color, file_path: cstring) -> Error {
	width := len(pixels[0])
	height := len(pixels)
	data := make([]u8, width * height * 3 + 1)


	for y := 0; y < height; y += 1 {
		for x := 0; x < width; x += 1 {
			pixel := pixels[y][x]
			index := (y * width + x) * 3
			data[index + 0] = pixel.r
			data[index + 1] = pixel.g
			data[index + 2] = pixel.b
		}
	}
	if stbi.write_png(file_path, i32(width), i32(height), 3, &data[0], i32(width) * 3) != 1 do return .Save_failed
	return .None

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
	draw_line(pixels, {WIDTH / 4 * 3, 0}, {WIDTH, HEIGHT}, {0x20, 0xff, 0x20, 0xff})
	draw_line(pixels, {0, HEIGHT / 2}, {WIDTH, HEIGHT / 2}, {0x20, 0x20, 0xff, 0xff})
	draw_line(pixels, {WIDTH / 2, 0}, {WIDTH / 2, HEIGHT}, {0x20, 0x20, 0xff, 0xff})

	file_path := "line.ppm"
	err := save_to_ppm(pixels, file_path)

	if err != nil {
		fmt.printfln("Error happened")
		fmt.panicf("%s %v", file_path, err)
	}

}

circle_example_png :: proc() {

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
	file_path: cstring = "circle.png"
	err := save_to_png(pixels, file_path)
	if err != nil {
		fmt.printfln("Error happened")
		fmt.panicf("%s %v", file_path, err)
	}
}

triangle_example :: proc() {
	pixels: [][]Color = make([][]Color, HEIGHT, context.temp_allocator)
	defer free_all(context.temp_allocator)
	for i in 0 ..< HEIGHT {
		pixels[i] = make([]Color, WIDTH)
	}
	fill(pixels, BACKGROUND_COLOR)
	fill_triangle(pixels,{0,0},{WIDTH/2,HEIGHT},{WIDTH,HEIGHT/2},FOREGROUND_COLOR)


	file_path := "triangle.ppm"
	err := save_to_ppm(pixels, file_path)

	if err != nil {
		fmt.printfln("Error happened")
		fmt.panicf("%s %v", file_path, err)
	}

}
