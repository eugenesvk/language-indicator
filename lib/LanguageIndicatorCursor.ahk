#Requires AutoHotKey 2.1-alpha.18
; Set custom text select pointer or paint a mark nearby, depending on input language and capslock state.

; Script work in this way:
; 1. lookin into "./cursors/" folder for files "1.cur", "1-capslock.cur", "2.cur", etc.
; 2. in case there's no "./cursors/" folder exist, embedded images to be used to set mark near mouse cursor/pointer

import "language-indicator\cfg"  	as cfg
import "language-indicator\state"	{state as _st}

import "language-indicator\lib\GetInputLocaleIndex"  	{GetInputLocaleIndex} ; https://www.autohotkey.com/boards/viewtopic.php?t=84140
import "language-indicator\lib\GetMousePosPrediction"	as GetMousePosPrediction
import "language-indicator\lib\ImagePainter"         	{ImagePainter} ; based on ImagePut.ahk
import "language-indicator\lib\OnFrameRate"          	as OnFrameRate
import "language-indicator\lib\UseBase64Image"       	{*}
import "language-indicator\lib\UseCached"            	{UseCached}
Import "language-indicator\lib\Log"                  	as L

InitCursorState()

global cursorMark := ImagePainter()
cursorMark.margin := cfg.cursor.markMargin

; cursor to reflect locale and capslock state
export CheckCursor() {
	global cursorMark
	if (A_Cursor != cfg.cursor.target.cursorName) {
		RevertCursors()
		cursorMark.HideWindow()
		return
	}
	UpdateCursorState()
	CursorsFolderExist()
		? UseCursorFile() ; use cursor from file system
		: UseCursorMarkEmbedded() ; use embedded base64 image to paint a mark near the cursor
}

UseCursorMarkEmbedded() {
	if (_st.cursorMarkName == "") {
		cursorMark.RemoveWindow()
		return
	}
	mark := UseBase64Image(_st.cursorMarkName) ; { name: <str>, image: <0 | path | base64> }
	PaintCursorMark(mark) ; repaint mark every ~cfg.updatePeriod...
	onFrame.ScheduleRun(() => PaintCursorMark(mark), "cursor", cfg.cursor.updatePeriod) ; ...repaint mark on a few next frames
}
onFrame := OnFrameRate.OnFrameRateScheduler.Increase() ; must be removed if not used in the line above

UseCursorFile() {
	if (_st.cursorFile == "") {
		RevertCursors()
		return
	}
	SetCursorFromFile(_st.cursorFile)
}

; (no capslock + initial language) → 0
; (capslock + initial language) → "arrow_white_9px"
; (no capslock + second language) → "circle_red_9px"
GetCursorMarkName(locale := 1, capslock := 0) {
	if (locale == 1 and capslock == 0)
		return "" ; use default cursor

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

GetCursorFile() {
	for ext in cfg.cursor.files.extensions {
		if _st.capslock {
			path := cfg.cursor.files.folder . _st.locale . cfg.cursor.files.capslockSuffix . ext ; e.g. "cursors\1-capslock.cur"
			if (FileExist(path))
				return path ; capslock-suffixed file to be used
		}
		; fallback if no capslock file found
		path := cfg.cursor.files.folder . _st.locale . ext ; e.g. "\cursors\1.cur"
		if (FileExist(path))
			return path
	}
	return ""
}

global modifiedCursorsCount := 0
; https://autohotkey.com/board/topic/32608-changing-the-system-cursor/
SetCursorFromFile(filePath := "") {
	global modifiedCursorsCount
	if (!filePath or filePath == "") {
		; L.Log("LanguageIndicatorCursor.ahk: cursor's filePath is not set")
		return
	} else if FileExist(filePath) {
		SplitPath(filePath, , , &ext)
		if !(ext ~= "^(?i:cur|ani|ico)$") {
			; L.Log("LanguageIndicatorCursor.ahk: invalid file extension, only (ani|cur|ico) allowed")
			return
		}
	} else {
		; L.Log("LanguageIndicatorCursor.ahk: (" . filePath . ") was not found on disk")
		return
	}
	cursorHandle := DllCall("LoadCursorFromFile", "Str", filePath)
	DllCall("SetSystemCursor", "Uint", cursorHandle, "Int", cfg.cursor.target.cursorId) ; set cursor
	modifiedCursorsCount += 1
}

RevertCursors() {
	global modifiedCursorsCount
	if modifiedCursorsCount == 0
		return

	SPI_SETCURSORS := 0x57
	DllCall("SystemParametersInfo", "UInt", SPI_SETCURSORS, "UInt", 0, "UInt", 0, "UInt", 0) ; reset cursors
	modifiedCursorsCount := 0
}

; markObj := { name: ..., image: ...}
PaintCursorMark(markObj, cursor := "IBeam") {
	global cursorMark

	if (cursor != 0 and cursor != A_Cursor) { ; cursor not matched
		cursorMark.HideWindow()
		cursorMark.Clear()
		return
	}

	if (!markObj.image or 10 > StrLen(markObj.image)) { ; no image
		cursorMark.RemoveWindow()
		cursorMark.Clear()
		return
	}

	pos := GetMousePosPrediction.GetMousePos(cfg.cursor.mousePositionPrediction) ; use prediction

	if (pos.x == -1 or pos.x == -1) { ; wrong cursor position
		cursorMark.HideWindow()
		cursorMark.Clear()
		return
	}

	cursorMark.StorePrev()
	cursorMark.img.name := markObj.name
	cursorMark.img.image := markObj.image
	cursorMark.img.x := pos.x
	cursorMark.img.y := pos.y

	cursorMark.Paint()
}

InitCursorState() {
	if !_st.HasOwnProp("cursorFile")
		_st.cursorFile := ""
	if !_st.HasOwnProp("cursorMarkName")
		_st.cursorMarkName := ""
}

UpdateCursorState() {
	if CursorsFolderExist() {
		_st.prev.cursorFile := _st.cursorFile
		_st.cursorFile := GetCursorFile()

		_st.prev.cursorMarkName := _st.cursorMarkName
		_st.cursorMarkName := ""
	} else {
		_st.prev.cursorMarkName := _st.cursorMarkName
		_st.cursorMarkName := GetCursorMarkName(_st.locale, _st.capslock)

		_st.prev.cursorFile := _st.cursorFile
		_st.cursorFile := ""
	}
}

CursorsFolderExist := UseCached(CheckCursorsFolderExist, cfg.cursor.files.folderExistCheckPeriod)
CheckCursorsFolderExist() {
	exist := DirExist(cfg.cursor.files.folder)

	if exist
		OnFrameRate.OnFrameRateScheduler.Decrease() ; prevent flickering

	return exist
}

export CursorExitFunc(ExitReason, ExitCode) {
	if !(ExitReason ~= "^(?i:Logoff|Shutdown)$") {
		RevertCursors()
		cursorMark.RemoveWindow()
	}
}

if cfg.cursor.debug
	L.Log(cfg)