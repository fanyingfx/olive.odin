package olive
// import "core:slice"
// import "core:bytes"
import "core:fmt"

WIDTH :: 800
HEIGHT :: 600
COLS :: 8*2
ROWS :: 6*2
CELL_WIDTH :: WIDTH / COLS
CELL_HEIGHT :: HEIGHT / ROWS

main :: proc() {
	checker_example()
	circle_example()
	line_example()
}
