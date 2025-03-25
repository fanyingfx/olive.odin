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
	triangle_example()
	// checker_example()
	// circle_example()
	// line_example()
	// circle_example_png()
// p1,p2,p3 := sort_triangle_points_by_y({0,1},{2,3},{3,888})
// fmt.println(p1,p2,p3)
}
