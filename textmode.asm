; This program is free software. It comes without any warranty, to
; the extent permitted by applicable law. You can redistribute it
; and/or modify it under the terms of the Do What The Fuck You Want
; To Public License, Version 2, as published by Sam Hocevar. See
; http://sam.zoy.org/wtfpl/COPYING for more details.

; The text-mode driver has the following features:
;  - RAM-free character buffer: You can read back what characters are on-screen
;    despite the lack of a RAM-based character buffer.  This is because PutC
;    encodes that information directly into the pixels written to the screen.
;  - Text window: All routines automatically wrap when the cursor reaches the
;    left or bottom bound of the currently defined window.
;  - No scrolling: I'm lazy
;  - 4 tab stops: For each formatting of output data
; 
; You must call ResetScreen first before using any of these functions.

;Memory: currentRow, currentCol
;windLeft, windRight, windTop, windBottom
;tab1, tab2, tab3, tab4
;Flags: Inverse

; Functions:
; SetFullScrnWind
;  - Resets the window to one in which everything is full-screen
; ClearWind
;  - Clears the current window by printing lots of spaces.
; PutSClrWind
;  - Displays a string.  If the string contains control codes, those codes are
;    parsed.  New lines will print spaces until the end of the line.
; PutS
;  - Displays a string.  If the string contains control codes, those codes are
;    parsed.
; Locate
;  - Moves the cursor to a specific location.
; HomeUp
;  - Moves the text cursor up to the top, left of the text window.
; CursorBack
;  - Moves the cursor back one unit.  May move to the rightmost position of the
;    previous line.  May also move to bottom-right of window if cursor was
;    previously at top-left.
; CursorForward
;  - Moves the cursor forward one unit.
; CursorRight
;  - Moves the cursor right, but does not allow the cursor to move past the right-
;    most edge of the window.
; CursorLeft
;  - Moves the cursor left, but does not allow the cursor to move past the left-
;    most edge of the window.
; CursorDown
;  - Moves the cursor down one row, but won't move down past the bottom of the
;    window.
; CursorUp
;  - Moves the cursor upone row, but won't move down past the top of the window.
; AdvanceCursor
;  - After a function like PutSpace or PutC has draw the character, this updates
;    the text cursor to match.  This may trigger advancing to a new line.
; NewLine
;  - Advances the cursor to the next line.
; NewLineClrEOL
;  - Moves the cursor to the next line, clearing the remainder of the current line.
; NewLine2
;  - Moves the cursor to the next line, unless it is already at the start of a new
;    line.  Useful if you want to display data all the way up to the last column.
; NewLineClrEOL2
;  - Moves the cursor to the next line, clearing the remainder of the current line,
;    unless the cursor is already at the start of a new line.  
;    Useful if you want to display data all the way up to the last column.
; NextTab
;  - Moves the cursor forward to the next tab position.
; PutSpace
;  - Draws a single blank cell to the screen.
; PutSpaces
;  - Sends several spaces to the screen.
; PutC2
;  - Displays the character given, just like PutC.  However, this checks bit 7 to
;    see whether the character should be displayed in inverse mode or not.
;    If inverse mode is set in textFlags, then the meaning of bit 7 is reversed;
;    that is, it inverts the inversion.
; PutC
;  - Draws a character to the screen.
; ReadChar
;  - Reads the character code of the character currently under the cursor.
;    WARNING: The LCD cursor is not reset!
;    To advance to next character location, call SetCharCol AND SetCharRow to reset
;    to previous value.  If you want to advance to the next location, call
;    AdvanceCursor.
; ResetScreen
;  - Initializes the screen modes and text control variables.  This must be the
;    first thing you call for text mode.
; FixCursor
;  - Fixes up the LCD read/write cursor
; SetCharRow
;  - Sets the LCD window top and bottom for the current row of text.
; SetCharCol
;  - Sets the LCD write cursor column to match currentCol
; SetLcdWindowColumnBounds
;  - Sets the LCD window left/right bounds.
;    These should be 0 and 314, because MicrOS rarely needs to keep writing to the
;    same char location.
; SetDirectionRight
;  - Sets the cursor to move left after every pixel.  At the end of the row, it
;    then moves down;
; SetDirectionDown
;  - Sets the cursor to move down after every pixel.  At the end of the column, it
;    then moves right.



.module Text

;------ SetFullScrnWind --------------------------------------------------------
SetFullScrnWind:
; Resets the window to one in which everything is full-screen
; Inputs:
;  - None
; Output:
;  - Window set
; Destroys:
;  - BC
	ld	bc, 0
	ld	(windTop), bc
	ld	bc, ((textCols - 0) * 256) + textRows
	ld	(windBottom), bc
	ret


;------ ClearWind --------------------------------------------------------------
ClearWind:
; Clears the current window by printing lots of spaces.
; Input:
;  - Window bounds
; Output:
;  - Window cleared and cursor moved to top left
; Destroys:
;  - Assume everything
	call	HomeUp
@:	call	NewLineClrEOL
	ld	a, (windTop)
	ld	b, a
	ld	a, (currentRow)
	cp	b
	jr	nz, {-1@}
	jp	HomeUp


;------ FinishClearWind --------------------------------------------------------
FinishClearWind:
; Clears the rest of the current window past the cursor.  However, it clears
; nothing if the cursor is at the window origin.
; Input:
;  - Window bounds
; Output:
;  - Window cleared, cursor moved to top left
; Destroys:
;  - Assume all
	ld	a, (windTop)
	ld	b, a
	ld	a, (currentRow)
	cp	b
	jr	nz, {-1@}
	ld	a, (windLeft)
	ld	b, a
	ld	a, (currentCol)
	cp	b
	jr	nz, {-1@}
	ret


;------ PutSClrWind ------------------------------------------------------------
PutSClrWind:
; Displays a string.  If the string contains control codes, those codes are
; parsed.  New lines will print spaces until the end of the line.
; Input:
;  - HL: String to show
; Output:
;  - String shown
;  - HL advanced to the byte after the null terminator.
; Destroys:
;  - AF
	push	bc
putSClrWindLoop:
	ld	a, (hl)
	inc	hl
	cp	ch1stPrintableChar
	call	nc, PutC
	jr	nc, putSClrWindLoop
	or	a
	jr	z, putSClrWindFillToEnd
	cp	chNewLine
	jr	nz, {@}
	call	NewLineClrEOL
	jr	putSClrWindLoop
@:	cp	chTab
	call	z, NextTab
	jr	putSClrWindLoop	; Just display spaces until the last column of the last line
putSClrWindFillToEnd:
	push	de
	push	hl
	ld	a, (windTop)
	ld	b, a
	ld	a, (currentRow)
	cp	b
	jr	nz, {@}
	ld	a, (windLeft)
	ld	b, a
	ld	a, (currentCol)
	cp	b
	jr	z, putSClrWindRet
@:	call	NewLineClrEOL
	ld	a, (windTop)
	ld	b, a
	ld	a, (currentRow)
	cp	b
	jr	nz, {-1@}
putSClrWindRet:
	call	HomeUp
	pop	hl
	pop	de
	pop	bc
	ret


;------ PutS -------------------------------------------------------------------
PutS:
; Displays a string.  If the string contains control codes, those codes are
; parsed.
; Input:
;  - HL: String to show
; Output:
;  - String shown
;  - HL advanced to the byte after the null terminator.
; Destroys:
;  - AF
	ld	a, (hl)
	inc	hl
	cp	ch1stPrintableChar
	call	nc, PutC
	jr	nc, PutS
	or	a
	ret	z
	push	bc
	push	de
	push	hl
	cp	chNewLine
	jr	nz, {@}
	call	NewLine
	jr	{2@}
@:	cp	chTab
	call	z, NextTab
@:	pop	hl
	pop	de
	pop	bc
	jr	PutS


;------ Locate -----------------------------------------------------------------
Locate:
; Moves the cursor to a specific location in the current window.
; Inputs:
;  - H: Column
;  - L: Row
; Output:
;  - Cursor moved
; Destroys:
;  - Nothing
	push	af
	push	bc
	push	de
	push	hl
	ld	de, (windTop)
;	res	7, h
	add	hl, de
	ld	(currentRow), hl
	call	SetCharRow
	call	SetCharCol
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret


;------ LocateAbsolute ---------------------------------------------------------
LocateAbsolute:
; Moves the cursor to a specific location.
; Inputs:
;  - H: Column
;  - L: Row
; Output:
;  - Cursor moved
; Destroys:
;  - Nothing
	push	af
	push	bc
	push	de
	push	hl
	ld	(currentRow), hl
	call	SetCharRow
	call	SetCharCol
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret


;------ HomeUp -----------------------------------------------------------------
HomeUp:
; Moves the text cursor up to the top, left of the text window.
; Inputs:
;  - None
; Output:
;  - Cursor moved
; Destroys:
;  - A
	push	hl
	ld	hl, 0	
	call	Locate
	pop	hl
	ret

	
;------ CursorBack -------------------------------------------------------------
CursorBack:
; Moves the cursor back one unit.  May move to the rightmost position of the
; previous line.  May also move to bottom-right of window if cursor was
; previously at top-left.
; Input:
;  - Current cursor location
; Output:
;  - Cursor moved.
; Destroys:
;  - AF
;  - C
	ld	a, (currentCol)
	or	a
	jr	{@}
	ld	c, a
	ld	a, (windLeft)
	cp	c
	jr	z, {@}
	ld	a, c
	dec	a
	ld	(currentCol), a
	jp	SetCharCol
@:	ld	a, (windRight)
	ld	(currentCol), a
	ld	a, (currentRow)
	or	a
	ret	z
	ld	c, a
	ld	a, (windTop)
	cp	c
	;ret	z
	jr	nz, {@}
	ld	a, (windBottom)
	ld	c, a
@:	ld	a, c
	dec	a
	ld	(currentRow), a
	jp	FixCursor


;------ CursorForward ----------------------------------------------------------
CursorForward:
; Moves the cursor forward one unit.
; Input:
;  - Current cursor location
; Output:
;  - Cursor moved.
; Destroys:
;  - Whatever AdvanceCursor destorys.
;  - AF
	call	AdvanceCursor
	jp	FixCursor


;------ CursorRight ------------------------------------------------------------
CursorRight:
; Moves the cursor right, but does not allow the cursor to move past the right-
; most edge of the window.
; Input:
;  - Current cursor location
; Output:
;  - Cursor moved.
; Destroys:
;  - AF
;  - C
;  - HL
	ld	a, (windRight)
	ld	c, a
	ld	a, (currentCol)
	inc	a
	cp	c
	ret	nc
	ld	(currentCol), a
	jp	SetCharCol


;------ CursorLeft -------------------------------------------------------------
CursorLeft:
; Moves the cursor left, but does not allow the cursor to move past the left-
; most edge of the window.
; Input:
;  - Current cursor location
; Output:
;  - Cursor moved.
; Destroys:
;  - AF
;  - C
;  - HL
	ld	a, (windLeft)
	ld	c, a
	ld	a, (currentCol)
	or	a
	ret	z
	dec	a
	cp	c
	ret	c
	ld	(currentCol), a
	jp	SetCharCol


;------ CursorDown -------------------------------------------------------------
CursorDown:
; Moves the cursor down one row, but won't move down past the bottom of the
; window.
; Input:
;  - Current cursor location
; Output:
;  - Cursor moved.
; Destroys:
;  - AF
;  - BC
;  - E
	ld	a, (windBottom)
	ld	c, a
	ld	a, (currentRow)
	inc	a
	cp	c
	ret	nc
	ld	(currentRow), a
	jp	SetCharRow


;------ CursorUp ---------------------------------------------------------------
CursorUp:
; Moves the cursor upone row, but won't move down past the top of the window.
; Input:
;  - Current cursor location
; Output:
;  - Cursor moved.
; Destroys:
;  - AF
;  - BC
;  - E
	ld	a, (windTop)
	ld	c, a
	ld	a, (currentRow)
	or	a
	ret	z
	dec	a
	cp	c
	ret	c
	ld	(currentRow), a
	jp	SetCharRow


;------ AdvanceCursor ----------------------------------------------------------
AdvanceCursor:
; After a function like PutSpace or PutC has draw the character, this updates
; the text cursor to match.  This may trigger advancing to a new line.
; Inputs:
;  - None
; Output:
;  - Cursor advanced.
; Destroys:
;  - A
;  - B
	ld	a, (currentCol)
	inc	a
	ld	(currentCol), a
	ld	b, a
	ld	a, (windRight)
	cp	b
	jr	z, NewLine
	ret	nc


;------ NewLine ----------------------------------------------------------------
; Advances the cursor to the next line.
; Inputs:
;  - None
; Output:
;  - Cursor moved.
; Destroys:
;  - A
;  - B
NewLine:
	;ld	a, (mflags + textFlags)
	;bit	textNewlineClr, a
	;jp	nz, NewLineClrEOL
	ld	a, (windLeft)
	ld	(currentCol), a
	ld	a, (currentRow)
	inc	a
	ld	(currentRow), a
	ld	b, a
	ld	a, (windBottom)
	cp	b
	;jr	nc, +_
	jr	z, {@}
	jp	nc, FixCursor
@:	ld	a, (windTop)
	ld	(currentRow), a
;	ld	a, (mflags + textFlags)
;	bit	textAutoScroll, a
;	jp	nz, ScrollUp
	jp	FixCursor


;------ NewLineClrEOL ----------------------------------------------------------
NewLineClrEOL:
; Moves the cursor to the next line, clearing the remainder of the current line.
; Inputs:
;  - None
; Output:
;  - Cursor moved
; Destroys:
;  - AF
;  - BC
	push	hl
	push	de

;	ld	hl, 0FFFFh
;	inc	(hl)

@:	call	PutSpace
	
;	ld	a, (hl)
	
;	call	PutC
	
;	ld	a, 05Fh
;	call	PutC
	ld	a, (currentCol)
	ld	b, a
	ld	a, (windLeft)
	cp	b
	jr	nz, {-1@}
	pop	de
	pop	hl
	ret


;------ NewLine2 ---------------------------------------------------------------
NewLine2:
; Moves the cursor to the next line, unless it is already at the start of a new
; line.  Useful if you want to display data all the way up to the last column.
	ld	a, (currentCol)
	ld	b, a
	ld	a, (windLeft)
	cp	b
	jp	nz, NewLine
	ret


;------ NewLineClrEOL2 ---------------------------------------------------------
NewLineClrEOL2:
; Moves the cursor to the next line, clearing the remainder of the current line,
; unless the cursor is already at the start of a new line.  
; Useful if you want to display data all the way up to the last column.
; Inputs:
;  - None
; Output:
;  - Cursor moved
; Destroys:
;  - AF
;  - BC
	ld	a, (currentCol)
	ld	b, a
	ld	a, (windLeft)
	cp	b
	jp	nz, NewLineClrEOL
	ret


;------ NextTab ----------------------------------------------------------------
NextTab:
; Moves the cursor forward to the next tab position.
; Inputs:
;  - Tab array
;  - currentCol
; Output:
;  - Cursor advanced
; Destroys:
;  - Nothing
	push	af
	push	bc
	push	de
	push	hl
	ld	hl, currentCol
	ld	a, (hl)
	inc	hl
	ld	b, (hl)
	inc	hl
	cp	b
	jr	c, {@}
	ld	b, (hl)
	inc	hl
	cp	b
	jr	c, {@}
	ld	b, (hl)
	inc	hl
	cp	b
	jr	c, {@}
	ld	b, (hl)
	inc	hl
	cp	b
	jr	nc, tabRestoreRegisters
@:	ld	c, a
	ld	a, b
	sub	c
	ld	b, a
	call	PutSpaces
tabRestoreRegisters:
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret


;------ ToggleInverse ----------------------------------------------------------
ToggleInverse:
; Toggles the inverse text flag.
; Inputs:
;  - None
; Outputs:
;  - Documented effect(s)
; Destroys:
;  - AF
	ld	a, (flags + mTextFlags)
	xor	mTextInverseMask
	ld	(flags + mTextFlags), a
	ret


;------ PutSpace ---------------------------------------------------------------
PutSpace:
; Draws a single blank cell to the screen.
; Input:
;  - mTextInverse, (iy + textFlags)
; Output:
;  - Spaces written
; Destroys:
;  - A
;  - B
; Assumes:
;  - LCD window already set
;  - LCD write cursor already set
	; Tell it we want to write pixels
	ld	a, lrGram
	screenDi
	out	(pLcdCmd), a
	out	(pLcdCmd), a
	screenEi
	ld	b, (charWidth * charHeight) / 2
	ld	a, (flags + mTextFlags)
	bit	mTextInverse, a
	ld	a, 0	; Do not change to XOR A
	jr	z, {@}
	dec	a
	screenDi
@:	
.ifdef	USE_CHEAP_COLOR_TEXT
	and	TEXT_COLOR_VALUE
.endif
@:	out	(pLcdData), a
	out	(pLcdData), a
	out	(pLcdData), a
	out	(pLcdData), a
	djnz	{-1@}
	screenEi
	jp	AdvanceCursor


;------ PutSpaces --------------------------------------------------------------
PutSpaces:
; Sends several spaces to the screen.  This routine may cause scrolling if
; scrolling is enabled.
; Input:
;  - B: Number of space to display
; Output:
;  - Cursor moved, space erased.
; Destroys:
;  - AF
;  - B
	push	bc
	call	PutSpace
	pop	bc
	djnz	PutSpaces
	ret


;------ PutC -------------------------------------------------------------------
PutC:
; Displays the character given, just like PutCRaw.  However, this checks bit 7
; to see whether the character should be displayed in inverse mode or not.
; If inverse mode is set in mTextFlags, then the meaning of bit 7 is reversed;
; that is, it inverts the inversion.
; Inputs:
;  - A: Character
;  - 7,A: Set for inverse mode.
	push	af
	push	bc
	ld	b, a
	ld	a, (flags + mTextFlags)
	push	af
	ld	c, a
	and	mTextInverseMask^255
	bit	mTextInverse, c
	ld	a, 0
	jr	z, {@}
	xor	mTextInverseMask
@:	bit	7, b
	jr	z, {@}
	xor	mTextInverseMask
	res	7, b
@:	or	c
	ld	(flags + mTextFlags), a
	ld	a, b
	call	PutCRaw
	pop	af
	ld	(flags + mTextFlags), a
	pop	bc
	pop	af
	ret


;------ PutCRaw ----------------------------------------------------------------
PutCRaw:
; Draws a character to the screen.
; Input:
;  - A
;  - mTextInverse, (flags + mTextFlags): Set to invert bitmap
; Output:
;  - Character drawn
;  - Cursor advanced to next location
; Destroys:
;  - Nothing
; Assumes:
;  - LCD window already set
;  - LCD write cursor already set
; If you want to add color support, the best way to do that is probably to have
; H and L hold the foreground and background colors (assuming you don't feel
; the need for full 16-bit color in your text) and make IX the data pointer.
	push	af
	push	bc
	push	de
	push	hl
	ld	c, a
	xor	a
	; Sync
	screenDi
	out	(pLcdCmd), a
	out	(pLcdCmd), a
	out	(pLcdCmd), a
	out	(pLcdCmd), a
	; Tell it we want to write pixels
	ld	a, lrGram
	out	(pLcdCmd), a
	out	(pLcdCmd), a
	screenEi
	; If APD while displaying something, the screen will get confused
	ld	a, c
;	sub	minChar	; Not all 256 code points have bitmaps
;	jr	nc, +_
;	xor	a
;_:	; Multiply to get offset
	ld	l, a
	ld	h, 0
.ifndef	SMALL_FONT
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
.else
	ld	e, l
	ld	d, h
	add	hl, hl
	add	hl, de
	add	hl, hl
	add	hl, de
.endif
	ld	de, fontData
	add	hl, de
; Inital output: Write ASCII code
	; Set bit 7 in ASCII if inverse text is set
	ld	e, a
	ld	a, (flags + mTextFlags)
	ld	d, a
	ld	a, e
	bit	mTextInverse, d
	ld	d, 0
	jr	z, {@}
	or	80h
	ld	c, a
	dec	d
@:	ld	a, (hl)
	inc	hl
	;ld	b, 8
	xor	d	; inverse text support
	ld	e, a
;_:	; Output byte loop
.deflong PutCInitialOutput()
	rrc	e
	sbc	a, a
.ifdef	USE_CHEAP_COLOR_TEXT
	and	TEXT_COLOR_VALUE
.endif
	out	(pLcdData), a
	rrc	c
	jr	nc, {@}
	xor	20h
@:	out	(pLcdData), a
.enddeflong
;	djnz	--_
	; Let's optimize with loop unrolling!
	screenDi
	PutCInitialOutput()
	PutCInitialOutput()
	PutCInitialOutput()
	PutCInitialOutput()
	PutCInitialOutput()
	PutCInitialOutput()
	PutCInitialOutput()
	PutCInitialOutput()
	screenEi
; Main output loop
; B = bit loop counter
; C = byte loop counter
; D = inverse text flag
; E = text bitmap
; HL = ptr
;	ld	c, charLength-2
.if	(charWidth * charHeight) % 8 > 0
	ld	b, charLength - 2
.else
	ld	b, charLength - 1
.endif
PutMapOutLoop:
	ld	a, (hl)
	inc	hl
;	ld	b, 8
	xor	d	; inverse text support
	ld	e, a
;_:	; Output byte loop
.deflong PutCMainOutput()
	rrc	e
	sbc	a, a
.ifdef	USE_CHEAP_COLOR_TEXT
	and	TEXT_COLOR_VALUE
.endif
	out	(pLcdData), a
	out	(pLcdData), a
.enddeflong
;	djnz	-_
	; Unroll loop
	screenDi
	PutCMainOutput()
	PutCMainOutput()
	PutCMainOutput()
	PutCMainOutput()
	PutCMainOutput()
	PutCMainOutput()
	PutCMainOutput()
	PutCMainOutput()
	screenEi
;	dec	c
;	jr	nz, PutMapOutLoop
	djnz	PutMapOutLoop
; Remainder
.if	(charWidth * charHeight) % 8 > 0
	ld	a, (hl)
;	ld	b, 6
	xor	d	; inverse text support
	ld	e, a
;_:	; Output byte loop
;	rrc	e
;	sbc	a, a
;	out	(pLcdData), a
;	out	(pLcdData), a
;	djnz	-_
	screenDi
	PutCMainOutput()
.if	(charWidth * charHeight) % 8 > 1
	PutCMainOutput()
.endif
.if	(charWidth * charHeight) % 8 > 2
	PutCMainOutput()
.endif
.if	(charWidth * charHeight) % 8 > 3
	PutCMainOutput()
.endif
.if	(charWidth * charHeight) % 8 > 4
	PutCMainOutput()
.endif
.if	(charWidth * charHeight) % 8 > 5
	PutCMainOutput()
.endif
.if	(charWidth * charHeight) % 8 > 6
	PutCMainOutput()
.endif
.if	(charWidth * charHeight) % 8 > 7
	PutCMainOutput()
.endif
	screenEi
.endif
	call	AdvanceCursor
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret


;------ ReadChar ---------------------------------------------------------------
ReadChar:
; Reads the character code of the character currently under the cursor.
; WARNING: The LCD cursor is not reset!
; To advance to next character location, call SetCharCol AND SetCharRow to reset
; to previous value.  If you want to advance to the next location, call
; AdvanceCursor with textAutoScroll disabled.  (If it's enabled, calling
; AdvanceCursor could cause scrolling, which is probably not what you want since
; you're trying to READ non-destructively.)
; Inputs:
;  - Set LCD cursor to the correct location
; Output:
;  - A: 8-bit character code
; Destroys:
;  - LCD cursor
	push	bc
	push	de
	push	hl
	ld	c, pLcdData
	ld	b, 8
	ld	a, lrGram
	screenDi
	out	(pLcdCmd), a
	out	(pLcdCmd), a
@:	screenDi
	in	a, (pLcdData)
	in	a, (pLcdData)
	in	h, (c)
	in	a, (pLcdData)
	screenEi
	ld	l, a
	xor	h
	add	a, a
	add	a, a
	add	a, a
	rr	e
	out	(c), h
	out	(c), l
	djnz	{-1@}
	ld	a, e
	pop	hl
	pop	de
	pop	bc
	ret


;------ ResetScreen ------------------------------------------------------------
ResetScreen:
; Initializes the screen modes and text control variables.  This must be the
; first thing you call for text mode.
; Inputs:
;  - None
; Output:
;  - Everything ready for text mode
; Destroys:
;  - I dunno, assume everything.
	xor	a
	screenDi
	out	(pLcdCmd), a
	out	(pLcdCmd), a
	out	(pLcdCmd), a
	out	(pLcdCmd), a
	screenEi
	call	SetDirectionDown
	call	SetLcdWindowColumnBounds
	call	SetFullScrnWind
	jp	HomeUp


;------ FixCursor --------------------------------------------------------------
FixCursor:
; Fixes up the LCD read/write cursor
; Inputs:
;  - None
; Output:
;  - LCD window set
; Destroys:
;  - AF
	push	bc
	push	de
	push	hl
	call	SetCharCol
	call	SetCharRow
	pop	hl
	pop	de
	pop	bc
	ret


;------ SetCharRow -------------------------------------------------------------
SetCharRow:
; Sets the LCD window top and bottom for the current row of text.
; Inputs:
;  - None
; Output:
;  - LCD window set
; Destroys:
;  - AF
;  - BC
;  - E
	; Setup
	ld	b, lrWinTop
	ld	c, pLcdCmd
	; Set row
	ld	a, (currentRow)
.ifndef	SMALL_FONT
	; Multiply by 14
	add	a, a
	ld	e, a
	add	a, a
	add	a, a
	add	a, a
	sub	e
.else
	; Multiply by 9
	ld	e, a
	add	a, a
	add	a, a
	add	a, a
	add	a, e
.endif
	screenDi
	; And write it
	out	(c), b
	out	(c), b
	inc	c
	out	(c), 0
	out	(pLcdData), a
	dec	c
	; lrWinRowEnd
	inc	b
	out	(c), b
	out	(c), b
	add	a, charHeight-1
	inc	c
	out	(c), 0
	out	(pLcdData), a
	dec	c
	; lrRow
	ld	b, lrRow
	out	(c), b
	out	(c), b
	sub	charHeight-1
	inc	c
	out	(c), 0
	out	(pLcdData), a
	dec	c
	screenEi
	ret


;------ SetCharCol -------------------------------------------------------------
SetCharCol:
; Sets the LCD write cursor column to match currentCol
; Input:
;  - None
; Output:
;  - LCD window set
; Destroys:
;  - AF
;  - C
;  - HL
	; Set column
	ld	a, (currentCol)
.ifndef	SMALL_FONT
	; Multiply by 9
	ld	h, a
	add	a, a
	add	a, a
	add	a, a
	add	a, h
	ld	l, a
	ld	a, h
	cp	29
	sbc	a, a
	inc	a
	ld	h, a
.else
	; Multiply by 6
	ld	h, a
	add	a, a
	add	a, h
	add	a, a
	ld	l, a
	ld	a, h
	cp	43
	sbc	a, a
	inc	a
	ld	h, a
.endif
	ld	a, lrCol
	screenDi
	out	(pLcdCmd), a
	out	(pLcdCmd), a
	ld	a, h
	out	(pLcdData), a
	ld	a, l
	out	(pLcdData), a
;	dec	c
	; lrWinColStart
;	ld	h, a
;	ld	de, charWidth
;	add	hl, de
	; lrWinColEnd
;	inc	b
;	out	(c), 0
;	out	(c), b
;	inc	c
;	out	(c), h
;	out	(c), l
	screenEi
	ret


;------ SetLcdWindowColumnBounds -----------------------------------------------
; Sets the LCD window left/right bounds.
; These should be 0 and 314, because MicrOS rarely needs to keep writing to the
; same char location.
; Input:
;  - None
; Output:
;  - LCD left/right bounds reset
; Destroys:
;  - AF
; Assumes:
;  - Assumes that you want to be text mode.
; Execution Time:
;  - 134 cc not including inital CALL
SetLcdWindowColumnBounds:
	screenDi
	xor	a
	out	(pLcdCmd), a
	out	(pLcdCmd), a
	out	(pLcdCmd), a
	out	(pLcdCmd), a
	ld	a, lrWinLeft
	out	(pLcdCmd), a
	out	(pLcdCmd), a
	xor	a
	out	(pLcdData), a
	out	(pLcdData), a
	out	(pLcdCmd), a
	ld	a, lrWinRight
	out	(pLcdCmd), a
	ld	a, 1
	out	(pLcdData), a
	ld	a, lcdLow(((charWidth * textCols) - 1))
	out	(pLcdData), a
	ld	a, lrWinBottom
	out	(pLcdCmd), a
	out	(pLcdCmd), a
	xor	a
	out	(pLcdData), a
	ld	a, colorScrnHeight
	out	(pLcdData), a
	screenEi
	ret	;134 cc


;------ SetDirectionRight ------------------------------------------------------
SetDirectionRight:
; Sets the cursor to move left after every pixel.  At the end of the row, it
; then moves down;
; Inputs:
;  - None
; Output:
;  - Mode changed
; Destroys:
;  - AF
;  - H
	push	hl
	ld	a, lrEntryMode
	screenDi
	out	(pLcdCmd), a
	out	(pLcdCmd), a
	in	a, (pLcdData)
	ld	h, a
	in	a, (pLcdData)
	; Ignore the result
	ld	a, h
	out	(pLcdData), a
	ld	a, lcdCurMoveHoriz | lcdRowInc | lcdColInc
	out	(pLcdData), a
	pop	hl
	screenEi
	ret


;------ SetDirectionDown -------------------------------------------------------
SetDirectionDown:
; Sets the cursor to move down after every pixel.  At the end of the column, it
; then moves right.
; Inputs:
;  - None
; Output:
;  - Mode changed
; Destroys:
;  - AF
;  - H
	screenDi
	ld	a, lrEntryMode
	out	(pLcdCmd), a
	out	(pLcdCmd), a
	in	a, (pLcdData)
	ld	h, a
	in	a, (pLcdData)
	; Ignore the result
	ld	a, h
	out	(pLcdData), a
	ld	a, lcdRowInc | lcdColInc
	out	(pLcdData), a
	screenEi
	ret

.endmodule