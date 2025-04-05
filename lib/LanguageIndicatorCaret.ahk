#Requires AutoHotKey 2.1-alpha.18
; Add extra mark to the text caret (aka blinking cursor) depending on input language and capslock state.
; Script is lookin into "./carets/" folder for files like "1-capslock.png", "2.png", etc.

; #singleinstance force

import "language-indicator/lib/DebugCaretPosition" 	{DebugCaretPosition}
import "language-indicator/lib/GetCapslockState"   	{GetCapslockState}
import "language-indicator/lib/GetInputLocaleIndex"	{GetInputLocaleIndex}
import "language-indicator/lib/GetCaretRect"       	{GetCaretRect}
import "language-indicator/lib/ImagePainter"       	{ImagePainter} ; based on ImagePut.ahk
import "language-indicator/lib/UseBase64Image"     	{*}
import "language-indicator/lib/OnFrameRate"        	as OnFrameRate
import "language-indicator/lib/TickCount"          	{TickCount}
import "language-indicator/lib/Log"                	as L
import "language-indicator/lib/UseCached"          	{UseCached}
import "language-indicator/var"                    	{localesArray, langNamesArray}

if !IsSet(cfg)
	global cfg := {}

cfg.caret := {
	debug: false,
	debugCaretPosition: false,
	files: {
		capslockSuffix: "-capslock",
		folderExistCheckPeriod: 1000, ; optimization?
		folder: A_ScriptDir . "\language-indicator\carets\",
		extensions: [".png", ".gif"]
	},
	markMargin: { x: 1, y: -1 },
	updatePeriod: 100,
}

if IsSet(languageIndicator)
	cfg.caret.updatePeriod := languageIndicator.updatePeriod

if !IsSet(state)
	global state := { prev: {} }
InitCaretState()

global caretMark := ImagePainter()
caretMark.margin := cfg.caret.markMargin

RunCaret()
RunCaret() {
	SetTimer(CheckCaret, cfg.caret.updatePeriod)
	OnExit(CaretExitFunc)
}

; Checks if caret reflect current input locale or capslock state
CheckCaret() {
	global state
	UpdateCaretState()
	CaretsFolderExist()
		? UseCaretMarkFile() ; use caret mark from file system
		: UseCaretMarkEmbedded() ; use embedded base64 image
}

onFrame := OnFrameRate.OnFrameRateScheduler.Increase() ; must be decreased if `onFrame.ScheduleRun` not used in code below
UseCaretMarkEmbedded() {
	global state
	state.caretMarkName := GetCaretMarkName(state.locale, state.capslock)
	if (state.caretMarkName == "") {
		caretMark.RemoveWindow()
		return
	}
	mark := UseBase64Image(state.caretMarkName) ; { name: <str>, image: <0 | path | base64> }
	PaintCaretMark(mark) ; repaint mark every ~cfg.updatePeriod...
	onFrame.ScheduleRun(() => PaintCaretMark(mark), "caret", cfg.caret.updatePeriod) ;...repaint mark on frames between
}
UseCaretMarkFile() {
	global state
	state.caretMarkName := GetCaretMarkName(state.locale, state.capslock)
	if (state.caretMarkName == "") {
		caretMark.RemoveWindow()
		return
	}
	mark := { name: state.caretMarkName, image: GetCaretMarkFile() } ; { name: <str>, image: <path | base64> }
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
	global cfg, state
	for ext in cfg.caret.files.extensions {
		if state.capslock {
			path := cfg.caret.files.folder . state.locale . cfg.caret.files.capslockSuffix . ext ; e.g. "carets\1-capslock.png"
			if (FileExist(path))
				return path ; capslock-suffixed file to be used
		}
		; fallback if no capslock file found
		path := cfg.caret.files.folder . state.locale . ext ; e.g. "\carets\1.png"
		if (FileExist(path))
			return path
	}
	return ""
}

; markObj := { name: ..., image: ...}
PaintCaretMark(markObj) {
	global cfg, caretMark, state

	if (!markObj.image or 2 > StrLen(markObj.image)) { ; no image
		caretMark.RemoveWindow()
		caretMark.Clear()
		return
	}

	; not used, only for debugging
	state.caretMarkImage := SubStr(markObj.image, 1, 20) . "..."

	top := -1, left := -1, bottom := -1, right := -1
	w := 0, h := 0
	GetCaretRect(&left, &top, &right, &bottom, &detectMethod)
	w := right - left
	h := bottom - top

	if cfg.caret.debugCaretPosition
		DebugCaretPosition(&left, &top, &right, &bottom, &detectMethod)

	if (InStr(detectMethod, "failure") or (w < 1 and h < 1)) {
		caretMark.HideWindow()
		return
	}

	caretMark.StorePrev()
	caretMark.img.name := markObj.name
	caretMark.img.image := markObj.image
	caretMark.img.x := left
	caretMark.img.y := top

	caretMark.Paint()
}

InitCaretState() {
	global state
	if !state.HasOwnProp("prev")
		state.prev := {}
	if !state.HasOwnProp("locale")
		state.locale := 1
	if !state.HasOwnProp("capslock")
		state.capslock := 0
	if !state.HasOwnProp("caretMarkName")
		state.caretMarkName := ""
	if !state.HasOwnProp("caretMarkImage")
		state.caretMarkImage := ""
}

UpdateCaretState() {
	static last_changed_locale := 0, counter := 0
	counter += 1
	global state
	lang_id := 0x0000
	state.prev.locale := state.locale
	state.locale := GetInputLocaleIndex(&lang_id)
	if   (state.locale != state.prev.locale)
		|| (state.locale != last_changed_locale){
		; Tooltip(counter " state.locale=" state.locale Format("`n{1:#04x}`tlang_id",lang_id) "`n" Format("{1:#04x}`tlocalesArray1",localesArray[1]) " " langNamesArray[1] "`n" localesArray.Length " =? " langNamesArray.length,x:=0,y:=50,id:=17)
		last_changed_locale := state.locale
		set_lang := False
		for i, l_id in localesArray {
			if (lang_id == l_id) {
				set_lang := True
				try {
				; Tooltip(" i=" i " name = ‹" langNamesArray[i] "›",x:=0,y:=0,id:=18)
					TraySetIcon("language-indicator\img\lang\" langNamesArray[i] ".ico",,)
				} catch Error as err {
					TraySetIcon("*",,)
				}
			}
		}
		if !set_lang { ; todo: this is a frequent operation, does it cost much? is it really needed?
			; TraySetIcon("*",,)
		}

		state.prev.capslock := state.capslock
		state.capslock := GetCapslockState()

		if CaretsFolderExist() {
			state.prev.caretMarkImage := state.caretMarkImage
			state.caretMarkImage := GetCaretMarkFile()

			state.prev.caretMarkName := state.caretMarkName
			state.caretMarkName := ""
		} else {
			state.prev.caretMarkName := state.caretMarkName
			state.caretMarkName := GetCaretMarkName(state.locale, state.capslock)

			state.prev.caretMarkImage := state.caretMarkImage
			state.caretMarkImage := ""
		}
	}
}

CaretsFolderExist := UseCached(CheckCaretsFolderExist, cfg.caret.files.folderExistCheckPeriod)
CheckCaretsFolderExist() {
	return DirExist(cfg.caret.files.folder)
}

CaretExitFunc(ExitReason, ExitCode) {
	if !(ExitReason ~= "^(?i:Logoff|Shutdown)$")
		caretMark.RemoveWindow()
}

if cfg.caret.debug
	L.Log(cfg)