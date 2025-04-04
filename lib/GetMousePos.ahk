#Requires AutoHotKey 2.1-alpha.18
#include Log.ahk

GetMousePos() {
	CoordMode "Mouse", "Screen"
	MouseGetPos(&mx, &my)

	return {
		x: mx,
		y: my
	}
}