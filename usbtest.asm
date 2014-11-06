; This program is free software. It comes without any warranty, to
; the extent permitted by applicable law. You can redistribute it
; and/or modify it under the terms of the Do What The Fuck You Want
; To Public License, Version 2, as published by Sam Hocevar. See
; http://sam.zoy.org/wtfpl/COPYING for more details.

; Interrupt-driven USB core for the TI-84 Plus C SE
; Dr. D'nar
; drdnar@gmail.com
; Build using Brass (Ben Ryves Assembler) version 1.x

; So note: BCALL 5290 handles host-mode VBUS initialization

; TODO:
;  - Logging
;  - DPCs for interrupts
;  - New USB driver
;  - Check if charge pump is needed for peripheral mode



.binarymode ti8x

;.define	screenDi	di
;.define	screenEi	ei
.define	screenDi	nop \ nop
.define	screenEi	nop \ nop

.define	DEBUG

.ifdef	DEBUG
	.define	LOGGING_ENABLED
.endif

.ifdef	LOGGING_ENABLED
	.define	LOG_USB_INT
	.define	LOG_USB_LOW
	.define	LOG_USB_PHY
	.define	LOG_USB_PROT
.endif



.nolist
.include "ti84pcse.inc"
.include "dcse8.inc"
.list
.include "equates.asm"
.include "usbequates.asm"

;====== Header =================================================================
;------ DCSE -------------------------------------------------------------------
	.org	userMem
BinaryStart:
	.db $DE,$2A,"N",$BB,$B4,$BB,$B4,$BB,$B3,$BB,$C3,")D"   ;Disp "Needs D
	.db $BB,$BF,$BB,$BF,$BB,$C2,$BB,$C3,")CSE",$2A,$3F     ;oors CSE"
	.db $EF,$11                                            ;OpenLib(
	.db "D",$BB,$BF,$BB,$BF,$BB,$C2,$BB,$C3,"CSE",$11,$3F  ;(tokenized "DoorsCSE")
	.db $EF,$12,$3F                                        ;ExecLib
	.db $D5,$3F                                            ;Return
	.db tExtTok,tAsm84CPrgm,$3F                            ;Asm84CPrgm
HeaderStart:
	.dw	AsmStart - HeaderStart

	.dw	{2@} - {@}
	.db	ASMHEADER_FIELD_TYPE_LIB
@:	.db	"DoorsCSE", 8, 0
@:	
	.dw	{2@} - {@}
	.db	ASMHEADER_FIELD_TYPE_DESC
@:	.db	"Peripheral Mode Tests", 0
@:
	.dw	{2@} - {@}
	.db	ASMHEADER_FIELD_TYPE_AUTH
@:	.db	"USB Core Test", 0
@:
	.dw	0
	.db	255
AsmStart:
	.relocate	userMem

program_start:
generic_stuff_start:
	; Allow clean quitting
	ld	(spInitial), sp
	in	a, (pMPgA)
	ld	l, a
	in	a, (pMPgAHigh)
	ld	h, a
	ld	(pageAInitial), hl
	; This is important
	ld	a, cpu15MHz
	; OK, not really, but it helps a lot.
	out	(pCpuSpeed), a
	; Log location
	ld	a, 85h
	ld	(logStartPage), a
	ld	hl, 4000h
	ld	(logStartAddress), hl

; Interrupts
Restart:
	ld	sp, (spInitial)
	call	SetUpInterrupts
	ei
	call	ResetScreen
	call	ClrScrnFull
	xor	a
	ld	(keyBuffer), a
	ld	hl, thingy
	jp	Menu

thingy:
;		 1234567890123456 C 0123456789012345
;	.db	"            _MAIN MENU
	.db	"            "
	.db	80h, ('M'|80h), ('A'|80h), ('I'|80h), ('N'|80h), (' '|80h)
	.db	('M'|80h), ('E'|80h), ('N'|80h), ('U'|80h)
	.db	80h, chNewLine
;	.db	"Test program is live, but there is "
;	.db	"nothing to do.", chNewLine
	.db	"USB Peripheral Test Program", chNewLine
	.db	"Build ", VERSION, chNewLine
	.db	"1. HID Demo", chNewLine
	.db	"7. Logging Test", chNewLine
	.db	"8. Reset Log", chNewLine
	.db	"9. Read Log", chNewLine
	.db	"Clear: Quit:"
	.db	0
	.db	sk1
	.dw	HidDemo
	.db	sk7
	.dw	LoggingTest
	.db	sk8
	.dw	menuResetLog
	.db	sk9
	.dw	ShowLog
	.db	skClear
	.dw	Quit
	.db	0

menuResetLog:
	call	ResetLog
	jp	Restart

	
;====== Termination ============================================================
;------ Panic routine ----------------------------------------------------------
errorText:	.db	"BUG CHECK: ", 0
Panic:
	di
	ex	(sp), iy
	push	ix
	push	hl
	push	de
	push	bc
	push	af
	push	iy
	; Kill USB, hard
	xor	a
	out	(57h), a
	out	(5Bh), a
	out	(4Ch), a
	ld	a, 2
	out	(54h), a
	; Now reset other hardware
	call	SetUpInterrupts
	call	ResetScreen
	ld	hl, 0
	call	Locate
	ld	hl, errorText
	call	PutS
	pop	hl
	call	DispHL
	ld	a, ' '
	call	PutC
	ld	hl, BUILD
	call	DispDecimal
	call	NewLine
	ld	b, 4
@:	pop	hl
	call	DispHL
	ld	a, ' '
	call	PutC
	djnz	{-1@}
	pop	hl
	call	DispHL
	ld	a, ' '
	call	PutC
	pop	hl
	call	DispHL
	
	call	GetKey
	call	GetKey


;------ Actual code to return code to OS ---------------------------------------
; 31 March 2014 11:27:43 PM KermM: DrDnar: Set the LCD ports to full-window, bcall(_DrawStatusBar), clear out CmdShadow with spaces, fix the APD flags, homeup, then send kClear to _jforcecmd
Quit:
	di
	; Memory map
	ld	iy, flags
	ld	sp, (spInitial)
	ld	a, (pageAInitial)
	out	(pMPgA), a
	ld	a, (PageAHighInitial)
	out	(pMPgAHigh), a
	ld	a, 81h
	out	(pMPgB), a
	dec	a
	out	(pMPgC), a
	; Screen
	xor	a
	out	(pLcdCmd), a
	out	(pLcdCmd), a
	out	(pLcdCmd), a
	out	(pLcdCmd), a
	setLcdDReg(lrWinLeft, 0)
	setLcdDReg(lrWinRight, lcdWidth)
	setLcdDReg(lrWinTop, 0)
	setLcdDReg(lrWinBottom, lcdHeight)
	setLcdDReg(lrEntryMode, lcdDispCtrlDefault)
	; Interrupts
	ld	a, 1011b
	out	(pIntMask), a
	im	1
	ei
	call	EnableUSB
	; More screen stuff
;	This doesn't need to be cleared because I don't touch it.
;	ld	hl, cmdShadow 
;	ld	de, cmdShadow + 1
;	ld	(hl), '@' ; space
;	ld	bc, 259
;	ldir
;	Actually, this doesn't need to be cleared either.
;	ld	hl, textShadow
;	ld	de, textShadow+1
;	ld	(hl), '!'
;	ld	bc, 259
;	ldir
	b_call(_DelRes)
	res	OnInterrupt, (iy + OnFlags)
	ei
	halt	; flush any keys the user held down
	b_call(_GetCSC)
	ret
generic_stuff_end:



;====== Includes ===============================================================

logging_start:
.include "logging.asm"
logging_end:

linky_start:
.include "linkyequates.asm"
.include "linkyhook.asm"
.include "linkyroutines.asm"
.include "linkylow.asm"
linky_end:

hiddemo_start:
.include "linkyhiddemo.asm"
hiddemo_end:

utility_start:
.include "utility.asm"
utility_end:

interrupts_start:
.include "interrupts.asm"
interrupts_end:

keyboard_start:
.include "keyboard.asm"
keyboard_end:

lcd_start:
.include "lcd.asm"
lcd_end:

text_start:
.include "textmode.asm"
text_end:

data_start:
.include "data.asm"
data_end:

keyboard_data_start:
.include "keyboard_data.asm"
keyboard_data_end:

font_start:
.include "font_data.asm"
font_end:


program_end:


;====== INFORMATION ============================================================
.echo	"\n * INFORMATION & STATISTICS * \n"
.echo	"Build number: ", BUILD, "\n"
.echo	" * SIZES * \n"
.echo	"Initialization & termination code size: ", generic_stuff_end - generic_stuff_start, " bytes\n"
.echo	"Logging size: ", linky_end - linky_start, " bytes\n"
.echo	" Log strings size: ", log_table_end - log_table_start, " bytes\n"
.echo	"Linky size: ", linky_end - linky_start, " bytes\n"
.echo	"HID demo size: ", hiddemo_end - hiddemo_start, " bytes\n"
.echo	"Utility routines size: ", utility_end - utility_start, " bytes\n"
.echo	"Interrupt driver size: ", interrupts_end - interrupts_start, " bytes\n"
.echo	"Keyboard driver size: ", keyboard_end - keyboard_start, " bytes\n"
.echo	"LCD driver size: ", lcd_end - lcd_start, " bytes\n"
.echo	"Text driver size: ", text_end - text_start, " bytes\n"
;.echo	"LCD & text driver size: ", text_end - lcd_start, " bytes\n"
.echo	"Data size: ", data_end - data_start, " bytes\n"
.echo	"Font size: ", font_end - font_start, " bytes\n"
.echo	"Total program code & data: ", program_end - program_start, " bytes\n"
;.echo	" size: ", _end - _start, " bytes"
.echo	"\n"