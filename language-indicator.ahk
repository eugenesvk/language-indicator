#Requires AutoHotKey 2.1-alpha.18
#singleinstance force

; ProcessSetPriority("Realtime")

import "language-indicator\lib\LanguageIndicatorCaret"
import "language-indicator\lib\LanguageIndicatorCursor"
import "language-indicator\cfg" as cfg

; A_IconTip := "Language Indicator v" . cfg.languageIndicator.version
