#Requires AutoHotKey 2.1-alpha.18

; A_TickCount precision is 10ms, so QPC...
export TickCount() {
	DllCall("QueryPerformanceFrequency", "Int64*", &freq := 0)
	DllCall("QueryPerformanceCounter", "Int64*", &counter := 0)
	return Floor(counter / (freq / 1000)) ; milliseconds (ms)
}