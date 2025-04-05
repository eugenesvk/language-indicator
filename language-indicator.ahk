#Requires AutoHotKey 2.1-alpha.18
; ProcessSetPriority("Realtime")

import "language-indicator\cfg"  	as cfg
import "language-indicator\state"	{state as _st}
import "language-indicator\var"  	{localesArray, langNamesArray}

import "language-indicator\lib\GetInputLocaleIndex"	{GetInputLocaleIndex}

import "language-indicator\lib\LanguageIndicatorCaret" 	as LI_Caret
import "language-indicator\lib\LanguageIndicatorCursor"	as LI_Cursor

SetTimers()
SetTimers() {
  SetTimer(CheckLangChange, cfg.languageIndicator.updatePeriod)
  OnExit(LI_Caret.CaretExitFunc)
  OnExit(LI_Cursor.CursorExitFunc)
}

CheckLangChange() {
  static last_changed_locale := 0
  lang_id := 0x0000
  _st.prev.locale	:= _st.locale
  _st.locale     	:= GetInputLocaleIndex(&lang_id)
  if   (_st.locale != _st.prev.locale)
    || (_st.locale != last_changed_locale) {
    last_changed_locale := _st.locale
    set_lang := False
    for i, l_id in localesArray {
      if (lang_id == l_id) {
        set_lang := True
        try {
          TraySetIcon("language-indicator\img\lang\" langNamesArray[i] ".ico",,)
        } catch Error as err {
          TraySetIcon("*",,)
        }
        break
      }
    }
    if !set_lang { ; todo: this is a frequent operation, does it cost much? is it really needed?
      ; TraySetIcon("*",,)
    }
    LI_Caret.CheckCaret()
    LI_Cursor.CheckCursor()
  }
}
