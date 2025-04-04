#Requires AutoHotKey 2.1-alpha.18

export HasValue(haystack, val) {
	for index, value in haystack
		if (value = val)
			return index
	if !IsObject(haystack)
		; throw Exception("Bad haystack!", -1, haystack) ; ahk v1
		throw ValueError("haystack id not an object", -1, haystack) ; ahk v2
	return 0
}