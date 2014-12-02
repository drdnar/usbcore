UnlockFlash:
;	ld	iy, unlockFlashRoutine-2
;	jp	ExecRamCode

;	.dw	unlockFlashRoutineEnd-unlockFlashRoutine
unlockFlashRoutine:
;This is only going to work properly on known 84+CSE boot code 4.0.
	di
	in a,(0Eh)
	push af
	in a,(6)
	push af
	ld a,1
	out (0Eh),a
	ld a,7Fh
	out (6),a
	ld hl,81FAh ;81 comes from i + flags, FA comes from lower byte of return address from boot code
	ld (hl),0C3h
	inc hl
;	ld (hl),(+_ - unlockFlashRoutine + microsRamCode) & 0FFh
	ld (hl), {@} & 0FFh
	inc hl
;	ld (hl),(+_ - unlockFlashRoutine + microsRamCode) >> 8
	ld (hl), {@} >> 8
	ld a,1
	out (5),a
	ld hl,0
	add hl,sp
	ex de,hl
	ld sp,8282h+4000h+2+2+2+2-1 ;8282h comes from boot code "call IX" routine, offsets come from boot code stack trace
	ld a,80h
	ld i,a
	jp 430Ah ;430Ah comes from boot code "erase sector 0" reboot code
@:	ex de,hl
	ld sp,hl
	xor a
	out (5),a
	pop af
	out (6),a
	pop af
	out (0Eh),a
	ret
unlockFlashRoutineEnd:

.ifdef	NEVER
UnlockFlash:
;Unlocks Flash protection.
;Destroys:
;	ramCode
;	0FFFEh
;      tempSwapArea+10
;This cannot work on the original TI-83 Plus.
	di
	ld	a, 1
	out	(pMPgBHigh), a
	ld	a, 7Fh
	out	(pMPgB), a
	;Find "call ix" code
	ld	ix, callIXPattern
	ld	de, 8000h
	call	FindPattern
	jr	nz, unlockReturn
	ld	hl, (0FFFEh)
	push	hl
	;Find boot page "erase sector 0" reboot code
	ld	ix, unlockPattern
	ld	de, 8000h
	call	FindPattern
	pop	de
	jr	nz, unlockReturn
	ld	a, 81h
	out	(pMPgB), a
	ld	d, 81h ;D comes from i + flags, E comes from lower byte of return address from boot code
	ld	hl, returnPoint
	ld	bc, returnPointEnd - returnPoint
	ldir
	ld	hl, unlockLoader
	ld	de, tempSwapArea + 10
	ld	bc, unlockLoaderEnd - unlockLoader
	ldir
	jp	tempSwapArea + 10
unlockLoader:
	in	a, (pMPgA)
	push	af
	in	a, (pMPgAHigh)
	push	af
	ld	a, 7Fh
	out	(6), a
	ld	a, 1
	out	(0Eh), a
	ld	de, unlockPatternCallStart - unlockPattern
	ld	hl, (0FFFEh)
	add	hl, de
	res	7, h
	set	6, h
	push	hl
	pop	ix
	ld	a, 1
	out	(5), a
	ld	hl, 0
	add	hl, sp
	ex	de, hl
	ld	sp, 8282h+4000h+2+2+2+2-1 ;base comes from boot code "call IX" routine, offsets come from boot code stack trace
	ld	a, 80h
	ld	i, a
	jp	(ix)
unlockLoaderEnd:
returnPoint:
	ex	de, hl
	ld	sp, hl
	xor	a
	out	(5), a
	pop	af
	out	(0Eh), a
	pop	af
	out	(6), a
	in	a, (2)
	ret
returnPointEnd:
unlockReturn:
	ld	a, 81h
	out	(7), a
unlockRet:
	ret
callIXPattern:
	push	bc
	push	de
	push	hl
	push	ix
	pop	hl
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	inc	hl
	ld	de, 8100h
	push	de
	ldir
	pop	ix
	pop	hl
	pop	de
	pop	bc
	call	0FEFEh
	push	af
	ld	a, (82FEh)
	bit	2, a
	.db	0FFh
unlockPattern:
	call	0FEFEh
	.db	28h, 0FEh ;jr z,xx
unlockPatternCallStart:
	push	af
	ld	a, 1
	nop
	nop
	im	1
	di
	out	(14h), a
	di
	.db	0FDh
	xor	a
	call	0FEFEh
	push	af
	xor	a
	nop
	nop
	im	1
	di
	out	(14h), a
	.db	255

FindPattern:
;Pattern in IX, starting address in DE
;Returns NZ if pattern not found
;(0FFFEh) contains the address of match found
;Search pattern:	terminated by 0FFh
;					0FEh is ? (one-byte wildcard)
;					0FDh is * (multi-byte wildcard)
	ld hl,unlockRet
	push hl
	dec de
searchLoopRestart:
	inc de
	ld (0FFFEh),de
	push ix
	pop hl
searchLoop:
	ld b,(hl)
	ld a,b
	inc a
	or a
	ret z
	inc de
	inc a
	jr z,matchSoFar
	dec de
	inc a
	ld c,a
	;At this point, we're either the actual byte (match or no match) (C != 0)
	;  or * wildcard (keep going until we find our pattern byte) (C == 0)
	or a
	jr nz,findByte
	inc hl
	ld b,(hl)
findByte:
	ld a,(de)
	inc de
	bit 6,d
	ret nz
	cp b
	jr z,matchSoFar
	;This isn't it; do we start over at the beginning of the pattern,
	;  or do we keep going until we find that byte?
	inc c
	dec c
	jr z,findByte
	ld de,(0FFFEh)
	jr searchLoopRestart
matchSoFar:
	inc hl
	jr searchLoop
.endif