.ifdef never
PHY driver init
PHY disable
USB start
INT E4
INT line 40
LOW init peripheral
INT F0
INT prot 9104
INT bus reset
INT F0
INT prot 9100
INT control pipe 01
INT RX CTRL 8006 0001 0000 4000
INT CTRL dev to host 06
INT CTRL response start
INT CTRL response cont 1200
0010: INT F0
INT prot 9100
INT control pipe 00
INT CTRL response cont 0A00
INT F0
INT prot 9100
INT control pipe 10
INT control NAK thingy
INT CTRL response cont 0200
INT F0
INT prot 9104
INT bus reset
INT F0
INT prot 9100
INT control pipe 01
INT RX CTRL 0005 0400 0000 0000
INT CTRL set addr 04
0021: INT CTRL finish
INT F0
INT prot 9100
INT control pipe 01
INT set address 04
INT F0
INT prot 9100
INT control pipe 01
INT RX CTRL 8006 0001 0000 1200
INT CTRL dev to host 06
INT CTRL response start
INT CTRL response cont 1200
INT F0
INT prot 9100
INT control pipe 00
INT CTRL response cont 0A00
INT F0
0032: INT prot 9100
INT control pipe 00
INT CTRL response cont 0200
INT F0
INT prot 9100
INT control pipe 00
INT set address 04
INT F0
INT prot 9100
INT control pipe 01
INT RX CTRL 8006 0002 0000 FF00
INT CTRL dev to host 06
INT CTRL response start
INT CTRL response cont 2200
INT F0
INT prot 9100
INT control pipe 00
0043: INT CTRL response cont 1A00
INT F0
INT prot 9100
INT control pipe 00
INT F0
INT prot 9100
INT control pipe 00
INT CTRL response cont 0A00
INT F0
INT prot 9100
INT control pipe 00
INT CTRL response cont 0200
INT F0
INT prot 9100
INT control pipe 00
INT set address 04
0054: INT F0
INT prot 9100
INT control pipe 01
INT RX CTRL 8006 0003 0000 FF00
INT CTRL dev to host 06
INT CTRL response start
INT CTRL response cont 0400
INT F0
INT prot 9100
INT control pipe 00
INT set address 04
INT F0
INT prot 9100
INT control pipe 01
INT RX CTRL 8006 0203 0904 FF00
INT CTRL dev to host 06
INT CTRL response start
0065: INT CTRL response cont 2000
INT F0
INT prot 9100
INT control pipe 00
INT CTRL response cont 1800
INT F0
INT prot 9100
INT control pipe 00
INT CTRL response cont 1000
INT F0
INT prot 9100
INT control pipe 00
INT CTRL response cont 0800
INT F0
INT prot 9100
INT control pipe 04
INT control STALL
0076: INT F0
INT prot 9100
INT control pipe 01
INT RX CTRL 8006 0203 0904 FF00
INT CTRL dev to host 06
INT CTRL response start
INT CTRL response cont 2000
INT F0
INT prot 9100
INT control pipe 00
INT CTRL response cont 1800
INT F0
INT prot 9100
INT control pipe 00
INT CTRL response cont 1000
INT F0
INT prot 9100
0087: INT control pipe 00
INT CTRL response cont 0800
INT F0
INT prot 9100
INT control pipe 04
INT control STALL
INT F0
INT prot 9100
INT control pipe 01
INT RX CTRL 8006 0001 0000 1200
INT CTRL dev to host 06
INT CTRL response start
INT CTRL response cont 1200
INT F0
INT prot 9100
INT control pipe 00
INT CTRL response cont 0A00
0098: INT F0
INT prot 9100
INT control pipe 00
INT CTRL response cont 0200
INT F0
INT prot 9100
INT control pipe 00
INT set address 04
INT F0
INT prot 9100
INT control pipe 01
INT RX CTRL 8006 0002 0000 0900
INT CTRL dev to host 06
INT CTRL response start
INT CTRL response cont 0900
INT F0
INT prot 9100
00A9: INT control pipe 00
INT CTRL response cont 0100
INT F0
INT prot 9100
INT control pipe 00
INT set address 04
INT F0
INT prot 9100
INT control pipe 01
INT RX CTRL 8006 0002 0000 2200
INT CTRL dev to host 06
INT CTRL response start
INT CTRL response cont 2200
INT F0
INT prot 9100
INT control pipe 01
INT CTRL response cont 1A00
00BA: INT F0
INT prot 9100
INT control pipe 00
INT CTRL response cont 1200
INT F0
INT prot 9100
INT control pipe 00
INT CTRL response cont 0A00
INT F0
INT prot 9100
INT control pipe 00
INT CTRL response cont 0200
INT F0
INT prot 9100
INT control pipe 00
INT set address 04
INT F0
00CB: INT prot 9100
INT control pipe 00
INT set address 04
INT F0
INT prot 9100
INT control pipe 01
INT RX CTRL 0009 0100 0000 0000
INT CTRL set configuration 01
LOW CTRL finish
INT F0
INT prot 9100
INT control pipe 00
INT set address 04
INT F0
INT prot 9100
INT control pipe 01
INT RX CTRL 210A 0000 0000 0000
00DC: HID class-specific CTRL 0A
LOW CTRL finish
INT F0
INT prot 9100
INT control pipe 00
INT set address 04
INT F0
INT prot 9100
INT control pipe 01
INT RX CTRL 8106 0022 0000 7F00
HID get report
INT CTRL response start
INT CTRL response cont 3F00
INT F0
INT prot 9100
INT control pipe 00
INT CTRL response cont 3700
00ED: INT F0
...
00FE: ...
...
0109: INT F0
INT prot 9100
INT control pipe 01
INT RX CTRL 2109 0002 0000 0100
HID class-specific CTRL 09
INT F0
INT prot 9100
INT control pipe 01
LOW CTRL finish
INT F0
INT prot 9100
INT control pipe 00
LOW TX packet port 01
INT F0
INT prot 9100
INT outgoing success
LOW TX packet port 01
INT F0
INT prot 9100
INT outgoing success

INT E4
INT line 80
USB STOP


SRP = Session Request Protocol
HNP = Host Negotiation Protocol

INT prot 9104, 91 = port 8F (pUsbIntrId) BDEVICE | VBUS 10 | SESSION, 04 = port 86 (pUsbDevCtl) = usbIntrReset

├─┬─ DriverInit
│ └─── DisableUSB
├─── EnableUSB
├─┬─ Interrupt E4 1110 0100
│ └─┬─ Line interrupt: B cable plugged in
│   └─── InitializeUSB_Peripheral
├─── Protocol interrupt: Bus reset
├─┬─ Protocol interrupt, pUsbCsr0Cont = csr0RxPktRdy
│ └─┬─ Control pipe packet 8006 0001 0000 4000
│   └─── Send 12h byte reply
├─┬─ Protocol interrupt ?
│ └─── Reset csr0SvdSetupEnd . . . whatever that does
├─┬─ Protocol interrupt
│ └─┬─ Control pipe packet 0005 0400 0000 0000
│   └─── SET ADDRESS = 4
├─┬─ Protocol interrupt
│ └─── Control pipe packet 8006 0001 0000 1200

RX CTRL 8006 0002 0000 FF00
8006 0003 0000 FF00
8006 0203 0904 FF00
8006 0203 0904 FF00
8006 0001 0000 1200
8006 0002 0000 0900
8006 0002 0000 2200
0009 0100 0000 0000
210A 0000 0000 0000
8106 0022 0000 7F00



.endif





; HID Keyboard test
; TODO:
;  - Keyboard scanner: Scan keyboard, and send held keys
;  - Send events semi-regularly

usbDescTypeDevice	EQU	1
usbDescTypeConfig	EQU	2
usbDescTypeString	EQU	3
usbDescTypeIntrfc	EQU	4
usbDescTypeEndpoint	EQU	5
usbDescTypeProtocol	EQU	21h
endpntControl		EQU	0
endpntIsochronous	EQU	1
endpntBulk		EQU	2
endpntInterrupt		EQU	3
usbDescTypeFunct	EQU	21h
usbVersion		EQU	110h
usbClassHid		EQU	3
hidSubClassBoot		EQU	1
hidProtocolKbd		EQU	1
hidProtocolMouse	EQU	2


hidDemoMessage:
		;01234567890123456
	.db	"HID Demo", 0
hidDemoActiveMessage:
	.db	" Active ", 0

HidDemo:
;	B_CALL(_ClrLCDFull)
;	B_CALL(_HomeUp)
	call	HomeUp
	ld	hl, hidDemoMessage
	call	PutSClrWind
	
	; Initialize driver
	ld	b, 0
	call	DriverInit
	call	EnableUSB
	; Set up some pointers to data descriptors
;	B_CALL(_GetCurrentPageSub)
	ld	hl, KbdDescriptors
	ld	de, appData
	ld	bc, 9FFh
@:	ldi
	ldi
	ld	(de), a
	inc	de
	djnz	{-1@}
	ld	ix, appData
	ld	hl, KbdHandleControlRequest
	ld	a, (KbdDeviceDescriptor + 7)
	call	SetupPeripheralMode
	; Message
	ld	hl, 8 * 256 + 0
	call	Locate
	ld	hl, hidDemoActiveMessage
	call	PutS
	; Idle loop
hidLoop:
;	B_CALL(_GetCSC)
	ei
	halt
	call	GetCSC
;	or	a
;	jr	z, hidLoop
;	jr	HidDemoExit
	
	cp	skClear
	jr	z, HidDemoExit
	or	a
	jr	z, hidLoop
	ld	hl, appData + 31
	cp	skAlpha
	jr	nz, {1@}
	ld	(hl), 2
@:	ld	hl, appData + 32
	ld	(hl), 0
	ld	de, appData + 33
	ld	bc, 7
	ldir
	ld	hl, KeyTable
	call	MapTable
	jr	nz, hidLoop
	ld	hl, appData + 31
	ld	c, (hl)
	inc	hl
	ld	(hl), c
	inc	hl
	inc	hl
	ld	(hl), b
	dec	hl
	dec	hl
	ld	b, 8
	ld	c, 1
	call	SendInterruptData
	
	ld	a, chDown
	call	PutC
	
;	jr	c, ShowMainMenu
	ld	b, 64
@:	ei
	halt
	djnz	{-1@}
	xor	a
	ld	(appData + 32 + 2), a
	ld	hl, appData + 32
	ld	b, 8
	ld	c, 1
	call	SendInterruptData
	
	ld	a, chUp
	call	PutC
	
	ld	hl, appData + 31
	ld	(hl), 0
	jr	hidLoop
HidDemoExit:
	call	DriverKill
	jp	Restart
KeyTable:
	.db	34
	.db	skMath, 04h
	.db	skMatrix, 05h	;c4
	.db	skPrgm, 06h	;1
	.db	skRecip, 07h	;b9
	.db	skSin, 08h
	.db	skCos, 09h
	.db	skTan, 0Ah	;f6
	.db	skPower, 0Bh	;f1
	.db	skSquare, 0Ch
	.db	skComma, 0Dh	;b9
	.db	skLParen, 0Eh
	.db	skRParen, 0Fh	
	.db	skDiv, 10h	;f1
	.db	skLog, 11h	;e0
	.db	sk7, 12h
	.db	sk8, 13h
	.db	sk9, 14h
	.db	skMul, 15h
	.db	skLn, 16h
	.db	sk4, 17h	;78
	.db	sk5, 18h	;2b
	.db	sk6, 19h	;1f
	.db	skSub, 1Ah
	.db	skStore, 1Bh	;12
	.db	sk1, 1Ch
	.db	sk2, 1Dh	;d4
	.db	sk0, 2Ch
	.db	skEnter, 28h
	.db	skLeft, 50h
	.db	skRight, 4Fh
	.db	skUp, 52h
	.db	skDown, 51h
	.db	skDel, 2Ah
	.db	skDecPnt, 37h


KbdHandleControlRequest:
	; Switch based on control request type
	ld	hl, controlBuffer
	ld	a, (hl)
	inc	hl
	cp	21h	; Class-specific request
	jr	z, KbdHandleControlRequestClassSpecific
	and	80h	; Check bit 7 for check if HID thingy?
	jr	z, KbdHandleControlRequestUnknown
	ld	a, (hl)
	inc	hl
	cp	06	; 80 06 ...
	jr	nz, KbdHandleControlRequestUnknown
	inc	hl
	ld	a, (hl)
	cp	22h	; Is request for HID descriptor?
	jp	z, KbdHandleControlRequestHidReport
KbdHandleControlRequestUnknown:
	; I don't know, just ignore it
	scf
	ret

KbdHandleControlRequestClassSpecific:
	ld	a, (hl)
	LogUsbProtEvent8(lidUsbProtKbdCtrlReqClass, a)
	cp	0Ah	; SET_IDLE
	jr	z, KbdHandleControlRequestSetIdle
; From page 51
; 01	GET_REPORT
; 02	GET_IDLE
; 03	GET_PROTOCOL
; 09	SET_REPORT
; 0A	SET_IDLE
; 0B	SET_PROTOCOL
	ld	b, 81h
	ld	de, (controlBuffer + 6)
	ld	a, e
	or	d
	jr	z, KbdHandleControlRequestSetIdle
	ld	hl, appData + 32
	call	StartControlInput
	xor	a
	ret
	
KbdHandleControlRequestSetIdle:
	call	FinishControlRequest
	xor	a
	ret

KbdHandleControlRequestHidReport:
	LogUsbProtEventNull(lidUsbProtKbdGetReport)
	B_CALL(_GetCurrentPageSub)
	ld	b, a
	ld	hl, KbdHidDescriptor
	ld	de, KbdHidDescriptorEnd - KbdHidDescriptor
	call	StartControlResponse
	xor	a
	ret

GetRomPage:
	push	bc
	in	a, (6)
	ld	b, a
	in	a, (0Eh)
	rla
	rr	b
	rra
	pop	bc
	ret


KbdDescriptors:
	.dw	KbdDeviceDescriptor
	.dw	KbdConfigDescriptor
	.dw	KbdStringDescriptorTable

KbdDeviceDescriptor:
	.db	KbdDeviceDescriptorEnd - KbdDeviceDescriptor	; bLength
	.db	usbDescTypeDevice				; bDescriptorType
	.dw	usbVersion					; bcdUSB
	.db	3						; bDeviceClass
	.db	1						; bDeviceSubClass
	.db	1						; bDeviceProtocol
	.db	8h						; bMaxPacketSize
	.dw	0451h						; idVendor
	.dw	0CA7Ch						; idProduct
	.dw	0100h						; bcdDevice
	.db	1						; iManufacturer
	.db	2						; iProduct
	.db	0						; iSerialNumber
	.db	1						; bNumConfigurations
KbdDeviceDescriptorEnd:

KbdConfigDescriptor:
	.db	KbdConfigDescriptorEnd - KbdConfigDescriptor	; bLength
	.db	usbDescTypeConfig				; bDescriptorType
	.dw	KbdEndpntDescriptorEnd - KbdConfigDescriptor	; wLength thingy
	.db	1						; bNumInterfaces
	.db	1						; bConfigurationValue
	.db	2						; iConfiguration
	; 0xA0 = Bus-powered, remote wakeup
	.db	0A0h						; bmAttributes
	.db	100/2						; mMaxPower
KbdConfigDescriptorEnd:
KbdIntrfcDescriptor:
	.db	KbdIntrfcDescriptorEnd - KbdIntrfcDescriptor	; bLength
	.db	usbDescTypeIntrfc				; bDescriptorType
	.db	0						; bInterfaceNumber
	.db	0						; bAlternateSetting
	.db	1						; bNumEndPoints
	.db	usbClassHid					; bInterfaceClass
	.db	hidSubClassBoot					; bInterfaceSubClass
	.db	hidProtocolKbd					; bInterfaceProtocol
	.db	3						; iInterface
KbdIntrfcDescriptorEnd:
KbdFunctDescriptor:
	.db	KbdFunctDescriptorEnd - KbdFunctDescriptor	; bLength
	.db	usbDescTypeFunct				; bDescriptorType
	.dw	101h						; bcdHID 110
	.db	0						; bCountryCode
	.db	1						; bNumDescriptors
	.db	22h						; bDescriptorType
	.dw	KbdHidDescriptorEnd - KbdHidDescriptor		; bDescriptorLength
KbdFunctDescriptorEnd:
KbdEndpntDescriptor:
	.db	KbdEndpntDescriptorEnd - KbdEndpntDescriptor	; bLength
	.db	usbDescTypeEndpoint				; bDescriptorType
	.db	81h						; bEndpointAddress (In)
	.db	endpntInterrupt					; bmAttributes
	.dw	8						; wMaxPacketSize
	.db	50						; bInterval
KbdEndpntDescriptorEnd:

KbdStringDescriptorTable:
	.db	4
	
	.db	0	; Apparently, this is an index
KbdStringDescriptor0:
	.db	KbdStringDescriptor0End - KbdStringDescriptor0	; bLength
	.db	usbDescTypeString				; bDescriptorType
	.dw	0409h	; US English
KbdStringDescriptor0End:

	.db	1
KbdStringDescriptor1:
	.db	KbdStringDescriptor1End - KbdStringDescriptor1	; bLength
	.db	usbDescTypeString				; bDescriptorType
	; UCS-16 (little-endian)
	.dw	'T', 'e', 'x', 'a', 's', ' '
	.dw	'I', 'n', 's', 't', 'r', 'u', 'm', 'e', 'n', 't', 's', ' '
	.dw	'o', 'f', ' '
	.dw	'D', 'e', 's', 't', 'r', 'u', 'c', 't', 'i', 'o', 'n'
KbdStringDescriptor1End:

	.db	2
KbdStringDescriptor2:
	.db	KbdStringDescriptor2End - KbdStringDescriptor2	; bLength
	.db	usbDescTypeString				; bDescriptorType
	.dw	'H', 'I', 'D', ' ', 'T', 'e', 's', 't', ' '
	.dw	'D', 'e', 'v', 'i', 'c', 'e'
KbdStringDescriptor2End:

	.db	3
KbdStringDescriptor3:
	.db	KbdStringDescriptor3End - KbdStringDescriptor3	; bLength
	.db	usbDescTypeString				; bDescriptorType
	.dw	'K', 'e', 'y', 'b', 'o', 'a', 'r', 'd', ' '
	.dw	'T', 'e', 's', 't'
KbdStringDescriptor3End:

; Endura Pro:
; 05010906a101050719e029e71500250175019508810295017508810195057501050819012905910295017503910195067508150026ff000507190029988100c0
;0501		; USAGE_PAGE (Generic Desktop)
;0906		; USAGE (Keyboard)
;a101		; COLLECTION (Application)
;0507		;   USAGE_PAGE (Keyboard)
;19e0		;   USAGE_MINIMUM (Keyboard LeftControl)
;29e7		;   USAGE_MAXIMUM (Keyboard Right GUI)
;1500		;   LOGICAL_MINIMUM (0)
;2501		;   LOGICAL_MAXIMUM (1)
;7501		;   REPORT_SIZE (1)
;9508		;   REPORT_COUNT (8)
;8102		;   INPUT (Data,Var,Abs)
;9501		;   REPORT_COUNT (1)
;7508		;   REPORT_SIZE (8)
;8101					;   INPUT (Cnst,Var,Abs) 81 03
;9505		;   REPORT_COUNT (5)
;7501		;   REPORT_SIZE (1)
;0508		;   USAGE_PAGE (LEDs)
;1901		;   USAGE_MINIMUM (Num Lock)
;2905		;   USAGE_MAXIMUM (Kana)
;9102		;   OUTPUT (Data,Var,Abs)
;9501		;   REPORT_COUNT (1)
;7503		;   REPORT_SIZE (3)
;9101					;   OUTPUT (Cnst,Var,Abs) 91 03
;9506		;   REPORT_COUNT (6)
;7508		;   REPORT_SIZE (8)
;1500		;   LOGICAL_MINIMUM (0)
;26ff00			;   LOGICAL_MAXIMUM ??? (0xFF00)
;0507		;   USAGE_PAGE (Keyboard)
;1900		;   USAGE_MINIMUM (Reserved (no event indicated))
;2998		;   USAGE_MAXIMUM (0x98, not 0x65)
;8100		;   INPUT (Data,Ary,Abs)
;c0		; END_COLLECTION
KbdHidDescriptor:
	; 63 bytes
	.db	5, 1h		; USAGE_PAGE (Generic Desktop)
	.db	9, 6h		; USAGE (Keyboard)
	.db	0A1h, 1h	; COLLECTION (Application)
	.db	5h, 7h		;   USAGE_PAGE (Keyboard)
	.db	19h, 0E0h	;   USAGE_MINIMUM (Keyboard LeftControl)
	.db	29h, 0E7h	;   USAGE_MAXIMUM (Keyboard Right GUI)
	.db	15h, 0h		;   LOGICAL_MINIMUM (0)
	.db	25h, 1h		;   LOGICAL_MAXIMUM (1)
	.db	75h, 1h		;   REPORT_SIZE (1)
	.db	95h, 8h		;   REPORT_COUNT (8)
	.db	81h, 2h		;   INPUT (Data,Var,Abs)
	.db	95h, 1h		;   REPORT_COUNT (1)
	.db	75h, 8h		;   REPORT_SIZE (8)
	.db	81h, 3h		;   INPUT (Cnst,Var,Abs) 81 03
	.db	95h, 5h		;   REPORT_COUNT (5)
	.db	75h, 1h		;   REPORT_SIZE (1)
	.db	5h, 8h		;   USAGE_PAGE (LEDs)
	.db	19h, 1h		;   USAGE_MINIMUM (Num Lock)
	.db	29h, 5h		;   USAGE_MAXIMUM (Kana)
	.db	91h, 2h		;   OUTPUT (Data,Var,Abs)
	.db	95h, 1h		;   REPORT_COUNT (1)
	.db	75h, 3h		;   REPORT_SIZE (3)
	.db	91h, 3h		;   OUTPUT (Cnst,Var,Abs) 91 03
	.db	95h, 6h		;   REPORT_COUNT (6)
	.db	75h, 8h		;   REPORT_SIZE (8)
	.db	15h, 0h		;   LOGICAL_MINIMUM (0)
	.db	25h, 65h	;   LOGICAL_MAXIMUM (101)
	.db	5h, 7h		;   USAGE_PAGE (Keyboard)
	.db	19h, 0h		;   USAGE_MINIMUM (Reserved (no event indicated))
	.db	29h, 65h	;   USAGE_MAXIMUM (Keyboard Application)
	.db	81h, 0h		;   INPUT (Data,Ary,Abs)
	.db	0C0h		; END_COLLECTION
KbdHidDescriptorEnd:
