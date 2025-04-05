#Requires AutoHotKey 2.1-alpha.18
; Add extra mark to the text caret (aka blinking cursor) depending on input language and capslock state.
; Script is lookin into "./carets/" folder for files like "1-capslock.png", "2.png", etc.

import "language-indicator\cfg"  	as cfg
import "language-indicator\state"	{state as _st}
import "language-indicator\var"  	{localesArray, langNamesArray}

import "language-indicator\lib\GetInputLocaleIndex"	{GetInputLocaleIndex}
import "language-indicator\lib\GetCaretRect"       	{GetCaretRect}
import "language-indicator\lib\ImagePainter"       	{ImagePainter} ; based on ImagePut.ahk
import "language-indicator\lib\UseBase64Image"     	{*}
import "language-indicator\lib\OnFrameRate"        	as OnFrameRate
import "language-indicator\lib\TickCount"          	{TickCount}
import "language-indicator\lib\Log"                	as L
import "language-indicator\lib\UseCached"          	{UseCached}

global caretMark := ImagePainter()
caretMark.margin := cfg.caret.markMargin

; Checks if caret reflect current input locale or capslock state
export CheckCaret() {
	UpdateCaretState()
	CaretsFolderExist()
		? UseCaretMarkFile() ; use caret mark from file system
		: UseCaretMarkEmbedded() ; use embedded base64 image
}

onFrame := OnFrameRate.OnFrameRateScheduler.Increase() ; must be decreased if `onFrame.ScheduleRun` not used in code below
UseCaretMarkEmbedded() {
	_st.caretMarkName := GetCaretMarkName(_st.locale, _st.capslock)
	if (_st.caretMarkName == "") {
		caretMark.RemoveWindow()
		return
	}
	mark := UseBase64Image(_st.caretMarkName) ; { name: <str>, image: <0 | path | base64> }
	PaintCaretMark(mark) ; repaint mark every ~cfg.updatePeriod...
	onFrame.ScheduleRun(() => PaintCaretMark(mark), "caret", cfg.caret.updatePeriod) ;...repaint mark on frames between
}
UseCaretMarkFile() {
	_st.caretMarkName := GetCaretMarkName(_st.locale, _st.capslock)
	if (_st.caretMarkName == "") {
		caretMark.RemoveWindow()
		return
	}
	mark := { name: _st.caretMarkName, image: GetCaretMarkFile() } ; { name: <str>, image: <path | base64> }
	PaintCaretMark(mark) ; repaint mark every ~cfg.updatePeriod...
	onFrame.ScheduleRun(() => PaintCaretMark(mark), "caret", cfg.caret.updatePeriod) ;...repaint mark on frames between
}

; (no capslock + initial language) → 0
; (capslock + initial language) → "arrow_white_9px"
; (no capslock + second language) → "circle_red_9px"
GetCaretMarkName(locale, capslock) {
	if (locale == 1 and capslock == 0)
		return "" ; no mark

	; see UseBase64Image.ahk
	figures := Map("0", "circle", "1", "arrow")
	colors := Map("1", "white", "2", "red", "3", "green", 4, "blue")
	sizes := ["9px", "12px"]

	figure := figures.Get("" . capslock, "undefined")
	color := colors.Get("" . locale, "undefined")
	size := sizes[2]

	imageName := figure "_" color "_" size
	return imageName
}

GetCaretMarkFile() {
	for ext in cfg.caret.files.extensions {
		if _st.capslock {
			path := cfg.caret.files.folder . _st.locale . cfg.caret.files.capslockSuffix . ext ; e.g. "carets\1-capslock.png"
			if (FileExist(path))
				return path ; capslock-suffixed file to be used
		}
		; fallback if no capslock file found
		path := cfg.caret.files.folder . _st.locale . ext ; e.g. "\carets\1.png"
		if (FileExist(path))
			return path
	}
	return ""
}

; markObj := { name: ..., image: ...}
PaintCaretMark(markObj) {
	global caretMark

	if (!markObj.image or 2 > StrLen(markObj.image)) { ; no image
		caretMark.RemoveWindow()
		caretMark.Clear()
		return
	}

	; not used, only for debugging
	_st.caretMarkImage := SubStr(markObj.image, 1, 20) . "..."

	w := _st.‸.→ - _st.‸.←
	h := _st.‸.↓ - _st.‸.↑

	if (InStr(_st.‸.detectMethod, "failure") or (w < 1 and h < 1)) {
		caretMark.HideWindow()
		return
	}

	caretMark.StorePrev()
	caretMark.img.name := markObj.name
	caretMark.img.image := markObj.image
	caretMark.img.x := _st.‸.←
	caretMark.img.y := _st.‸.↑

	caretMark.Paint()
}

export InitCaretState() {
	if !_st.HasOwnProp("caretMarkName")
		_st.caretMarkName := ""
	if !_st.HasOwnProp("caretMarkImage")
		_st.caretMarkImage := ""
	if !_st.HasOwnProp("‸")
		_st.‸ := {↑:-1, ←:-1, ↓:-1, →:-1, detectMethod: "", t: A_TickCount, t_moved: 0}
	if !_st.HasOwnProp("prev")
		_st.prev := {‸:{↑:-1, ←:-1, ↓:-1, →:-1, detectMethod: "", t: A_TickCount, t_moved: 0}}
	if !_st.prev.HasOwnProp("‸")
		_st.prev.‸ := {↑:-1, ←:-1, ↓:-1, →:-1, detectMethod: "", t: A_TickCount, t_moved: 0}
}

UpdateCaretState() {
	if CaretsFolderExist() {
		_st.prev.caretMarkImage := _st.caretMarkImage
		_st.caretMarkImage := GetCaretMarkFile()

		_st.prev.caretMarkName := _st.caretMarkName
		_st.caretMarkName := ""
	} else {
		_st.prev.caretMarkName := _st.caretMarkName
		_st.caretMarkName := GetCaretMarkName(_st.locale, _st.capslock)

		_st.prev.caretMarkImage := _st.caretMarkImage
		_st.caretMarkImage := ""
	}
}

CaretsFolderExist := UseCached(CheckCaretsFolderExist, cfg.caret.files.folderExistCheckPeriod)
CheckCaretsFolderExist() {
	return DirExist(cfg.caret.files.folder)
}

export CaretExitFunc(ExitReason, ExitCode) {
	if !(ExitReason ~= "^(?i:Logoff|Shutdown)$")
		caretMark.RemoveWindow()
}

if cfg.caret.debug
	L.Log(cfg.caret)