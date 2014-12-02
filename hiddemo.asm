HidDemoStart:
	


hidEventCallBack:




;====== Variables ==============================================================
hidTxPipe0Vars		.equ	hid_vars
hidTxPipe1Vars		.equ	hidTxPipe0Vars + usbPipeVarsSize
hidRxPipe0Vars		.equ	hidTxPipe1Vars + usbPipeVarsSize
hidControlTxBuffer	.equ	hidRxPipe0Vars + usbPipeVarsSize
hidInterruptBuffer	.equ	hidControlTxBuffer + 64
hidControlRxBuffer	.equ	hidInterruptBuffer + 8
end_of_hid_vars		.equ	hidControlRxBuffer + 64


;====== Descriptors & Data =====================================================
hidDriverSetupData:
; Global stuff
	.dw	hidDescriptors
	.dw	hidEventCallBack
	.db	2			; TX pipes count, 8 pipe maximum (including control pipe)
	.dw	hidTxPipe0Vars
	.db	1			; RX pipes count, 8 pipe maximum (including control pipe)
	.dw	hidRxPipe0Vars
; TX control pipe
	.db	usbPipeFlagAutoBufferB	; usbPipeFlags
	.db	64 / 8			; Max packet size
	.dw	0			; usbPipeDataProcCb
	.db	0			; usbPipeDataProcCbPg
	.dw	hidControlTxBuffer	; usbPipeBufferPtr
	.db	0			; usbPipeBufferPtrPg
	.dw	64			; usbPipeBufferSize
	.dw	hidControlTxBuffer	; usbPipeBufferReadPtr
	.db	0			; usbPipeBufferReadPtrPg
	.dw	hidControlTxBuffer	; usbPipeBufferWritePtr
	.db	0			; usbPipeBufferWritePtrPg
; TX HID interrupt pipe
	.db	0			; usbPipeFlags
	.db	8 / 8			; Max packet size
	.dw	0			; usbPipeDataProcCb
	.db	0			; usbPipeDataProcCbPg
	.dw	hidInterruptBuffer	; usbPipeBufferPtr
	.db	0			; usbPipeBufferPtrPg
	.dw	8			; usbPipeBufferSize
	.dw	hidInterruptBuffer	; usbPipeBufferReadPtr
	.db	0			; usbPipeBufferReadPtrPg
	.dw	hidInterruptBuffer	; usbPipeBufferWritePtr
	.db	0			; usbPipeBufferWritePtrPg
; RX control pipe
	.db	usbPipeFlagAutoBufferB | usbPipeFlagCbIsTable	; usbPipeFlags
	.db	64 / 8			; Max packet size
	.dw	hidControlTable		; usbPipeDataProcCb
	.db	0			; usbPipeDataProcCbPg
	.dw	hidControlRxBuffer	; usbPipeBufferPtr
	.db	0			; usbPipeBufferPtrPg
	.dw	64			; usbPipeBufferSize
	.dw	hidControlRxBuffer	; usbPipeBufferReadPtr
	.db	0			; usbPipeBufferReadPtrPg
	.dw	hidControlRxBuffer	; usbPipeBufferWritePtr
	.db	0			; usbPipeBufferWritePtrPg
; Pipe flags usbPipeFlagCbOnIntrB usbPipeFlagAutoBufferB usbPipeFlagBufferFullB usbPipeFlagBufferEmptyB

hidDescriptors:
hidControlTable:




KbdDescriptors:
	.dw	KbdDeviceDescriptor
	.dw	KbdConfigDescriptor
	.db	4
	.dw	KbdStringDescriptor0
	.dw	KbdStringDescriptor1
	.dw	KbdStringDescriptor2
	.dw	KbdStringDescriptor3

KbdDeviceDescriptor:
	.db	KbdDeviceDescriptorEnd - KbdDeviceDescriptor	; bLength
	.db	usbDescTypeDevice				; bDescriptorType
	.dw	usbVersion					; bcdUSB
	.db	3						; bDeviceClass
	.db	1						; bDeviceSubClass
	.db	1						; bDeviceProtocol
	.db	64						; bMaxPacketSize
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
	
KbdStringDescriptor0:
	.db	KbdStringDescriptor0End - KbdStringDescriptor0	; bLength
	.db	usbDescTypeString				; bDescriptorType
	.dw	0409h	; US English
KbdStringDescriptor0End:

KbdStringDescriptor1:
	.db	KbdStringDescriptor1End - KbdStringDescriptor1	; bLength
	.db	usbDescTypeString				; bDescriptorType
	; UCS-16 (little-endian)
	.dw	'T', 'e', 'x', 'a', 's', ' '
	.dw	'I', 'n', 's', 't', 'r', 'u', 'm', 'e', 'n', 't', 's', ' '
	.dw	'o', 'f', ' '
	.dw	'D', 'e', 's', 't', 'r', 'u', 'c', 't', 'i', 'o', 'n'
KbdStringDescriptor1End:

KbdStringDescriptor2:
	.db	KbdStringDescriptor2End - KbdStringDescriptor2	; bLength
	.db	usbDescTypeString				; bDescriptorType
	.dw	'H', 'I', 'D', ' ', 'T', 'e', 's', 't', ' '
	.dw	'D', 'e', 'v', 'i', 'c', 'e'
KbdStringDescriptor2End:

KbdStringDescriptor3:
	.db	KbdStringDescriptor3End - KbdStringDescriptor3	; bLength
	.db	usbDescTypeString				; bDescriptorType
	.dw	'K', 'e', 'y', 'b', 'o', 'a', 'r', 'd', ' '
	.dw	'T', 'e', 's', 't'
KbdStringDescriptor3End:

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
