; This program is free software. It comes without any warranty, to
; the extent permitted by applicable law. You can redistribute it
; and/or modify it under the terms of the Do What The Fuck You Want
; To Public License, Version 2, as published by Sam Hocevar. See
; http://sam.zoy.org/wtfpl/COPYING for more details.

.module	Utility


;====== Math Routines ==========================================================
;------ Milos Bazelides routines -----------------------------------------------
; These routines are by Milos "baze" Bazelides, baze_at_baze_au_com
; Retrived from http://baze.au.com/misc/z80bits.html 25 October 2008
#ifdef	NEVER
MultHByE:
; Standard optimized 8-bit multiply.
; Input: H = Multiplier, E = Multiplicand
; Output: HL = Product
	xor	a
	ld	l, a
	ld	d, a
	sla	h		; optimised 1st iteration
	jr	nc,$+3
	ld	l,e
	;
	ld	b, 7
multHbyEloop:
	add	hl,hl		; unroll 7 times
	jr	nc,$+3		; ...
	add	hl,de		; ...
	djnz	multHbyEloop
	ret
#endif


;------ DivHLByC ---------------------------------------------------------------
DivHLByC:
; 16-bit by 8-bit divide
; Inputs:
;  - HL: Dividend
;  - C: Divisor
; Outputs:
;  - HL: Quotient
;  - A: Remainder
; Destroys:
;  - B
	xor	a
	ld	b, 16
_dhlcl:
	add	hl,hl		; unroll 16 times
	rla			; ...
	cp	c		; ...
	jr	c,$+4		; ...
	sub	c		; ...
	inc	l		; ...
	djnz	_dhlcl
	ret


#ifdef	NEVER
;------ DivEHLByD --------------------------------------------------------------
DivEHLByD:
; 24-bit by 8-bit divide
; Inputs:
;  - EHL: Dividend
;  - D: Divisor
; Outputs:
;  - EHL: Quotient
;  - A: Remainder
; Destroys:
;  - B
	xor	a
	ld	b, 24
_dehld:	add	hl,hl		; unroll 24 times
	rl	e		; ...
	rla			; ...
	cp	d		; ...
	jr	c,$+4		; ...
	sub	d		; ...
	inc	l		; ...
	djnz	_dehld
	ret
#endif


;------ DivACByDE --------------------------------------------------------------
DivACByDE:
; 16-bit by 16-bit divide
; Inputs:
;  - A:C: Dividend
;  - DE: Divisor
; Outputs:
;  - A:C: Quotient
;  - HL: Remainder
; Destroys:
;  - AF
;  - BC
	ld	hl, 0
	ld	b, 16
@:	sll	c
	rla
	adc	hl, hl
	sbc	hl, de
	jr	nc, $ + 4
	add	hl, de
	dec	c
	djnz	{-1@}
	ret


;------ DispHL & DispByte ------------------------------------------------------
DispHL:
; Displays HL in hex.
; Input:
;  - HL
; Output:
;  - Word displayed
; Destroys:
;  - AF
	ld	a, h
	call	DispByte
	ld	a, l
DispByte:
; Display A in hex.
; Input:
;  - A: Byte
; Output:
;  - Byte displayed
; Destroys:
;  - AF
	push	af
	rra
	rra
	rra
	rra
	call	_dba
	pop	af
_dba:	or	0F0h
	daa
	add	a, 0A0h
	adc	a, 40h
	call	PutC
;	b_call(_PutC)
	ret


;------ DispDecimal ------------------------------------------------------------
DispDecimal:
; Displays HL in decimal.
; Input:
;  - HL
; Output:
;  - 16-bit number displayed in decimal
; Destroys:
;  - HL
;  - BC
;  - AF
	bit	7, h
	jr	z, {@}
	ld	a, h
	cpl
	ld	h, a
	ld	a, l
	cpl
	ld	l, a
	ld	bc, 1
	add	hl, bc
	ld	a, '-'
	call	PutC
@:	ld	bc, 10000
	cpHlBc
	jr	nc, _dd4
	ld	bc, 1000
	cpHlBc
	jr	nc, _dd3
	ld	bc, 100
	cpHlBc
	jr	nc, _dd2
	ld	bc, 10
	cpHlBc
	ld	b, 0FFh
	jr	nc, _dd1
	jr	_dd0	
_dd4	ld	bc, -10000
	call	_dda
_dd3	ld	bc, -1000
	call	_dda
_dd2	ld	bc, -100
	call	_dda
_dd1	ld	c, -10
	call	_dda
_dd0	ld	c,b
_dda:	ld	a,'0'-1
_ddb:	inc	a
	add	hl,bc
	jr	c, _ddb
	sbc	hl,bc
	call	PutC
	ret


;------ ShowHexDump ------------------------------------------------------------
ShowHexDump:
; Shows some hex data, shows the value of certain variables, and highlights them
; if in the hex dump.
; Inputs:
;  - C: Number of LINES to show
;     - 8 bytes per line with large font
;     - 16 bytes per line with small font
;  - IX: Address of data to show
;  - IY: Ptr to vars list
;     - .db numberOfVars
;     - .dw var1LabelStr
;     - .dw var1Ptr
;     - .dw var2LabelStr
;     - .dw var2Ptr
;     - &c.
; Outputs:
;  - Documented effects
; Destroys:
;  - AF
;  - BC
;  - DE
;  - HL
;  - IX
;  - IY
;	call	ClearWind
	call	HomeUp
	call	ToggleInverse
	ld	hl, _dumpHeader
	call	PutS
;	ld	e, ixl
;	dec	e
	ld	e, 255
.ifndef	SMALL_FONT
	ld	b, 8
.else
	ld	b, 16
.endif
@:	ld	a, ' '
	call	PutC
	ld	a, e
	inc	a
;	and	15
	ld	e, a
	call	DispByte
	djnz	{-1@}
	call	ToggleInverse
_showDataLineLoop:
	push	ix
	pop	hl
	call	DispHL
	ld	a, ':'
	call	PutC
.ifndef	SMALL_FONT
	ld	b, 8
.else
	ld	b, 16
.endif
_showDataByteLoop:
	ld	a, ' '
	call	PutC
	push	iy
	ld	d, 0
	ld	a, (iy)
	inc	iy
	or	a
	jr	z, _showDataNoHighlight
	push	ix
	pop	de
_showDataByteCheckHighlightLoop:
	inc	iy
	inc	iy
	ld	l, (iy)
	inc	iy
	ld	h, (iy)
	inc	iy
	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a
	or	a
	sbc	hl, de
	jr	z, {@}
	dec	a
	jr	nz, _showDataByteCheckHighlightLoop
	ld	d, 0
	jr	_showDataNoHighlight
@:	ld	hl, flags + mTextFlags
	call	ToggleInverse
	ld	d, 1
_showDataNoHighlight:
	pop	iy
	ld	a, (ix)
	inc	ix
	call	DispByte
	ld	hl, flags + mTextFlags
	bit	0, d
	call	nz, ToggleInverse
	djnz	_showDataByteLoop
.ifndef	SMALL_FONT
	call	NewLine
.endif
	dec	c
	jr	nz, _showDataLineLoop
	ld	a, (iy)
	or	a
	jr	z, {2@}
	ld	e, a
	inc	iy
@:	ld	l, (iy)
	inc	iy
	ld	h, (iy)
	inc	iy
	call	PutS
	ld	l, (iy)
	inc	iy
	ld	h, (iy)
	inc	iy
;	push	hl
;	call	DispHL
;	ld	a, ':'
;	call	PutC
;	pop	hl
	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a
	call	DispHL
	call	NewLineClrEOL2
	dec	e
	jr	nz, {-1@}
@:	call	FinishClearWind
	ret
_dumpHeader:
	.db	"     ", 0
.ifdef	NEVER
;.ifndef	SMALL_FONT
	.db	"      00 01 02 03 04 05 06 07", chNewLine, 0
;.else
;	.db	"      00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F", 0
	.db	(' ' | 80h), (' ' | 80h), (' ' | 80h), (' ' | 80h), (' ' | 80h), (' ' | 80h)
	.db	('0' | 80h), ('0' | 80h), (' ' | 80h), ('0' | 80h), ('1' | 80h), (' ' | 80h)
	.db	('0' | 80h), ('2' | 80h), (' ' | 80h), ('0' | 80h), ('3' | 80h), (' ' | 80h)
	.db	('0' | 80h), ('4' | 80h), (' ' | 80h), ('0' | 80h), ('5' | 80h), (' ' | 80h)
	.db	('0' | 80h), ('6' | 80h), (' ' | 80h), ('0' | 80h), ('7' | 80h), (' ' | 80h)
	.db	('0' | 80h), ('8' | 80h), (' ' | 80h), ('0' | 80h), ('9' | 80h), (' ' | 80h)
	.db	('0' | 80h), ('A' | 80h), (' ' | 80h), ('0' | 80h), ('B' | 80h), (' ' | 80h)
	.db	('0' | 80h), ('C' | 80h), (' ' | 80h), ('0' | 80h), ('D' | 80h), (' ' | 80h)
	.db	('0' | 80h), ('E' | 80h), (' ' | 80h), ('0' | 80h), ('F' | 80h)
	.db	0
.endif


;------ ------------------------------------------------------------------------
.ifdef	NEVER
;------ DispA ------------------------------------------------------------------
DispA:
; Displays A as a decimal, without zero-padding.
; Input:
;  - A
; Output:
;  - Number displayed at current cursor location.
; Destroys:
;  - C
	cp	10
	jr	c, _dda2
	cp	100
	jr	c, _dda0
	ld	c, 2
	sub	200
	jr	nc, _dda3
	dec	c
	add	a, 100
_dda3:	push	af
	ld	a, c
	call	_dda2
	pop	af
_dda0:	ld	c, -1
_dda1:	inc	c
	sub	10
	jr	nc, _dda1
	add	a, 10
	push	af
	ld	a, c
	call	_dda2
	pop	af
_dda2:	add	a, '0'
	jp	PutC
.endif


;====== Routines ===============================================================

;------ CompareStrings ---------------------------------------------------------
CompareStrings:
; Checks if two null terminated strings are identical.
; Input:
;  - HL: String 1
;  - DE: String 2
;  - B: Maximum string length
; Output:
;  - NZ if strings unequal
;  - Z if strings are identical
;  - If string are identical, HL and DE point to byte after zero
; Destroys:
;  - A
;  - B
;  - DE
;  - HL
	ld	a, (de)
	cp	(hl)
	ret	nz
	inc	hl
	inc	de
	or	a
	ret	z
	djnz	CompareStrings
	xor	a
	inc	a
	ret


#ifdef	NEVER
;------ ClearMem ---------------------------------------------------------------
ClearMem:
; Clears a section of memory SLOW! :p
; Input:
;  - HL: Location to kill
;  - B: Number of bytes to kill
;  - A: What to clear it with
	ld	(hl), a
	inc	hl
	djnz	ClearMem
	ret
#endif


;------ GetStrIndexed ----------------------------------------------------------
GetStrIndexed:
; Given an index into a table of ZTSs, this finds the specified string
; Inputs:
;  - A: Index
;  - HL: Pointer to table
; Output:
;  - HL: Pointer to selected string
	or	a
	ret	z
	push	bc
	ld	b, a
	xor	a
_gsia:	cp	(hl)
	inc	hl
	jr	nz, _gsia
	djnz	_gsia
	pop	bc
	ret


;------ GetStrLength -----------------------------------------------------------
GetStrLength:
; Finds the null terminator in a string.
; Input:
;  - HL: Ptr to string
; Output:
;  - HL: Length
;  - DE: Ptr to string
; Destroys:
;  - BC
	ld	bc, 0
	xor	a
	ld	e, l
	ld	d, h
	cpir
	or	a
	sbc	hl, de
	ret


;------ MapTable ---------------------------------------------------------------
MapTable:
; Scans a table mapping an input in A to an output in B.
; Input:
;  - HL: Pointer to struct specifying entries in real table and table address.
; Outputs:
;  - B: Code
;  - NZ on failure
; Destroys:
;  - HL
	ld	b, (hl)
	inc	hl
_mtl:	cp	(hl)
	inc	hl
	jr	z, _mtd
	inc	hl
	djnz	_mtl
	inc	b
	ret
_mtd:	ld	b, (hl)
	cp	a
	ret


;------ DispHeaderText ---------------------------------------------------------
DispHeaderText:
; Displays a string, centered, in inverse text.
; Input:
;  - HL: Ptr to string
; Outputs:
;  - HL: Byte after null
; Destroys:
;  - AF
;  - BC
;  - DE
	call	GetStrLength
	ex	de, hl
;	ld	a, textCols / 2 - 1
	ld	a, (windLeft)
	ld	b, a
	ld	a, (windRight)
	sub	b
	srl	a
	dec	a
	srl	e
	sub	e
	ld	b, a
	call	PutSpaces
	call	ToggleInverse
	call	PutSpace
	call	PutS
	call	PutSpace
	call	ToggleInverse
	jp	NewLineClrEOL


;------ Menu -------------------------------------------------------------------
Menu:
; Simple menu routine.
; HL points to a data structure that describes the menu.
; The first item in the menu is a zero-termed string to be displayed.
; After that, there is a list of acceptable keys and jump addresses.
; This is a JUMP not a CALL!
; This passes the key that was pressed in B.
	call	HomeUp
	call	DispHeaderText
	call	PutSClrWind ; hl = byte after 0
	push	hl
	pop	ix
menuKeyLoop:
	call	GetKey
	push	ix
	pop	hl
	ld	b, a
	ld	a, (hl)
	or	a
	jp	z, Quit
@:	; Key table scan loop
	ld	a, (hl)
	inc	hl
	or	a
	jr	z, menuKeyLoop
	cp	b
	jr	z, {@}
	inc	hl
	inc	hl
	jr	{-1@}
@:	; Found an entry!
	; Is it a link to another menu?
	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a
	ld	a, (hl)
	or	a
	jr	z, {@}
	jp	(hl)
@:	; Yes, it's linking to another menu.
	inc	hl
	jr	Menu


.ifdef	NEVER
;------ CallHLIndirect ---------------------------------------------------------
CallHLIndirect:
; Calls (HL), unless (HL) is NULL.
; If (HL) is NULL, the routine returns without calling.
; Input:
;  - HL: Pointer to pointer to routine
; Output:
;  - Routine called
; Destroys:
;  - Whatever the callee destroys
	push	af
	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a
	or	h
	jr	z, {@}
	pop	af
	jp	(hl)
@:	pop	af
	ret
.endif


;------ CallHL -----------------------------------------------------------------
CallHL:
; Calls HL, unless HL is NULL.
; Input:
;  - HL: Address to call
; Output:
;  - Just take a wild guess
; Destroys:
;  - ???
;  - MAYBE THE WHOLE UNIVERSE
	push	af
	ld	a, h
	or	a
	jr	z, {@}
	pop	af
CallHLNoCheck:
	jp	(hl)
@:	pop	af
	ret


.ifdef	NEVER
;------ CallAddressOnStack -----------------------------------------------------
CallAddressOnStack:
; Calls the address you have pushed onto the stack, preserving HL.
; Inputs:
;  - The address to call is pushed onto the stack before CALLing this function
;  - Any registers to use as arguments
; Output:
;  - Function is called, all registers are preserved
; Destroys:
;  - Flags
	push	ix	; ix + 3, ix + 2		; 15
	push	bc	; ix + 1, ix + 0		; 11
	ld	ix, 0					; 14
	add	ix, sp					; 15
	ld	c, (ix + 4)				; 19
	ld	b, (ix + 6)				; 19
	ld	(ix + 6), c				; 19
	ld	(ix + 4), b				; 19
	ld	c, (ix + 5)				; 19
	ld	b, (ix + 7)				; 19
	ld	(ix + 7), c				; 19
	ld	(ix + 5), b				; 19
	pop	bc					; 10
	pop	ix					; 14
	ret						; 10
	; 241 cc (258 including the CALL you made to call this function)
.endif


.ifdef	NEVER
;------ CallHLWithHLLoadedFromStack --------------------------------------------
CallHLWithHLLoadedFromStack:
; Calls function at HL, but before calling, loads HL from the value you pushed
; onto the stack.
; Inputs:
;  - HL: Ptr to function
;  - Value to use for as argument to function pushed onto stack
; Output:
;  - Function is called, all registers and flags are preserved
; Destroys:
;  - Nothing
	push	ix	; ix + 3, ix + 2		; 15
	push	af	; ix + 1, ix + 0		; 11
	ld	ix, 0					; 14
	add	ix, sp					; 15
	ld	a, (ix + 4)				; 19
	ld	(ix + 4), l				; 19
	ld	l, (ix + 6)				; 19
	ld	(ix + 6), a				; 19
	ld	a, (ix + 5)				; 19
	ld	(ix + 5), h				; 19
	ld	h, (ix + 7)				; 19
	ld	(ix + 7), a				; 19
	pop	af					; 10
	pop	ix					; 14
	ret						; 10
	; 241 cc (258 including the CALL you made to call this function)
.endif


.ifdef	NEVER
;------ SavePage ---------------------------------------------------------------
SavePage:
; Saves the current page in the swap bank onto the stack.
; Inputs:
;  - None
; Output:
;  - Page on stack
; Destroys:
;  - AF
;  - HL
	in	a, (pSwapBank)
	ld	l, a
	in	a, (pSwapBankHigh)
	ld	h, a
	ex	(sp), hl
	jp	(hl)


;------ RestorePage ------------------------------------------------------------
RestorePage:
; Restores the page mapping saved onto the stack
; Inputs:
;  - None
; Output:
;  - Page on stack
; Destroys:
;  - AF
;  - HL
	pop	hl
	ex	(sp), hl
	ld	a, l
	out	(pSwapBank), a
	ld	a, h
	out	(pSwapBankHigh), a
	ret
.endif


;------ PutByte ----------------------------------------------------------------
PutByte:
; Writes a byte to RAM.  If HL is in the swapping range, B is assumed to be a
; RAM page.  (If B >= 80h, it WILL write to a RAM page, even if you intended B
; to be a flash page.)
; Inputs:
;  - A: Byte to write
;  - BHL: Location to write to
; Outputs:
;  - None
; Destroys:
;  - Flags
	push	bc
	push	hl
	ld	c, pSwapBank
	in	l, (c)
	ex	(sp), hl
	out	(c), b
	ld	(hl), a
	ex	(sp), hl
	out	(c), l
	pop	hl
	pop	bc
	ret


;------ GetByte ----------------------------------------------------------------
GetByte:
; Gets a byte from any page.  Page is RAM if Page >= F0h
; Inputs:
;  - BHL: Ptr to byte to get
; Output:
;  - A: Byte
; Destroys:
;  - Flags
	push	hl
	in	a, (pSwapBank)
	ld	l, a
	in	a, (pSwapBankHigh)
	ld	h, a
	ex	(sp), hl
	ld	a, b
	cp	0F0h
	jr	nc, {@}
	rlca
	out	(pSwapBankHigh), a
	srl	a
@:	out	(pSwapBank), a
	ld	a, (hl)
	ex	(sp), hl
	push	af
	ld	a, l
	out	(pSwapBank), a
	ld	a, h
	out	(pSwapBankHigh), a
	pop	af
	pop	hl
	ret
.ifdef	NEVER
	push	bc
	push	hl
	ld	c, pSwapBank
	in	l, (c)
	set	2, c
	in	h, (c)
	ex	(sp), hl
	ld	a, b
	cp	0F0h
	jr	nc, {@}
	rlca
	out	(c), a
	srl	a
@:	out	(pSwapBank), a
	ld	a, (hl)
	ex	(sp), hl
	out	(c), h
	res	2, c
	out	(c), a
	pop	hl
	pop	bc
	ret
.endif


;------ InvokeCallBack ---------------------------------------------------------
InvokeCallBack:
; Calls the 3-byte call back pointed to by IX if the high byte of the call back
; address is not zero.
; Input:
;  - IX: Pointer to call back
; Output:
;  - Call back called
;  - All registers from call back are preserved
;  - No way to know if call back wasn't called
; Destroys:
;  - IX
; TODO:
;  - The version below is suitable for use in a library app
	push	hl
	push	af
	ld	l, (ix + 0)
	ld	h, (ix + 1)
	push	hl
	pop	ix
	ld	a, h
	or	a
	jr	z, {@}
	pop	af
	pop	hl
	jp	(ix)
@:	pop	af
	pop	hl
	ret

.ifdef	NEVER
	push	hl
	push	af
	in	a, (pSwapBank)
	ld	l, a
	in	a, (pSwapBankHigh)
	ld	h, a
	pop	af
	ex	(sp), hl
	push	hl
	ld	hl, _icretpoint
	ex	(sp), hl
	push	hl
	push	af
	ld	a, (ix + 2)
	cp	0F0h
	jr	nc, {@}
	rlca
	out	(pSwapBankHigh), a
	srl	a
@:	out	(pSwapBank), a
	ld	l, (ix + 0)
	ld	h, (ix + 1)
	ld	a, l
	or	a
	jr	z, {@}
	push	hl
	pop	ix
	pop	af
	pop	hl
	jp	(ix)
@:	pop	af
	pop	hl
_icretpoint:
	ex	(sp), hl
	push	af
	ld	a, l
	out	(pSwapBank), a
	ld	a, h
	out	(pSwapBankHigh), a
	pop	af
	pop	hl
	ret
.endif

.ifdef	NEVER
	push	hl
	push	af
	in	a, (pSwapBank)
	ld	l, a
	in	a, (pSwapBankHigh)
	ld	h, a
	pop	af
	ex	(sp), hl
	push	hl
	ld	hl, _icretpoint
	ex	(sp), hl
	push	hl
	push	af
	inc	hl
	inc	hl
	ld	a, (hl)
	cp	0F0h
	jr	nc, {@}
	rlca
	out	(pSwapBankHigh), a
	srl	a
@:	out	(pSwapBank), a
	dec	hl
	ld	a, (hl)
	dec	hl
	ld	l, (hl)
	ld	h, a
	or	a
	jr	z, {@}
	push	hl
	pop	ix
	pop	af
	pop	hl
	jp	(ix)
@:	pop	af
	pop	hl
_icretpoint:
	ex	(sp), hl
	push	af
	ld	a, l
	out	(pSwapBank), a
	ld	a, h
	out	(pSwapBankHigh), a
	pop	af
	pop	hl
	ret
.endif
.ifdef	NEVER
	push	hl
	push	af
	in	a, (pSwapBank)
	ld	l, a
	in	a, (pSwapBankHigh)
	ld	h, a
	pop	af
	ex	(sp), hl
	push	hl
	ld	hl, _icretpoint
	ex	(sp), hl
	inc	hl
	inc	hl
	push	af
	ld	a, (hl)
	cp	0F0h
	jr	nc, {@}
	rlca
	out	(pSwapBankHigh), a
	srl	a
@:	out	(pSwapBank), a
	dec	hl
	ld	a, (hl)
	dec	hl
	ld	l, (hl)
	ld	h, a
	or	a
	jr	z, {@}
	pop	af
	jp	(hl)
@:	pop	af
_icretpoint:
	ex	(sp), hl
	push	af
	ld	a, l
	out	(pSwapBank), a
	ld	a, h
	out	(pSwapBankHigh), a
	pop	af
	pop	hl
	ret
.endif


.ifdef	NEVER
;------ InvokeCallBackWithAFHL -------------------------------------------------
InvokeCallBackWithAFHL:
; Invokes the call back pointed to by HL, preserving AF and passing the value on
; the stack in HL.
; Inputs:
;  - HL: Ptr to callback
;     - If high byte of callback address is zero, it is not called.
;  - Value on stack: Passed in HL to function
; Outputs:
;  - Call back called
			; ix + 11, ix + 10	value to pass in HL
			; ix + 9, ix + 8	original return address
	push	af	; ix + 7, ix + 6	original page mapping
	push	af	; ix + 5, ix + 4	stack frame ptr
	push	af	; ix + 3, ix + 2	callback address
	push	ix	; ix + 1, ix + 0	original ix
	ld	ix, 0
	add	ix, sp
	push	af	; ix - 1, ix - 2	original AF
	in	a, (pSwapBank)
	ld	(ix + 6), a
	in	a, (pSwapBankHigh)
	ld	(ix + 7), a
	ld	a, (hl)
	inc	hl
	ld	(ix + 2), a
	ld	a, (hl)
	inc	hl
	ld	(ix + 3), a
	or	a
	jr	z, _icnocall
	ld	a, (hl)
	cp	0F0h
	jr	nc, {@}
	rlca
	out	(pSwapBankHigh), a
	srl	a
@:	out	(pSwapBank), a
	ld	a, ixl
	ld	(ix + 4), a
	ld	a, ixh
	ld	(ix + 5), a
	ld	l, (ix + 10)
	ld	h, (ix + 11)
	pop	af
	pop	ix
	ret
_icnocall:
	pop	af
	pop	de
	pop	ix
	inc	sp
	inc	sp
	inc	sp
	inc	sp
	inc	sp
	inc	sp
	ret
_retPoint:
	ex	(sp), ix
	push	af
	ld	a, (ix + 6)
	out	(pSwapBank), a
	ld	a, (ix + 7)
	out	(pSwapBankHigh), a
	pop	af
	pop	ix
	inc	sp
	inc	sp
	ret
.endif


;------ ------------------------------------------------------------------------
.endmodule