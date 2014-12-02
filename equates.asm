; This program is free software. It comes without any warranty, to
; the extent permitted by applicable law. You can redistribute it
; and/or modify it under the terms of the Do What The Fuck You Want
; To Public License, Version 2, as published by Sam Hocevar. See
; http://sam.zoy.org/wtfpl/COPYING for more details.

; This file contains offsets of memory locations and constants that replace
; ti83plus.inc or ti84pcse.inc .

#define equ	.equ

; This macro prints a value in hex
.deflong EchoByte(x)
	.if (x) < 10h
		.echo	"0"
	.elseif (x) < 20h
		.echo	"1"
	.elseif (x) < 30h
		.echo	"2"
	.elseif (x) < 40h
		.echo	"3"
	.elseif (x) < 50h
		.echo	"4"
	.elseif (x) < 60h
		.echo	"5"
	.elseif (x) < 70h
		.echo	"6"
	.elseif (x) < 80h
		.echo	"7"
	.elseif (x) < 90h
		.echo	"8"
	.elseif (x) < 0A0h
		.echo	"9"
	.elseif (x) < 0B0h
		.echo	"A"
	.elseif (x) < 0C0h
		.echo	"B"
	.elseif (x) < 0D0h
		.echo	"C"
	.elseif (x) < 0E0h
		.echo	"D"
	.elseif (x) < 0F0h
		.echo	"E"
	.elseif (x) < 100h
		.echo	"F"
	.else
		.echo	"?"
	.endif
	.if (x % 10h) == 0
		.echo "0"
	.elseif (x % 10h) == 1
		.echo "1"
	.elseif (x % 10h) == 2
		.echo "2"
	.elseif (x % 10h) == 3
		.echo "3"
	.elseif (x % 10h) == 4
		.echo "4"
	.elseif (x % 10h) == 5
		.echo "5"
	.elseif (x % 10h) == 6
		.echo "6"
	.elseif (x % 10h) == 7
		.echo "7"
	.elseif (x % 10h) == 8
		.echo "8"
	.elseif (x % 10h) == 9
		.echo "9"
	.elseif (x % 10h) == 10
		.echo "A"
	.elseif (x % 10h) == 11
		.echo "B"
	.elseif (x % 10h) == 12
		.echo "C"
	.elseif (x % 10h) == 13
		.echo "D"
	.elseif (x % 10h) == 14
		.echo "E"
	.elseif (x % 10h) == 15
		.echo "F"
	.else
		.echo "?"
	.endif
.enddeflong

; This macro prints a value in hex
.deflong EchoWord(x)
	.if (x) < 1000h
		.echo	"0"
	.elseif (x) < 2000h
		.echo	"1"
	.elseif (x) < 3000h
		.echo	"2"
	.elseif (x) < 4000h
		.echo	"3"
	.elseif (x) < 5000h
		.echo	"4"
	.elseif (x) < 6000h
		.echo	"5"
	.elseif (x) < 7000h
		.echo	"6"
	.elseif (x) < 8000h
		.echo	"7"
	.elseif (x) < 9000h
		.echo	"8"
	.elseif (x) < 0A000h
		.echo	"9"
	.elseif (x) < 0B000h
		.echo	"A"
	.elseif (x) < 0C000h
		.echo	"B"
	.elseif (x) < 0D000h
		.echo	"C"
	.elseif (x) < 0E000h
		.echo	"D"
	.elseif (x) < 0F000h
		.echo	"E"
	.elseif (x) < 10000h
		.echo	"F"
	.else
		.echo	"?"
	.endif
	.if ((x) % 1000h) < 100h
		.echo "0"
	.elseif ((x) % 1000h) < 200h
		.echo "1"
	.elseif ((x) % 1000h) < 300h
		.echo "2"
	.elseif ((x) % 1000h) < 400h
		.echo "3"
	.elseif ((x) % 1000h) < 500h
		.echo "4"
	.elseif ((x) % 1000h) < 600h
		.echo "5"
	.elseif ((x) % 1000h) < 700h
		.echo "6"
	.elseif ((x) % 1000h) < 800h
		.echo "7"
	.elseif ((x) % 1000h) < 900h
		.echo "8"
	.elseif ((x) % 1000h) < 0A00h
		.echo "9"
	.elseif ((x) % 1000h) < 0B00h
		.echo "A"
	.elseif ((x) % 1000h) < 0C00h
		.echo "B"
	.elseif ((x) % 1000h) < 0D00h
		.echo "C"
	.elseif ((x) % 1000h) < 0E00h
		.echo "D"
	.elseif ((x) % 1000h) < 0F00h
		.echo "E"
	.elseif ((x) % 1000h) < 10000h
		.echo "F"
	.else
		.echo "!"
	.endif
	.if ((x) % 100h) < 10h
		.echo "0"
	.elseif ((x) % 100h) < 20h
		.echo "1"
	.elseif ((x) % 100h) < 30h
		.echo "2"
	.elseif ((x) % 100h) < 40h
		.echo "3"
	.elseif ((x) % 100h) < 50h
		.echo "4"
	.elseif ((x) % 100h) < 60h
		.echo "5"
	.elseif ((x) % 100h) < 70h
		.echo "6"
	.elseif ((x) % 100h) < 80h
		.echo "7"
	.elseif ((x) % 100h) < 90h
		.echo "8"
	.elseif ((x) % 100h) < 0A0h
		.echo "9"
	.elseif ((x) % 100h) < 0B0h
		.echo "A"
	.elseif ((x) % 100h) < 0C0h
		.echo "B"
	.elseif ((x) % 100h) < 0D0h
		.echo "C"
	.elseif ((x) % 100h) < 0E0h
		.echo "D"
	.elseif ((x) % 100h) < 0F0h
		.echo "E"
	.elseif ((x) % 100h) < 1000h
		.echo "F"
	.else
		.echo "!"
	.endif
	.if ((x) % 10h) == 0
		.echo "0"
	.elseif ((x) % 10h) == 1
		.echo "1"
	.elseif ((x) % 10h) == 2
		.echo "2"
	.elseif ((x) % 10h) == 3
		.echo "3"
	.elseif ((x) % 10h) == 4
		.echo "4"
	.elseif ((x) % 10h) == 5
		.echo "5"
	.elseif ((x) % 10h) == 6
		.echo "6"
	.elseif ((x) % 10h) == 7
		.echo "7"
	.elseif ((x) % 10h) == 8
		.echo "8"
	.elseif ((x) % 10h) == 9
		.echo "9"
	.elseif ((x) % 10h) == 10
		.echo "A"
	.elseif ((x) % 10h) == 11
		.echo "B"
	.elseif ((x) % 10h) == 12
		.echo "C"
	.elseif ((x) % 10h) == 13
		.echo "D"
	.elseif ((x) % 10h) == 14
		.echo "E"
	.elseif ((x) % 10h) == 15
		.echo "F"
	.else
		.echo "?"
	.endif
.enddeflong

;------ Version ----------------------------------------------------------------
; This is quite a hack.
; It converts the build number constant into an ASCII string.
; If you've got a better way to do this, I'd love to hear it.
; Update: unknownln suggested using Brass's looping structure, so I'll keep that
; in mind for the future.
.include "build_number.asm"
.define VERSION_1a ((BUILD) % 10)
.define VERSION_2a ((BUILD) % 100)
.define VERSION_3a ((BUILD) % 1000)
.define VERSION_4a ((BUILD) % 10000)
.define VERSION_5a ((BUILD) % 100000)
.define VERSION_6a ((BUILD) % 1000000)
.define VERSION_6b (VERSION_6a - VERSION_5a)
.define VERSION_5b (VERSION_5a - VERSION_4a)
.define VERSION_4b (VERSION_4a - VERSION_3a)
.define VERSION_3b (VERSION_3a - VERSION_2a)
.define VERSION_2b (VERSION_2a - VERSION_1a)
.define VERSION_1b (VERSION_1a)
.define VERSION_1c (VERSION_1b)
.define VERSION_2c (VERSION_2b / 10)
.define VERSION_3c (VERSION_3b / 100)
.define VERSION_4c (VERSION_4b / 1000)
.define VERSION_5c (VERSION_5b / 10000)
.define VERSION_6c (VERSION_6b / 100000)
.if	BUILD < 10
	.define	VERSION		('0' + VERSION_1c)
.elseif	BUILD < 100
	.define	VERSION		('0' + VERSION_2c), ('0' + VERSION_1c)
.elseif	BUILD < 1000
	.define	VERSION		('0' + VERSION_3c), ('0' + VERSION_2c), ('0' + VERSION_1c)
.elseif	BUILD < 10000
	.define	VERSION		('0' + VERSION_4c), ('0' + VERSION_3c), ('0' + VERSION_2c), ('0' + VERSION_1c)
.elseif	BUILD < 100000
	.define	VERSION		('0' + VERSION_5c), ('0' + VERSION_4c), ('0' + VERSION_3c), ('0' + VERSION_2c), ('0' + VERSION_1c)
.else
	.define	VERSION		('0' + VERSION_6c), ('0' + VERSION_5c), ('0' + VERSION_4c), ('0' + VERSION_3c), ('0' + VERSION_2c), ('0' + VERSION_1c)
.endif


;------ Macros -----------------------------------------------------------------

; Reads the value of an LCD register into HL
.deflong getLcdRegHl(regnum)
	ld a, regnum
	out (pLcdCmd), a
	out (pLcdCmd), a
	in a, (pLcdData)
	ld h, a
	in a, (pLcdData)
	ld l, a
.enddeflong

; Sets the value of an LCD register using HL
.deflong setLcdRegHl(regnum)
	ld a, regnum
	out (pLcdCmd), a
	out (pLcdCmd), a
	ld a, h
	out (pLcdData), a
	ld a, l
	out (pLcdData), a
.enddeflong

; Sets the value of an LCD register
; Both fixed constants and 8-bit registers (other than A) can be used
.deflong setLcdReg(regnum, highbyte, lowbyte)
	ld a, regnum
	out (pLcdCmd), a
	out (pLcdCmd), a
	ld a, highbyte
	out (pLcdData), a
	ld a, lowbyte
	out (pLcdData), a
.enddeflong

; Sets the value of an LCD register
; The value must be a fixed constant
.deflong setLcdDReg(regnum, double)
	ld a, regnum
	out (pLcdCmd), a
	out (pLcdCmd), a
	ld a, lcdHigh(double)
	out (pLcdData), a
	ld a, lcdLow(double)
	out (pLcdData), a
.enddeflong

; Standard optimized in-line routine
.deflong cpHlDe
	or	a
	sbc	hl, de
	add	hl, de
.enddeflong

; Standard optimized in-line routine
.deflong cpHlBc
	or	a
	sbc	hl, bc
	add	hl, bc
.enddeflong

; USB LOGGING

logReg16	.equ	80h
logNoReg	.equ	0
logRegA		.equ	1
logRegBC	.equ	2 + logReg16
logRegC		.equ	2
logRegB		.equ	3
logRegDE	.equ	4 + logReg16
logRegE		.equ	4
logRegD		.equ	5
logRegHL	.equ	6 + logReg16
logRegL		.equ	6
logRegH		.equ	7
logRegIX	.equ	8 + logReg16
logRegIXL	.equ	8
logRegIXH	.equ	9
logRegIY	.equ	10 + logReg16
logRegIYL	.equ	10
logRegIYH	.equ	11
logRegPC	.equ	12 + logReg16

.deflong LogEvent(logid, logtype)
.ifdef	LOGGING_ENABLED
	call	LogItem
	.db	logid
	.db	logtype
.endif
.enddeflong

.deflong LogUsbIntEvent(logid, logtype)
.ifdef	LOG_USB_INT
	call	LogItem
	.db	logid
	.db	logtype
.endif
.enddeflong

.deflong LogUsbLowEvent(logid, logtype)
.ifdef	LOG_USB_LOW
	call	LogItem
	.db	logid
	.db	logtype
.endif
.enddeflong

.deflong LogUsbPhyEvent(logid, logtype)
.ifdef	LOG_USB_PHY
	call	LogItem
	.db	logid
	.db	logtype
.endif
.enddeflong

.deflong LogUsbProtEvent(logid, logtype)
.ifdef	LOG_USB_PROT
	call	LogItem
	.db	logid
	.db	logtype
.endif
.enddeflong

.deflong LogUsbQueueEvent(logid, logtype)
.ifdef	LOG_USB_QUEUE
	call	LogItem
	.db	logid
	.db	logtype
.endif
.enddeflong

.deflong LogEventByte(logid)
.ifdef	LOGGING_ENABLED
	push	af
	push	bc
	push	hl
	ld	b, logid
	call	LogByte
	pop	hl
	pop	bc
	pop	af
.endif
.enddeflong

.deflong LogEventNull(logid)
.ifdef	LOGGING_ENABLED
	push	af
	push	bc
	push	hl
	ld	b, logid
	call	LogNull
	pop	hl
	pop	bc
	pop	af
.endif
.enddeflong

.deflong LogUsbIntEventNull(logid)
	.ifdef	LOG_USB_INT
	push	af
	push	bc
	push	hl
	ld	b, logid
	call	LogNull
	pop	hl
	pop	bc
	pop	af
	.endif
.enddeflong

.deflong LogUsbLowEventNull(logid)
	.ifdef	LOG_USB_LOW
	push	af
	push	bc
	push	hl
	ld	b, logid
	call	LogNull
	pop	hl
	pop	bc
	pop	af
	.endif
.enddeflong

.deflong LogUsbPhyEventNull(logid)
	.ifdef	LOG_USB_PHY
	push	af
	push	bc
	push	hl
	ld	b, logid
	call	LogNull
	pop	hl
	pop	bc
	pop	af
	.endif
.enddeflong

.deflong LogUsbProtEventNull(logid)
	.ifdef	LOG_USB_PROT
	push	af
	push	bc
	push	hl
	ld	b, logid
	call	LogNull
	pop	hl
	pop	bc
	pop	af
	.endif
.enddeflong

.deflong LogEvent8(logid, value)
.ifdef	LOGGING_ENABLED
	push	af
	push	bc
	push	de
	push	hl
	ld	e, value
	ld	b, logid
	call	Log8
	pop	hl
	pop	de
	pop	bc
	pop	af
.endif
.enddeflong

.deflong LogUsbIntEvent8(logid, value)
	.ifdef	LOG_USB_INT
	push	af
	push	bc
	push	de
	push	hl
	ld	e, value
	ld	b, logid
	call	Log8
	pop	hl
	pop	de
	pop	bc
	pop	af
	.endif
.enddeflong

.deflong LogUsbLowEvent8(logid, value)
	.ifdef	LOG_USB_LOW
	push	af
	push	bc
	push	de
	push	hl
	ld	e, value
	ld	b, logid
	call	Log8
	pop	hl
	pop	de
	pop	bc
	pop	af
	.endif
.enddeflong

.deflong LogUsbPhyEvent8(logid, value)
	.ifdef	LOG_USB_PHY
	push	af
	push	bc
	push	de
	push	hl
	ld	e, value
	ld	b, logid
	call	Log8
	pop	hl
	pop	de
	pop	bc
	pop	af
	.endif
.enddeflong

.deflong LogUsbProtEvent8(logid, value)
	.ifdef	LOG_USB_PROT
	push	af
	push	bc
	push	de
	push	hl
	ld	e, value
	ld	b, logid
	call	Log8
	pop	hl
	pop	de
	pop	bc
	pop	af
	.endif
.enddeflong

.deflong LogEvent16(logid, value)
.ifdef	LOGGING_ENABLED
	push	af
	push	bc
	push	de
	push	hl
	ld	de, value
	ld	b, logid
	call	Log16
	pop	hl
	pop	de
	pop	bc
	pop	af
.endif
.enddeflong

.deflong LogUsbIntEventDE(logid)
	.ifdef	LOG_USB_INT
	push	af
	push	bc
	push	de
	push	hl
	ld	b, logid
	call	Log16
	pop	hl
	pop	de
	pop	bc
	pop	af
	.endif
.enddeflong

.deflong LogUsbLowEventDE(logid)
	.ifdef	LOG_USB_LOW
	push	af
	push	bc
	push	de
	push	hl
	ld	b, logid
	call	Log16
	pop	hl
	pop	de
	pop	bc
	pop	af
	.endif
.enddeflong

.deflong LogUsbPhyEventDE(logid)
	.ifdef	LOG_USB_PHY
	push	af
	push	bc
	push	de
	push	hl
	ld	b, logid
	call	Log16
	pop	hl
	pop	de
	pop	bc
	pop	af
	.endif
.enddeflong

.deflong LogUsbProtEventDE(logid)
	.ifdef	LOG_USB_PROT
	push	af
	push	bc
	push	de
	push	hl
	ld	b, logid
	call	Log16
	pop	hl
	pop	de
	pop	bc
	pop	af
	.endif
.enddeflong

.deflong UnitTestPrint(str)
	.ifdef	UNIT_TESTS
	push	hl
	ld	hl, {+}
	call	PutS
	jr	{++}
+:	.db	str, 0
++:	pop	hl
	.endif
.enddeflong

.deflong UnitTestPrintHL()
	.ifdef	UNIT_TESTS
	push	hl
	push	af
	call	DispHL
	pop	af
	pop	hl
	.endif
.enddeflong

.deflong UnitTestPrintDE()
	.ifdef	UNIT_TESTS
	push	hl
	push	de
	push	af
	ex	de, hl
	call	DispHL
	pop	af
	pop	de
	pop	hl
	.endif
.enddeflong

.deflong UnitTestPrintA()
	.ifdef	UNIT_TESTS
	push	hl
	push	af
	call	DispByte
	pop	af
	pop	hl
	.endif
.enddeflong

.deflong UnitTestPrintChar(char)
	.ifdef	UNIT_TESTS
	push	hl
	push	af
	ld	a, char
	call	PutC
	pop	af
	pop	hl
	.endif
.enddeflong

;------ Structs ----------------------------------------------------------------
; 32-bit page/address pointer


;------ Main Memory Layout Settings --------------------------------------------
; Scrap memory usage:
;  - plotSScreen: Used for interrupts
;  - textShadow: Used for variables
;  - statVars: 
;  - saveSScreen: Used for USB buffers
;  - appData: 
;plotSScreen	equ	987Ch
;saveSScreen	equ	8798h
;textShadow	equ	08560h	; 260 bytes
;cmdShadow	equ	09BAAh ; Also expanded, but don't use this unless you want some crazy clean-up code
;statVars		equ	8C1Ch	; scrap 531 (clear b_call(_DelRes))
;appData	equ	8000h

start_of_static_vars	.equ	textShadow
; 9A01 is not free! It's the last byte of the IVT.
IvtLocation	.equ	99h ; vector table at 9900h
IsrLocation	.equ	98h ; ISR at 9898h
usbBuffers	.equ	saveSScreen


;------ Character Constants ----------------------------------------------------
chQuotes	.equ	22h
chNewLine	.equ	01h
chEnter		.equ	01h
chTab		.equ	02h
chBackspace	.equ	03h
chDel		.equ	03h
ch1stPrintableChar	.equ	4
chCheckBox	.equ	04h
chClear		.equ	04h
chCheckedBox	.equ	05h
ch2ndClear	.equ	05h
chCheckedBox2	.equ	06h
chAlphaClear	.equ	06h
chOpenRadio	.equ	07h
ch2ndDel	.equ	07h
chFilledRadio	.equ	08h
chInsert	.equ	09h
chBullet	.equ	09h
chAlphaDel	.equ	0Ah
chRight		.equ	0Ah
chLeft		.equ	0Bh
chLeftRight	.equ	0Ch
chDown		.equ	0Dh
chUp		.equ	0Eh
chUpDown	.equ	0Fh
chBox		.equ	10h
chLightShade	.equ	11h
chMode		.equ	11h
chMediumShade	.equ	12h
ch2ndMode	.equ	12h
chDarkShade	.equ	13h
chAlphaMode	.equ	13h
chFilledShade	.equ	14h
ch2ndRight	.equ	15h
ch2ndLeft	.equ	16h
ch2ndEnter	.equ	17h
ch2ndDown	.equ	18h
ch2ndUp		.equ	19h
chAlphaRight	.equ	1Ah
chAlphaLeft	.equ	1Bh
chAlphaEnter	.equ	1Ch
chAlphaDown	.equ	1Dh
chAlphaUp	.equ	1Eh
chBeta		.equ	7Fh
chCur		.equ	80h
chCur2nd	.equ	81h
chCurAlpha	.equ	82h
chCurAlphaLwr	.equ	83h
chCurIns	.equ	84h
chCurIns2nd	.equ	85h
chCurInsAlpha	.equ	86h
chCurInsAlphaLwr	.equ	87h
chCurFull	.equ	01h
chCurLeftLine	.equ	02h
chCurUnderline	.equ	03h


;------ Screen & Text ----------------------------------------------------------
.ifndef	SMALL_FONT
charWidth = 9
charHeight = 14
charLength = 16
textRows = 17
textCols = 35
.else
charWidth = 6
charHeight = 9
charLength = 7
textRows = 26
textCols = 53
.endif
colorScrnHeight = 240
colorScrnWidth = 320
minBacklightLevel = 32
defaultBrightness = 10h


;------ Settings ---------------------------------------------------------------
; Timers
; Sets how many half-seconds elapse until APD
suspendDelay	.equ	2*60*3
; Sets the frequency at which the keyboard is scanned
kbdScanDivisor		.equ	10	; The below values are multiples of 10.24 ms
; A key must be held this long to be accepted
minKeyHoldTime		.equ	3	; 
; A key must remain up for this long before it is registered as being released
keyBlockTime		.equ	1	; 
; This controls how long the wait until a held key starts repeating
keyFirstRepeatWaitTime	.equ	20	; 
; This controls how often a held key repeats
keyRepeatWaitTime	.equ	10	; 
; This controls how long to wait between toggling the cursor
cursorPeriod		.equ	200h


;------ Flags ------------------------------------------------------------------
; Flags
mApdFlags		.equ	xapFlag0	;application flags
mTextFlags		.equ	xapFlag0
mCursorFlags2		.equ	xapFlag0
mCursorFlags		.equ	xapFlag1	;[2nd] and [ALPHA] flags
inputerFlags		.equ	xapFlag2

; mCursorFlags
cursor2nd		.equ	0	;1=[2nd] has been pressed
cursor2ndMask		.equ	01h
cursorAlpha		.equ	1	;1=[ALPHA] has been pressed
cursorAlphaMask		.equ	02h
cursorLwrAlpha		.equ	2	;1=lower case, 0=upper case
cursorLwrAlphaMask	.equ	04h
cursorInsert		.equ	3
cursorInsertMask	.equ	08h
cursorALock		.equ	4	;1=alpha lock has been pressed
cursorALockMask		.equ	10h
cursorOther		.equ	5
cursorOtherMask		.equ	20h
; Unused bits
cursorAble 		.equ	6	;1=cursor flash is enabled
cursorAbleMask		.equ	40h
cursorShowing		.equ	7	;1=cursor is showing
cursorShowingMask	.equ	80h
; mTextFlags
mTextInverse		.equ	0	;1=display inverse bit-map
mTextInverseMask	.equ	1
; mCursorFlags2
cursorFlash		.equ	1
cursorFlashMask		.equ	02h
; mApdFlags
apdEnabled		.equ	6
apdEnabledMask		.equ	40h
apdNow			.equ	7
apdNowMask		.equ	80h
; inputerFlags
allowAlpha		.equ	0
allowAlphaMask		.equ	01h
allowLwrAlpha		.equ	1
allowLwrAlphaMask	.equ	02h
allowNumbers		.equ	2
allowNumbersMask	.equ	04h
allowSymbols		.equ	3
allowSymbolsMask	.equ	08h
allowControl		.equ	4
allowControlMask	.equ	10h
allowAllMask		.equ	allowAlphaMask + allowLwrAlphaMask + allowNumbersMask + allowSymbolsMask + allowControlMask
secondNibble		.equ	7


;------ Colors -----------------------------------------------------------------
colorBlack	.equ	00
colorGreen	.equ	04	; 06 for normal maximum saturation green
colorBrGreen	.equ	06
colorNavyBlue	.equ	08
colorDarkBlue	.equ	10h
colorBlue	.equ	18h
colorDarkGray	.equ	6Bh
colorGray	.equ	0B5h
colorRed	.equ	0E0h
colorYellow	.equ	0E7h
colorWhite	.equ	0FFh
; Hex   Component 5/6/5	Component 8/8/8	Color RGB	Color BGR
; 00	 0,    0,  0	  0,   0,   0	Black		Black
; 06	 0,   24,  6	  0, 192,  48	Green		Green
; 08	 1,    0,  8	  8,   0,  64	Navy Blue	Dark Maroon?
; 18	 3,    0, 24	 24,   0, 192	Blue		Red
; 1F	 3,   28, 31	 24, 224, 248	Baby Blue?	Gold/Yellow?
; 4A	 9,    9, 10
; 60	12,  1.5,  0	 96,  12,   0	Maroon?		Dark Blue?
; 33	 0,   12,  3	  0,  96,  24	Dark Green	Better Dark Green
; 6B	13, 13.5, 11	104, 108,  88	Gray 39%	Gray 39%
;;; 77	28, 31.5,  7	224, 252,  56	Lime Green	Teal
; 77	 0,   28,  7	  0, 224,  26			Green-screen Green
; B5	22, 22.5, 21	176, 180, 168	Gray 68%	Gray 68%
; D8	27,    3, 24	216,  24, 192	Magenta?	Blue-Magenta? 
; DB	27,   27, 30	216, 216, 240	Gray 88%	Gray 88%
; E0	28,  3.5,  0	224,  28,   0	Red		Blue
; E7	28, 31.5,  7	224, 252,   0	Yellow
; FF	31,   31, 31	255, 255, 255	White		White


;------ Vars -------------------------------------------------------------------

;start_of_static_vars .equ saveSScreen
; General Variables
; start_of_static_vars is defined in the equates_bw or equates_pcse


pageAInitial	.equ	start_of_static_vars
pageAHighInitial	.equ	pageAInitial + 1
spInitial		.equ	pageAHighInitial + 1
end_of_stuff		.equ	spInitial + 2

; LOGGING
logStartAddress		.equ	end_of_stuff
logStartPage		.equ	logStartAddress + 2
logCount		.equ	logStartPage + 1
logAddress		.equ	logCount + 2
logPage			.equ	logAddress + 2
logReadAddress		.equ	logPage + 1
logReadPage		.equ	logReadAddress + 2
logReadCount		.equ	logReadPage + 1
interruptCounter	.equ	logReadCount + 2
end_of_logging		.equ	interruptCounter + 1

; APD
; This is intended to be looped once a second.
genFastTimer	.equ	end_of_logging
; This holds the number of cursor flashes left until APD is triggered
suspendTimer	.equ	genFastTimer + 2
end_of_apd_vars	.equ	suspendTimer + 2

; KEYBOARD
; This controls when the keyboard is scanned
kbdScanTimer		.equ	end_of_apd_vars
; These variables are all used for debouncing
lastKey			.equ	kbdScanTimer + 1	; Normally 0
lastKeyHoldTimer	.equ	lastKey + 1		; Normally minKeyHoldTime
lastKeyBlockTimer	.equ	lastKeyHoldTimer + 1	; Normally keyBlockTime
lastKeyFirstRepeatTimer	.equ	lastKeyBlockTimer + 1	; Normally keyFirstRepeatWaitTime
lastKeyRepeatTimer	.equ	lastKeyFirstRepeatTimer + 1	; Normally keyRepeatWaitTime
; Last accepted keycode
keyBuffer		.equ	lastKeyRepeatTimer + 1	; Normally 0
; When this reaches zero, a flag is set, indicating the cursor should flash
cursorTimer		.equ	keyBuffer + 1
end_of_kbd_vars	.equ	cursorTimer + 2

; SCREEN
currentRow	.equ	end_of_kbd_vars + 2
currentCol	.equ	currentRow + 1
tabPos1		.equ	currentCol + 1
tabPos2		.equ	tabPos1 + 1
tabPos3		.equ	tabPos2 + 1
tabPos4		.equ	tabPos3 + 1
windTop		.equ	tabPos4 + 1
windLeft	.equ	windTop + 1
windBottom	.equ	windLeft + 1
windRight	.equ	windBottom + 1
cursorChar	.equ	windRight + 1
cursorBackup	.equ	cursorChar + 1
end_of_screen_var	.equ	cursorBackup + 1

usb_vars	.equ	end_of_screen_var
;hid_vars	.equ	end_usb_vars
.include "usb_driver_equates.asm"
hid_vars	.equ	end_usb_vars