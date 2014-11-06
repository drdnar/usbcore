; This program is free software. It comes without any warranty, to
; the extent permitted by applicable law. You can redistribute it
; and/or modify it under the terms of the Do What The Fuck You Want
; To Public License, Version 2, as published by Sam Hocevar. See
; http://sam.zoy.org/wtfpl/COPYING for more details.

;====== Table for Hex Input ====================================================
hexKeyTable:
hexKeyTableSize	.equ	16
	.db	skCos
	.db	skSin
	.db	skRecip
	.db	skPrgm
	.db	skMatrix
	.db	skMath
	.db	sk9
	.db	sk8
	.db	sk7
	.db	sk6
	.db	sk5
	.db	sk4
	.db	sk3
	.db	sk2
	.db	sk1
	.db	sk0


;====== Text Entry Table =======================================================
textAlphaTable:
	.db	(endLetterTable-letterTable) / 2
	.dw	letterTable
textAlphaSymbolTable:
	.db	(endLetterTable2-endLetterTable) / 2
	.dw	endLetterTable
textNumberTable:
	.db	(endNumberTable-numberTable) / 2
	.dw	numberTable
textNumberSymbolTable:
	.db	(endNumberTable2-endNumberTable) / 2
	.dw	endNumberTable
textControlCharTable:
	.db	(endControlTable-controlTable) / 2
	.dw	controlTable
text2ndControlCharTable:
	.db	(endControl2ndTable-control2ndTable) / 2
	.dw	control2ndTable
textAlphaControlCharTable:
	.db	(endControlAlphaTable-controlAlphaTable) / 2
	.dw	controlAlphaTable

letterTable:
	.db	skMath, "A"
	.db	skMatrix, "B"
	.db	skPrgm, "C"
	.db	skRecip, "D"
	.db	skSin, "E"
	.db	skCos, "F"
	.db	skTan, "G"
	.db	skPower, "H"
	.db	skSquare, "I"
	.db	skComma, "J"
	.db	skLParen, "K"
	.db	skRParen, "L"
	.db	skDiv, "M"
	.db	skLog, "N"
	.db	sk7, "O"
	.db	sk8, "P"
	.db	sk9, "Q"
	.db	skMul, "R"
	.db	skLn, "S"
	.db	sk4, "T"
	.db	sk5, "U"
	.db	sk6, "V"
	.db	skSub, "W"
	.db	skStore, "X"
	.db	sk1, "Y"
	.db	sk2, "Z"
;	.db	sk3, "[" ; Theta
endLetterTable:
	.db	sk0, " "
	.db	skDecPnt, ":"
	.db	skChs, "?"
	.db	skAdd, 22h
	.db	skVars, "!"
	.db	skStat, "#"
	.db	skGraphVar, "&"
	.db	skYEqu, "$"
	.db	skWindow, "%"
	.db	skZoom, 27h
	.db	skTrace, "["
	.db	skGraph, "]"
endLetterTable2:
letterTableLength .equ (endLetterTable2 - letterTable) / 2
numberTable:
	.db	sk7, "7"
	.db	sk8, "8"
	.db	sk9, "9"
	.db	sk4, "4"
	.db	sk5, "5"
	.db	sk6, "6"
	.db	skSub, "-"
	.db	sk1, "1"
	.db	sk2, "2"
	.db	sk3, "3"
	.db	sk0, "0"
	.db	skDecPnt, "."
endNumberTable:
	.db	skComma, ","
	.db	skLParen, "("
	.db	skRParen, ")"
	.db	skDiv, 2Fh
	.db	skMul, "*"
	.db	skAdd, "+"
	.db	skPower, "^"
	.db	skCos, "{"
	.db	skTan, "}"
	.db	skSin, "|"
	.db	skLog, ";"
	.db	skPrgm, "<"
	.db	skVars, ">"
	.db	skMatrix, "="
	.db	skLn, 5Ch
	.db	skSquare, "@"
	.db	skRecip, "`"
	.db	skMath, "~"
endNumberTable2:
numberTableLength .equ	(endNumberTable2 - numberTable) / 2
controlTable:
	.db	skEnter, chEnter
	.db	skClear, chClear
	.db	skMode, chMode
	.db	skDel, chDel
	.db	skUp, chUp
	.db	skDown, chDown
	.db	skLeft, chLeft
	.db	skRight, chRight
endControlTable:
control2ndTable:
	.db	skEnter, ch2ndEnter
	.db	skClear, ch2ndClear
	.db	skMode, ch2ndMode
	.db	skDel, ch2ndDel
	.db	skUp, ch2ndUp
	.db	skDown, ch2ndDown
	.db	skLeft, ch2ndLeft
	.db	skRight, ch2ndRight
endControl2ndTable:
controlAlphaTable:
	.db	skEnter, chAlphaEnter
	.db	skClear, chAlphaClear
	.db	skMode, chAlphaMode
	.db	skDel, chAlphaDel
	.db	skUp, chAlphaUp
	.db	skDown, chAlphaDown
	.db	skLeft, chAlphaLeft
	.db	skRight, chAlphaRight
endControlAlphaTable: