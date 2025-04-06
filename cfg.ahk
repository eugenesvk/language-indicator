#Requires AutoHotKey 2.1-alpha.18
export languageIndicator := {
  updatePeriod	: 100,
  version     	: "0.4",
  delay‸      	: 200, ; delay updating caret indicator position until this much ms has passed since the last caret position change
  lang_name   	: ['en-US','ru-RU'],
  ; full list of abbreviations in "Language tag" of "Language ID" table at learn.microsoft.com/en-us/openspecs/windows_protocols/ms-lcid/70feba9f-294e-491e-b6eb-56532684c37f
}
export caret              	:= {
  debug                   	: false,
  debugCaretPosition      	: false,
  files                   	: {
    capslockSuffix        	: "-capslock",
    folderExistCheckPeriod	: 1000, ; optimization?
    folder                	: A_ScriptDir . "\language-indicator\carets\",
    extensions            	: [".png",".gif"]
  }                       	,
  markMargin              	: {x:1, y:-1},
  updatePeriod            	: languageIndicator.updatePeriod,
}

export cursor := {
  debug                   	: false,
  files                   	: {
    capslockSuffix        	: "-capslock",
    folderExistCheckPeriod	: 1000, ; optimization?
    folder                	: A_ScriptDir . "\language-indicator\cursors\",
    extensions            	: [".cur",".ani",".ico"],
  }                       	,
  markMargin              	: { x: 11, y: -11 },
  mousePositionPrediction 	: 0.5, ; reduces lagging in case of embeddded image used as a mark, see GetMousePosPrediction.ahk
  target                  	: {
    cursorId              	: 32513, ; IDC_ARROW := 32512, IDC_IBEAM := 32513, IDC_WAIT := 32514, ...
    cursorName            	: "IBeam", ; must be consistent with ↑
  }                       	,
  updatePeriod            	: languageIndicator.updatePeriod,
}

export tray_icon := {
  debug                   	: false,
  files                   	: {
    folderExistCheckPeriod	: 1000, ; optimization?
    folder                	: A_ScriptDir . "\language-indicator\tray_icon\",
    ; extensions          	: [".ico",".cur",".ani"], ;EXE DLL CPL SCR and other types that contain icon resources
  }                       	,
  updatePeriod            	: languageIndicator.updatePeriod,
}
