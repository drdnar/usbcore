; This program is free software. It comes without any warranty, to
; the extent permitted by applicable law. You can redistribute it
; and/or modify it under the terms of the Do What The Fuck You Want
; To Public License, Version 2, as published by Sam Hocevar. See
; http://sam.zoy.org/wtfpl/COPYING for more details.

; This is the interrupt driver.

.module	Interrupts

;------ ApdOn ------------------------------------------------------------------
;ApdOn:
; ApdOn
; Enables the APD function.
; Inputs:
;  - None
; Outputs:
;  - None
; Destroys:
;  - AF
;	set	setApdEnabled, (iy + mSettings)
;	ret


;------ ApdOff -----------------------------------------------------------------
;ApdOff:
; ApdOff
; Disables the APD function.
; Inputs:
;  - None
; Outputs:
;  - None
; Destroys:
;  - AF
;	res	setApdEnabled, (iy + mSettings)
;	ret


;------ SetUpInterrupts --------------------------------------------------------
SetUpInterrupts:
; Sets up the IM 2 interrupt system, but does not enable interrupts.
; Inputs:
;  - None
; Output:
;  - Interrupts set up
; Destroys:
;  - Assume all
	di
	xor	a
	out	(pIntMask), a
	out	(pCrstlTmr1Freq), a
	out	(pCrstlTmr2Freq), a
	out	(pCrstlTmr3Freq), a
	out	(pLnkAstSeEnable), a
	; And kill USB
	out	(57h), a
	out	(5Bh), a
	out	(4Ch), a
	ld	a, 2
	out	(54h), a
	; Custom interrupt vector table
	ld	hl, IvtLocation*256
	ld	de, IvtLocation*256+1
	ld	bc, 256
	ld	a, IvtLocation
	ld	i, a
	ld	a, IsrLocation
	ld	(hl), a
	ldir
	; ISR
	ld	hl, InterruptServiceRoutine
	ld	de, IsrLocation*256+IsrLocation
	ld	bc, 3
	ldir
	; Enable only wanted interrupts
	;ld	a, tmrFreq0 | memMapMode0 | battVoltage0
	xor	a	; Above expression evaulates to 0
	out	(pAsicMiscCfg), a
	ld	a, intTmr2 | intOnKey | intDisableLowPowerMode
	out	(pIntMask), a
	im	2
	ret
InterruptServiceRoutine:
	jp	RealIsr


;------ Interrupt Service Routine ----------------------------------------------
RealIsr:
	push	af
	push	hl
	; Stack overflow check
	ld	hl, 0
	add	hl, sp
	ld	a, h
;	cp	0FEh
;	jr	nc, {@}
	inc	a
	jr	z, {@}
	pop	hl
	pop	af
	pop	ix	; Attempt to fetch PC into IX
	ld	iy, 0
	add	iy, sp
	ld	sp, 0FFF0h

;	in	a, (pGpioData)
;	and	~gpioBacklightCtrl
;	out	(pGpioData), a

	jp	Quit	;call	Panic
@:	; Check interrupt source
.ifdef	LOGGING_ENABLED
	ld	a, (interruptCounter)
	inc	a
	ld	(interruptCounter), a
.endif
	in	a, (pIntId)
	rra
	jr	nc, {@}
	; On key
	ld	a, intOnKey ^ 255
	out	(pIntAck), a
	pop	hl
	pop	af
	jp	Panic
@:	rra
	jp	c, Panic
	rra
	jr	c, _intHPapd
	rra
	rra
	jp	c, Panic
	rra
	jp	c, Panic;	jr	c, intHCrystal
	rra
	jp	c, Panic;intHHCrystal
	; Check USB
	push	bc
	push	de
.ifndef	USB_CORE_DRIVER
	push	ix
	in	a, (pUsbCoreIntrStatus)
	cp	1Fh
	call	z, Panic
	xor	255
	ld	c, a

;	push	bc
;	ld	a, 'i'
;	call	PutC
;	pop	bc

	call	USBactivityHook
	pop	ix
	pop	de
	pop	bc
	pop	hl
	pop	af
	ei
	ret
.else
	in	a, (pUsbCoreIntrStatus)
	cp	1F
	jp	nz, HandleUsbInterrupt
	call	Panic
.endif
	; Wait, there should be no other active interrupt sources.
;	xor	a
;	out	(pIntAck), a
	;call	RebootMicrOS
;intHLink:
;intHCrystal:
;intHApd: ; WTF, didn't we disable this interrupt?
;	jp	InstantQuit
_intHPapd:
;	push	hl
	; ACK the interrupt
	ld	a, intTmr2 ^ 255
	;xor	a
	out	(pIntAck), a
	; General fast timer.  This is useful for timing routines.
	ld	hl, (genFastTimer)
	inc	hl
_i1:	ld	(genFastTimer), hl
	ld	a, h
	cp	4
	jr	c, _i2
	ld	hl, 0
.ifdef	LOGGING_ENABLED
	xor	a
	ld	(interruptCounter), a
.endif
	jr	_i1	; Saves one byte.
_i2:	; Check the cursor timer.  This timer is always running.
	ld	hl, (cursorTimer)
	dec	hl
	ld	(cursorTimer), hl
	ld	a, h
	or	l
	jr	nz, _i3
	ld	hl, cursorPeriod
	ld	(cursorTimer), hl
	ld	hl, flags + mCursorFlags2
	set	cursorFlash, (hl)
	; Check if we're sleepy
	ld	a, (flags + mApdFlags)
	and	apdEnabledMask
	jr	z, _i3
	ld	hl, (suspendTimer)
	dec	hl
	ld	(suspendTimer), hl
	ld	a, l
	or	h
	jr	nz, _i3
	ld	hl, suspendDelay
	ld	(suspendTimer), hl
	ld	a, (flags + mApdFlags)
	bit	apdNow, a
	set	apdNow, a
	ld	(flags + mApdFlags), a

	in	a, (pGpioData)
	and	gpioBacklightCtrl
	out	(pGpioData), a

	jp	nz, Quit
_i3:	; Check if it's time to scan the keyboard
	ld	a, (kbdScanTimer)
	dec	a
	ld	(kbdScanTimer), a
	jr	nz, _noscn
	ld	a, kbdScanDivisor
	ld	(kbdScanTimer), a
	push	bc
	call	ScanKeyboard
	pop	bc
_noscn:	pop	hl
	pop	af
	ei
	ret
RealIsrEnd:


;------ ------------------------------------------------------------------------
.endmodule