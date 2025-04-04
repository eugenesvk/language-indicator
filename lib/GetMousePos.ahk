#Requires AutoHotKey 2.1-alpha.18
Include Log {Log}

GetMousePos() {
	CoordMode "Mouse", "Screen"
	MouseGetPos(&mx, &my)

	return {
		x: mx,
		y: my
	}
}