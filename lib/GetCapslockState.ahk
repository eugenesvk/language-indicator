#Requires AutoHotKey 2.1-alpha.18

GetCapslockState() {
	return GetKeyState("Capslock", "T")
}