#Requires AutoHotKey 2.1-alpha.18
; ProcessSetPriority("Realtime")

import "language-indicator\cfg"  	as cfg
import "language-indicator\state"	{state as _st}
import "language-indicator\var"  	{localesArray, langNamesArray}

import "language-indicator\lib\GetInputLocaleIndex"	{GetInputLocaleIndex}
import "language-indicator\lib\GetCaretRect"       	{GetCaretRect}
import "language-indicator\lib\DebugCaretPosition" 	{DebugCaretPosition}

import "language-indicator\lib\LanguageIndicatorCaret" 	as LI_Caret
import "language-indicator\lib\LanguageIndicatorCursor"	as LI_Cursor
import "language-indicator\lib\LanguageIndicatorTray"  	as LI_Tray

initState()
initState() {
  if !_st.HasOwnProp("locale") {
    _st.locale := -1 ; invalid index to trigger initial update
  }
  if !_st.HasOwnProp("lang_id") {
    _st.lang_id := 0x0000
  }
  if !_st.HasOwnProp("capslock") {
    _st.capslock := 0
  }
  if !_st.HasOwnProp("prev") {
    _st.prev := {locale:_st.locale, lang_id:_st.lang_id, capslock:_st.capslock}
  }
  if !_st.prev.HasOwnProp("locale") {
    _st.prev.locale := _st.locale
  }
  if !_st.prev.HasOwnProp("lang_id") {
    _st.prev.lang_id := _st.lang_id
  }
  if !_st.prev.HasOwnProp("capslock") {
    _st.prev.capslock := _st.capslock
  }
  LI_Caret.InitCaretState()
  LI_Cursor.InitCursorState()
  CheckLangCapsChange()
}

SetTimers()
SetTimers() {
  SetTimer(CheckLangCapsChange, cfg.languageIndicator.updatePeriod)
  OnExit(LI_Caret.CaretExitFunc)
  OnExit(LI_Cursor.CursorExitFunc)
  OnExit(LI_Tray.TrayExitFunc)
}

CheckLangCapsChange() {
  _st.locale       	:= GetInputLocaleIndex(&_st.lang_id)
  _st.capslock     	:= GetKeyState("Capslock", "T")
  is_locale_changed	:= (_st.locale   != _st.prev.locale  )
  is_caps_changed  	:= (_st.capslock != _st.prev.capslock)
  is_caret_checked := 0, is_cursor_checked := 0, is_caret_pos_changed := 0

  GetCaretRect(&_st.‸.←, &_st.‸.↑, &_st.‸.→, &_st.‸.↓, &detectMethod)
  if cfg.caret.debugCaretPosition {
    DebugCaretPosition(&_st.‸.←, &_st.‸.↑, &_st.‸.→, &_st.‸.↓, &detectMethod)
  }
  _st.‸.detectMethod := detectMethod
  is_caret_pos_changed	:= (_st.‸.← != _st.prev.‸.←)
    ||                	   (_st.‸.↑ != _st.prev.‸.↑)
    ||                	   (_st.‸.→ != _st.prev.‸.→)
    ||                	   (_st.‸.↓ != _st.prev.‸.↓)
  if is_locale_changed {
    _st.prev.locale	:= _st.locale
    LI_Tray.CheckTray()
    LI_Caret.CheckCaret(), is_caret_checked := 1
    LI_Cursor.CheckCursor(), is_cursor_checked := 1
  }
  if is_caps_changed {
    _st.prev.capslock	:= _st.capslock
    if !is_caret_checked {
      LI_Caret.CheckCaret(), is_caret_checked := 1
    }
    if !is_cursor_checked {
      LI_Cursor.CheckCursor(), is_cursor_checked := 1
    }
  }
  if is_caret_pos_changed {
    _st.prev.‸.←	:= _st.‸.←
    _st.prev.‸.↑	:= _st.‸.↑
    _st.prev.‸.→	:= _st.‸.→
    _st.prev.‸.↓	:= _st.‸.↓
    _st.prev.‸.t	:= A_TickCount
    }
  }
}
