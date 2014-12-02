; This program is free software. It comes without any warranty, to
; the extent permitted by applicable law. You can redistribute it
; and/or modify it under the terms of the Do What The Fuck You Want
; To Public License, Version 2, as published by Sam Hocevar. See
; http://sam.zoy.org/wtfpl/COPYING for more details.

; It might be nice to have a GetString routine at some point.  Whatever.

.module Keyboard

;------ GetAscii ---------------------------------------------------------------
GetAscii:
; Gets a single key press, with modifiers from mCursorFlags processed.  2nd and
; Alpha flags are reset, unless alpha-lock is enabled, in which case only 2nd is
; reset.
; Inputs:
;  - inputerFlags
; Outputs:
;  - ASCII char in B, might be a control char
;  - D: Cursor flags
;  - E: inputerFlags
; Destroys:
;  - Pretty much everything, most likely.
	ld	a, (flags + inputerFlags)
	and	allowAllMask
	ret	z
	call	GetKeyShifts
	; Test for A-Z
	bit	allowAlpha, e
	jr	z, getAsciiNum
	bit	cursorAlpha, d
	jr	z, getAsciiNum
	; Alpha A-Z
	ld	hl, textAlphaTable
	call	getAsciiScanTable
	jr	nz, {@}
	bit	allowLwrAlpha, e
	jr	z, ClearShiftFlags		; implicit return
	bit	cursorLwrAlpha, d
	jr	z, ClearShiftFlags		; implicit return
	; Alpha a-z
	ld	a, 20h
	add	a, b
	ld	b, a
	jr	ClearShiftFlags			; implicit return
@:	ld	hl, textAlphaSymbolTable
	bit	allowSymbols, e
	jr	z, GetAscii
	call	getAsciiScanTable
	jr	z, ClearShiftFlags		; implicit return
	jr	getAsciiControlChar
getAsciiNum:
	; Numbers 0-9
	ld	hl, textNumberSymbolTable
	bit	allowNumbers, e
	jr	z, getAsciiControlChar
	ld	hl, textNumberTable
	call	getAsciiScanTable
	jr	z, ClearShiftFlags		; implicit return
	ld	hl, textNumberSymbolTable
	bit	allowSymbols, e
	call	nz, getAsciiScanTable
	jr	z, ClearShiftFlags		; implicit return
getAsciiControlChar:
	bit	allowControl, e
	jr	z, GetAscii
	bit	cursor2nd, d
	jr	z, {@}
	ld	hl, text2ndControlCharTable
getAsciiCtrl:
	call	getAsciiScanTable
	jr	z, ClearShiftFlags		; implicit return
	jr	GetAscii
@:	bit	cursorAlpha, d
	jr	z, {@}
	ld	hl, textAlphaControlCharTable
	jr	getAsciiCtrl
@:	ld	hl, textControlCharTable
	jr	getAsciiCtrl

	
getAsciiScanTable:
; Scans a table mapping an input in A to an output in B.
; Input:
;  - HL: Pointer to struct specifying entries in real table and table address.
; Outputs:
;  - B: Code
;  - NZ on failure
; Destroys:
;  - C
;  - HL
	ld	b, (hl)
	inc	hl
	ld	c, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, c
@:	cp	(hl)
	jr	z, {@}
	inc	hl
	inc	hl
	djnz	{-1@}
	cp	b
	ret
@:	inc	hl
	ld	b, (hl)
	cp	a
	ret


;------ ClearShiftFlags --------------------------------------------------------
ClearShiftFlags:
; Clears 2nd and Alpha.  However, if Alpha Lock is on, alpha is not cleared.  If
; a special cursor is selected, it is not cleared.  See ClearAllShiftFlags for a
; routine to clear all shift flags.
; Inputs:
;  - None
; Output:
;  - Flags cleared
; Destroys:
;  - AF
	ld	a, (flags + mCursorFlags)
	bit	cursorOther, a
	ret	nz
	and	cursor2ndMask ^ 255
	ld	(flags + mCursorFlags), a
	bit	cursorALock, a
	ret	nz
	and	(cursorLwrAlphaMask | cursorAlphaMask) ^ 255
	ld	(flags + mCursorFlags), a
	ret


;------ ClearAllShiftFlags -----------------------------------------------------
ClearAllShiftFlags:
; Inputs:
;  - None
; Output:
;  - Flags cleared
; Destroys:
;  - AF
	ld	a, (flags + mCursorFlags)
	and	~(cursorALockMask | cursorLwrAlphaMask | cursorAlphaMask | cursor2ndMask | cursorInsertMask | cursorOtherMask)
	ld	(flags + mCursorFlags), a
	ret


;------ GetKeyShifts -----------------------------------------------------------
GetKeyShifts:
; Gets a single key press.  If the cursor is enabled, it will blink, and change
; according to shiftFlags.
; Input:
;  - mCursorFlags you want preset
; Output:
;  - Key code in A
;  - Flags
; Destroys:
;  - AF
;  - BC
;  - DE
;  - HL
getAsciiLoop:
;	di
;	ld	bc, (cursorTimerPeriod)
;	ld	(cursorTimer), bc
;	ei
	call	GetKey
	ld	l, a
	ld	a, (flags + inputerFlags)	; E: inputerFlags
	ld	e, a
	ld	a, (flags + mCursorFlags)	; D: cursorFlags
	ld	d, a
	ld	a, l
	; Check cursor options
	cp	skAlpha
	jr	nz, getKeyNoAlpha
	bit	allowAlpha, e
	jr	z, getAsciiLoop
	ld	a, d
	bit	cursor2nd, a
	jr	z, {@}
	and	~cursor2ndMask
	or	cursorAlphaMask | cursorALockMask
	jr	getAsciiSetFlags
@:	bit	cursorAlpha, a
	jr	nz, {@}
	or	cursorAlphaMask
	and	~cursorLwrAlphaMask
	jr	getAsciiSetFlags
@:	bit	allowLwrAlpha, e
	jr	nz, {2@}
@:	and	~(cursorAlphaMask | cursorLwrAlphaMask)
	jr	getAsciiSetFlags
@:	bit	cursorLwrAlpha, a
	jr	nz, {-2@}
	or	cursorLwrAlphaMask	
getAsciiSetFlags:
	ld	(flags + mCursorFlags), a
	jr	getAsciiLoop
getKeyNoAlpha:
	cp	sk2nd
	ret	nz
	ld	a, d
	bit	cursor2nd, a
	jr	nz, {@}
	or	cursor2ndMask
	jr	getAsciiSetFlags
@:	and	~cursor2ndMask
	jr	getAsciiSetFlags


;------ Hex input --------------------------------------------------------------
GetHexByte:
; Do not attempt to get a byte across a line break.
; Gets byte at current location.  Returns byte in A
; Registers:
; b: returns nibble from getNibble
; d: byte
	push	bc
	push	de
	push	hl
	call	CursorOn
	call	getNibble
	sla	b
	sla	b
	sla	b
	sla	b
	push	bc
	call	getNibble
	ld	a, b
	pop	bc
	add	a, b
	push	af
	call	CursorOff
	pop	af
	pop	hl
	pop	de
	pop	bc
	ret
getNibble:
	call	GetKey
	ld	hl, hexKeyTable
	ld	b, hexKeyTableSize
@:	cp	(hl)
	jr	z, foundNibble
	inc	hl
	djnz	{-1@}
	jr	getNibble
foundNibble:
	dec	b
	ld	a, '0'
	add	a, b
	cp	3Ah
	jr	c, {@}
	add	a, 7
@:	call	PutC
	ret


;------ BlinkyGetKey -----------------------------------------------------------
BlinkyGetKey:
; Blinky version of GetKey.
; Input:
;  - A: Cursor char
; Output:
;  - A: Key code
; Destroys:
;  - Flags
	ld	a, chCurUnderline
	ld	(cursorChar), a
	call	ClearAllShiftFlags
	ld	a, cursorOtherMask
	ld	(flags + mCursorFlags), a
	call	CursorOn
	call	GetKey
	push	af
	call	CursorOff
	pop	af
	ret


;------ GetKey -----------------------------------------------------------------
GetKey:
; Waits for a keypress, and returns it.
; This may APD.
; Interrupts must be enabled.
; Inputs:
;  - None
; Output:
;  - Scan code in A
; Destroys:
;  - Nothing
	push	hl
	push	af
	ld	hl, cursorPeriod;(cursorTimerPeriod)
	ld	(cursorTimer), hl
	ld	a, (flags + mCursorFlags)
	and	cursorAbleMask
	jr	z, {@}
	ld	hl, flags + mCursorFlags2
	set	cursorFlash, (hl)
@:	pop	af
	pop	hl
getKeyLoop:
	call	GetCSC
	or	a
	jr	nz, EraseCursor
	ei
	halt
	ld	a, (flags + mCursorFlags)
	and	cursorAbleMask;	bit	cursorAble, a
	jr	z, getKeyLoop
	ld	a, (flags + mcursorFlags2)
	and	cursorFlashMask
	call	nz, CursorToggle
	jr	getKeyLoop
EraseCursor:
	push	af
	ld	a, (flags + mCursorFlags)
	bit	cursorAble, a
	jr	z, {@}
	bit	cursorShowing, a
	call	nz, CursorToggle
@:	pop	af
	ret
CursorToggle:
;	ld	a, i
;	call	PutC
	push	bc
	push	de
	push	hl
	ld	hl, flags + mCursorFlags2
	res	cursorFlash, (hl)
	inc	hl
	bit	cursorShowing, (hl)
	jr	nz, cursorErase
	; Cursor is not showing
	set	cursorShowing, (hl)
	call	ReadChar
	ld	(cursorBackup), a
	call	FixCursor
	ld	a, (flags + mCursorFlags)
;	ld	c, 0
	ld	b, a
	ld	a, (cursorChar)
	bit	cursorOther, b
	jr	nz, cursorShowCursor
cursorNormalSet:
	ld	a, chCur
	bit	cursorInsert, b
	jr	z, {@}
	add	a, 4
@:	bit	cursor2nd, b
	jr	z, {@}
	inc	a
	jr	cursorShowCursor
@:	bit	cursorAlpha, b
	jr	z, cursorShowCursor
	add	a, 2
	bit	cursorLwrAlpha, b
	jr	z, cursorShowCursor
	inc	a
cursorShowCursor:
	ld	hl, (currentRow)
	push	hl
;	and	127
;	ld	a, 81h;('!'|80h)
	call	PutCRaw
	;call	BackspaceCursor
	pop	hl
	call	Locate
	jr	cursorToggleRet
cursorErase:
	res	cursorShowing, (hl)
	; Erase the cursor
#if mTextInverse != 0
	.error	"Change cursorErase to know the correct value of mTextInverse"
#endif
	ld	hl, flags + mTextFlags
	ld	c, (hl)
	res	mTextInverse, (hl)
	ld	hl, (currentRow)
	push	hl
	ld	a, (cursorBackup)
	call	PutC
	pop	hl
	call	Locate
	ld	a, c
	ld	(flags + mTextFlags), a
;	ld	a, (cursorBackup)
;	and	80h
;	rlc	a
;	ld	b, a
;	ld	a, (flags + mCursorFlags)
;	ld	c, a
;	and	~mTextInverseMask
;	or	b
;	ld	(flags + mCursorFlags), a
;	ld	a, (cursorBackup)
;	and	7Fh
;	ld	hl, (currentRow)
;	push	hl
;	call	PutC
;	pop	hl
;	call	Locate
;	;call	BackspaceCursor
;	ld	a, c
;	ld	(flags + mCursorFlags), a
cursorToggleRet:
	pop	hl
	pop	de
	pop	bc
	ret


;------ CursorOn ---------------------------------------------------------------
CursorOn:
; Enables the blinking cursor that GetKey can show
; Inputs:
;  - None
; Output:
;  - Documented effect(s)
; Destroys:
;  - Nothing
	push	hl
	ld	hl, flags + mCursorFlags
	set	cursorAble, (hl)
	ld	hl, flags + mCursorFlags2
	set	cursorFlash, (hl)
	pop	hl
	ret


;------ CursorOff --------------------------------------------------------------
CursorOff:
; Disables the blinking cursor
; Inputs:
;  - None
; Output:
;  - Documented effect(s)
; Destroys:
;  - Nothing
	push	hl
	ld	hl, flags + mCursorFlags
	res	cursorAble, (hl)
	pop	hl
	ret


;------ GetCSC -----------------------------------------------------------------
GetCSC:
; Returns the most recent keypress and removes it from the key queue.
; Inputs:
;  - None
; Output:
;  - Scan code in A
; Destroys:
;  - Nothing
	ld	a, (keyBuffer)
	push	af
	xor	a
	ld	(keyBuffer), a
	pop	af
	ret


;------ PeekCSC ----------------------------------------------------------------
PeekCSC:
; Returns the most recent keypress but leaves it in the key queue.
; This is a pretty dumb routine.
; Inputs:
;  - None
; Output:
;  - Scan code in A
; Destroys:
;  - Nothing
	ld	a, (keyBuffer)
	ret


;------ Scan Keyboard ----------------------------------------------------------
ScanKeyboard:
; Implements the core logic used for keyboard scanning, including timing for
; debouncing.
; You can call this manually if interrupts are disabled, but you will need to do
; so at about 50 Hz or the debouncing timing will be strange.
; Inputs:
;  - None
; Output:
;  - Documented effect (s)
; Destroys:
;  - AF
;  - BC
	call	RawGetCSC
; Key repeat logic:
; Key must be held for at least minKeyHoldTime before press registers.
; Thereafter, the same key code will not be accepted after release for keyBlockTime.
; As long as the key is being held, reissue the keypress to keyBuffer every keyRepeatWaitTime.
	; Any code?
	or	a
	jr	nz, dontReleaseKey
	ld	a, (lastKey)
	or	a
	ret	z	;jr	z, noKeys
	; Otherwise, begin blocking timer
	ld	a, (lastKeyBlockTimer)
	dec	a
	ld	(lastKeyBlockTimer), a
	ret	nz	;jr	nz, nokeys
	; The timer has expired, so allow the key again
	ld	(lastKey), a	; already 0
	ret
dontReleaseKey:
	ld	c, a	; Save code for a moment
	; Reset the blocking timer
	ld	a, keyBlockTime
	ld	(lastKeyBlockTimer), a
	; Is the registered key the same as the last key?
	; This also covers the 0 case.
	ld	a, (lastKey)
	cp	c
	jr	nz, newKey	; If not, accept the new key
	; It's the same old key, so decrement the hold timer
	ld	a, (lastKeyHoldTimer)
	or	a
	jr	nz, decHoldTimer
	; Wait, the key has already been accepted.
	; Check if we're already in repeat mode, or need to wait
	ld	a, (lastKeyFirstRepeatTimer)
	or	a
	jr	z, {@}	; Repeat mode
	dec	a
	ld	(lastKeyFirstRepeatTimer), a
	ret	;jr	noKeys
@:	; OK, so we're in repeat mode.  Now do the reapeat timer.
	ld	a, (lastKeyRepeatTimer)
	or	a
	jr	z, acceptKeypress	; The key was previously accepted, AND it's now ready to be reissued.
	dec	a
	ld	(lastKeyRepeatTimer), a
	ret
decHoldTimer:
	dec	a
	ld	(lastKeyHoldTimer), a
	jr	z, acceptKeypress
	; This key isn't ripe yet, so ignore it for now.
	ret	;jr	noKeys
newKey:	; Save the key code
	ld	a, c
	ld	(lastKey), a
	; Reset timers
	ld	bc, keyBlockTime*256 + minKeyHoldTime
	ld	(lastKeyHoldTimer), bc
	ld	bc, keyRepeatWaitTime*256 + keyFirstRepeatWaitTime
	ld	(lastKeyFirstRepeatTimer), bc
	; Now RET, and leave decrementing the debouncing timers for the next
	; interrupt cycle
	ret	;jr	noKeys
acceptKeypress:
	; Reset timers
	ld	a, keyBlockTime
	ld	(lastKeyBlockTimer), a
	ld	a, keyRepeatWaitTime
	ld	(lastKeyRepeatTimer), a
	ld	bc, suspendDelay
	ld	(suspendTimer), bc
	; Now write the key to the buffer
	ld	a, (lastKey)
	ld	(keyBuffer), a
;noKeys:	ret
	ret


;------ GetCSC -----------------------------------------------------------------
RawGetCSC:
; Scans the keyboard matrix for any pressed key, returning the first it finds,
; or 0 if none.
; Inputs:
;  - None
; Output:
;  - Code in A, or 0 if none
; Destroys:
;  - BC
	ld	a, 0FFh
	out	(pKey), a
	pop	af
	push	af
	ld	bc, 07BFh
@:	; Matrix scan loop
	ld	a, c
	out	(pKey), a
	rrca
	ld	c, a
	pop	af	; Probably should waste at least 20 cycles here.
	push	af	
;	push	ix
;	pop	ix
	in	a, (pKey)
	cp	0ffh
	jr	nz, {@}	; Any key pressed?
	djnz	{-1@}
	; No keys pressed in any key group, so return 0.
	xor	a
	ret
@:	; Yay! Found a key, now form a scan code
	dec	b
	sla	b
	sla	b
	sla	b
	; Get which bit in A is reset
@:	rrca
	inc	b
	jr	c, {-1@}
	ld	a, b
	ret

.endmodule