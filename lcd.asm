; This program is free software. It comes without any warranty, to
; the extent permitted by applicable law. You can redistribute it
; and/or modify it under the terms of the Do What The Fuck You Want
; To Public License, Version 2, as published by Sam Hocevar. See
; http://sam.zoy.org/wtfpl/COPYING for more details.

; This contains LCD routines not related to text.

.module	Lcd

;------ ClearSrcnFull ----------------------------------------------------------
; Fully erases the whole screen to black.
; Just uses FillScrnFull to do its dirty work.
ClrScrnFull:
	ld	d, 0
;------ FillScrnFull -----------------------------------------------------------
FillScrnFull:
; Fills the entire screen with a specified 16-bit color.
; Selected colors:
; Component 5/6/5 is the color as the LCD controller sees it.  For consistency,
; the middle green channel is divided by two, so each channel is out of 31.
; Component 8/8/8 is each channel multiplied by 8 so it is out of 255, like on
; PCs.
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
; FF	31,   31, 31	255, 255, 255	White		White
; 
; Input:
;  - D: Color to write, high and low bytes are the same
; Output:
;  - Screen filled with repeating byte
;  - Current LCD register set to lrGram
;  - Row & Col set to (0,0)
;  - Window set to (0,0)-(319,239)
; Destroys:
;  - A, BC
; Assumes:
;  - Only assumes that the LCD is more or less configured correctly.
; Execution Time:
;  - Base time is 129 ms
;  - Add 31 ms if ASIC-forced LCD delay is set to the minimum of 3 clock cycle
;  - Total minimum time is therefore 160 ms (or 6.2 frames/second)
	screenDi
	ld	c, pLcdCmd	; 7 cc
	xor	a		
	;			; sigma = 11
	; Sync
	out	(pLcdCmd), a	; 11 cc
	out	(pLcdCmd), a
	out	(pLcdCmd), a
	out	(pLcdCmd), a
	;			; sigma = 44
	; lrWinTop
	ld	b, lrWinTop	; 7 cc
	out	(pLcdCmd), a
	out	(c), b		; 12 cc
	out	(pLcdData), a
	out	(pLcdData), a
	;			; sigma = 52
	; lrWinBottom
	inc	b
	out	(pLcdCmd), a
	out	(c), b
	out	(pLcdData), a
	ld	a, colorScrnHeight-1
	out	(pLcdData), a
	xor	a
	;			; sigma = 60
	; lrWinLeft
	inc	b
	out	(pLcdCmd), a
	out	(c), b
	out	(pLcdData), a
	out	(pLcdData), a
	;			; sigma = 49
	; lrWinRight
	inc	b
	out	(pLcdCmd), a
	out	(c), b
	inc	a
	;ld	de, colorScrnWidth ; 10 cc
	out	(pLcdData), a
	ld	a, lcdLow((colorScrnWidth-1))
	out	(pLcdData), a
	xor	a
	;			; sigma = 64
	; lrRow
	ld	b, lrRow
	out	(pLcdCmd), a
	out	(c), b
	out	(pLcdData), a
	out	(pLcdData), a
	;			; sigma = 52
	; lrCol
	inc	b
	out	(pLcdCmd), a
	out	(c), b
	out	(pLcdData), a
	out	(pLcdData), a
	;			; sigma = 49
	; Now fill the screen
	ld	b, lrGram
	out	(pLcdCmd), a
	out	(c), b
	ld	c, 75
	ld	b, 0
	ld	a, d
	;			; sigma = 51
	; Total time for header:  sigma = 432
	; Plus 3 cycles added by ASIC per write: 30*3 = 90
	; So 522 cc total for initalization.
_fsfl:	out	(pLcdData), a
	out	(pLcdData), a
	out	(pLcdData), a
	out	(pLcdData), a
	out	(pLcdData), a
	out	(pLcdData), a
	out	(pLcdData), a
	out	(pLcdData), a
	djnz	_fsfl		; 13/8 cc
	; 11*8*256+13*255+8 = 25851 cc
	dec	c
	jr	nz, _fsfl		; 12/7 cc
	; (25851+4)*75+12*74+7 = 1940020
	screenEi
	ret			; 10 cc
	; 1940462 = ca. 129 ms
	; Plus 3 cycles per write: 3*2*320*240 = 460800.
	; So, including delays, 2401352 clock cycles + 77 more for save/restore interrupts
	; Which is about 160 ms or 6.2 frames/second.


;------ ------------------------------------------------------------------------
.endmodule