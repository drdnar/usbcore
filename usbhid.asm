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

.ifdef	NEVER
(9:12:01 PM) BrandonW: DrDnar, I feel I should warn you that the boot code's PutC routine eventually calls the character hook if the OS has been validated, and the process of checking whether the OS is validated will lock flash back.
(9:12:10 PM) BrandonW: So don't be using it while flash is unlocked.
(9:12:20 PM) BrandonW: It took me a very, very long time to track that down once.
(9:12:25 PM) BrandonW: Maybe it'll save you some time if you didn't already know.
(9:13:22 PM) DrDnar: It checks if the OS is validated EVERY time it writes a character?
(9:13:54 PM) BrandonW: Yes, it must since the fact that it's running isn't a guarantee that the OS is validated (which is an assumption that the OS itself can make).
(9:14:35 PM) DrDnar: Does the boot code use the localize hook to display its messages in a different language?
(9:15:17 PM) BrandonW: No, this is only for changing character bitmap data.
(9:15:25 PM) BrandonW: "character hook" probably wasn't the appropriate term to use, sorry.
(9:15:40 PM) BrandonW: So the font hook, I suppose.
(9:15:52 PM) DrDnar: So you can change boot code's font? What possible use could that be?
(9:16:48 PM) BrandonW: It just maintains consistency when a person with such a hook installed visits the MODE menu.
(9:17:09 PM) BrandonW: The text for the boot code version is displayed by it.
(9:17:38 PM) BrandonW: They check that the OS is validated first so that you don't just jump into the boot code to unlock flash and steal control back with a hook.
(9:18:13 PM) BrandonW: Or something.
(9:18:27 PM) BrandonW: Not MODE, I meant self-test, sorry.
(9:18:57 PM) DrDnar: How could you have control in the first place if the OS isn't validated?
(9:19:11 PM) BrandonW: There are ways.
(9:19:35 PM) DrDnar: Of course, but how many of those ways don't involve an exploit of their own?
(9:20:31 PM) BrandonW: I know it's not the sharpest logic, but they don't like the idea of passing control to something they don't first have a modicum of trust in.
(9:24:37 PM) BrandonW: I work around this PutC flash relock thing in the boot code 1.03 exploit by not writing the final OS valid marker until I'm ready to lock flash back myself.
(9:24:56 PM) BrandonW: It checks the page 0 markers before bothering to check the certificate (which is what causes the relock).
(9:25:01 PM) BrandonW: So if the page 0 markers fail, you have no problem.
(9:25:08 PM) BrandonW: With an OS already installed, though...you're screwed.
(9:25:45 PM) DrDnar: Hmm . . . might still be possible to work around. . . .
(9:25:52 PM) DrDnar: Does the OS PutC lock flash?
(9:25:58 PM) DrDnar: I don't recall so.
(9:26:11 PM) BrandonW: I highly doubt it.
(9:26:24 PM) BrandonW: It couldn't, no.
(9:26:29 PM) DrDnar: Otherwise the Calcsys hack that unlocks flash wouldn't work.
(9:26:55 PM) DrDnar: So I can switch between the two PutCs depending on my needs.

; This may become useful later.
BootPutCInit:
; Finds the location of the boot code's PutC.
; Inputs:
;  - None
; Outputs:
;  - bootPutCLocation: Location on page FF of PutC
;  - Z if PutC found
;  - NZ if PutC not found (probable boot code change)
; Destroys:
;  - Current flash page mappings
;  - AF
;  - BC
;  - DE
;  - HL
	ld	a, 7Fh
	out	(pMPgA), a
	out	(pMPgAHigh), a	; Neat trick, huh?
	ld	hl, (408Ah)
	ld	de, _DispBootVerSeq
	call	CompStr
	ret	nz
	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a
	ld	de, _PutSSeq
	call	CompStr
	ret	nz
	push	hl
	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a
	ld	de, _PutCSeq
	call	CompStr
	pop	hl
	ld	(bootPutCLocation), hl
	ret


BootPutC:
; Calls PutC from the boot code.
; Inputs:
;  - A: Character to display
;  - CurRow, CurCol
;  - Whatever other assorted things EOS may screw with
; Outputs:
;  - Char displayed
;  - Stuff screwed with
; Destroys:
;  - Assume all
	push	hl
	push	bc
	ld	b, a
	in	a, (pMPgAHigh)
	rra
	in	a, (pMPgA)
	push	af
	ld	a, 7Fh
	out	(pMPgA), a
	out	(pMPgAHigh), a
	ld	a, b
	ld	hl, (bootPutCLocation)
	call	CallHL
	pop	af
	out	(pMPgA), a
	rla
	out	(pMPgAHigh), a
	pop	bc
	pop	hl
	ret


; Boot code function stub patterns.
; BootPutCInit uses these to verify that it has, in fact, found PutC.
_DispBootVerSeq:
	.db	_DispBootVerSeqEnd - _DispBootVerSeq - 1
; From BOOT4.0
; 44D2: 210000 225984 211845 CD7471
	ld	hl, 0000
	ld	(08459h), hl	; curRow
	ld	hl, 0000
	.db	0CD	; call
_DispBootVerSeqEnd:

_PutSSeq:
	.db	_PutSSeqEnd - _PutSSeq - 1
; 7172: C5 F5 060A 7E 23 B7 37 2809 CD3271
	push	bc
	push	af
	ld	b, 00
	ld	a, (hl)
	inc	hl
	or	a
	scf	; WTF?
	jr	z, $ + 2
	.db	0CD	; call
_PutSSeqEnd:

_PutCSeq:
	.db	_PutCSeqEnd - _PutCSeq - 1
; 7132: F5 E5 FED6 2008 CD0672 CD8B71
	push	af
	push	hl
	cp	0D6h	; new line
	jr	nz, $ + 2
	call	0000
	call	0000
_PutCSeqEnd:

CompStr:
; Compares two sequences of bytes.
; Inputs:
;  - DE: Length-prefixed check string. 00 = wildcard
;  - HL: String to compare check string to
; Outputs:
;  - Z: Strings are equal
;     - HL, DE point to byte after last byte
;  - NZ: String are different
;     - HL, DE point to byte that differs
; Destroys:
;  - AF
;  - BC
;  - DE
;  - HL
	ld	a, (de)
	inc	de
	ld	b, a
@:	ld	a, (de)
	or	a
	jr	z, {@}
	cp	(hl)
	ret	nz
@:	inc	hl
	inc	de
	djnz	{-2@}
	ret
	
.endif



.binarymode ti8x

;.define	screenDi	di
;.define	screenEi	ei
.define	screenDi	nop \ nop
.define	screenEi	nop \ nop
.define	LOGGING_ENABLED

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
.include "usbequates.asm"
.include "equates.asm"

.define	UNIT_TESTS

.define	SWAP_BANK_A

.ifndef	SWAP_BANK_B
pSwapBank	.equ	pMPgB
pSwapBankHigh	.equ	pMPgBHigh
.else
pSwapBank	.equ	6;pMPgA
pSwapBankHigh	.equ	14;pMPgAHigh
.endif


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
.ifndef	UNIT_TESTS
	.db	"1. HID Demo", chNewLine
.else
	.db	"1. Unit Tests", chNewLine
.endif
	.db	"7. Logging Test", chNewLine
	.db	"8. Reset Log", chNewLine
	.db	"9. Read Log", chNewLine
	.db	"Clear: Quit:"
	.db	0
	.db	sk1
.ifndef	UNIT_TESTS
	.dw	HidDemo
.else
	.db	unitTestsMenu - 1
.endif
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



.ifdef	UNIT_TESTS
	.db	0
unitTestsMenu:
;		 1234567890123456 C 0123456789012345
;	.db	"            UNIT TESTS
	.db	"           "
	.db	80h, ('U'|80h), ('N'|80h), ('I'|80h), ('T'|80h), (' '|80h)
	.db	('T'|80h), ('E'|80h), ('S'|80h), ('T'|80h), ('S'|80h)
	.db	80h, chNewLine
	.db	"1. Start driver", chNewLine
	.db	"2. Queue tests", chNewLine
	.db	"3. Buffering tests"
	.db	0
	.db	sk1
	.dw	_doStartDriver
	.db	skClear
	.dw	Restart
	.db	0

_doStartDriver:
;	ld	hl, hidTestPipeSetupData
	call	SetupDriver
	call	InitializePeripheralMode


.endif

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

usb_driver_start:
.include "usb_driver.asm"
usb_driver_end:

hiddemo_start:
.include "hiddemo.asm"
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
;.echo	"Logging size: ", linky_end - linky_start, " bytes\n"
.echo	" Log strings size: ", log_table_end - log_table_start, " bytes\n"
.echo	"USB driver size: ", usb_driver_end - usb_driver_start, " bytes\n"
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