#Requires AutoHotKey 2.1-alpha.18
Import "language-indicator/lib/Log" as L

export GetMousePos() {
	CoordMode "Mouse", "Screen"
	MouseGetPos(&mx, &my)

	return {
		x: mx,
		y: my
	}
}