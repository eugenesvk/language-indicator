#Requires AutoHotKey 2.1-alpha.18
; Change Tray icon to reflect depending on input language
; Script is looking into "./tray_icon/" folder for files like "en-US.ico"

import "language-indicator\cfg"  	as cfg
import "language-indicator\state"	{state as _st}
import "language-indicator\var"  	{localesArray, langNamesArray}

import "language-indicator\lib\Log"	as L

; Checks if tray icon reflects current input locale. AHK handles file caching
export CheckTray() {
  UpdateTrayState()
}

UpdateTrayState() {
  set_lang := False
  for i, l_id in localesArray {
    if (_st.lang_id == l_id) {
      set_lang := True
      try {
        TraySetIcon(cfg.tray_icon.files.folder langNamesArray[i] ".ico",,)
      } catch Error as err {
        TraySetIcon("*",,)
      }
      break
    }
  }
  if !set_lang { ; todo: this is a frequent operation, does it cost much? is ireally needed?
    ; TraySetIcon("*",,)
  }
}

export TrayExitFunc(ExitReason, ExitCode) {
}

if cfg.tray_icon.debug {
  L.Log(cfg.tray_icon)
}
