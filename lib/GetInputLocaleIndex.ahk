#requires AutoHotkey v2.0
#include GetInputLocaleId.ahk
#include HasValue.ahk

global localesArray := [GetInputLocaleId()] ; start with one value of initial input locale ID

; populates localesArray
GetInputLocaleIndex(&locale_num:=0) {
	global localesArray
	localeId := GetInputLocaleId() ; docs.microsoft.com/en-us/windows/win32/intl/language-identifiers
	locale_num := localeId

	if !localeId {
		return 0
	}

	index := HasValue(localesArray, localeId)

	; push localeId into localesArray
	if !index {
		localesArray.Push(localeId)
		index := localesArray.length
	}

	return index
}