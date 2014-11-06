usbLineEventsIntrMask	.equ	cidFall | cidRise | vbusRise | vbusFall
usbCoreAllIntrMask	.equ	usbIntrSuspend | usbIntrResume | usbIntrReset | usbIntrSof | usbIntrConnect | usbIntrDisconnect | usbIntrSessReq | usbVbusError



; TODO: Callback invocation mode
; TODO: Max packet size information

; Global USB driver data
; USB event queue
usbIntRecurseFlag	.equ	usb_vars
usbEvQWritePtr		.equ	usbIntRecurseFlag + 1
usbEvQReadPtr		.equ	usbEvQWritePtr + 2
usbEvQueue		.equ	usbEvQReadPtr + 2
; Temp used for holding USB device address temporarily
usbTemp			.equ	usbEvQueue + 32
; Driver data
usbFlags		.equ	usbTemp + 1
usbEventFlags		.equ	usbFlags + 1
; Pointer to descriptors
usbDescriptorsPtr	.equ	usbEventFlags + 1
; Called on errors
usbMasterErrorCb	.equ	usbDescriptorsPtr + 2
; Called when the peripheral receives a USB address
usbDeviceStartCb	.equ	usbMasterErrorCb + 2
; Called when the peripheral is disconnected
usbDeviceStopCb		.equ	usbDeviceStartCb + 2
; Called when the device or bus is suspended
usbSuspendCb		.equ	usbDeviceStopCb + 2
; Called upon resume
usbResumeCb		.equ	usbSuspendCb + 2

; Individual pipes
usbPipeVarsSize		.equ	12
usbTxPipeCount		.equ	usbResumeCb + 2
usbTxPipe0VarsPtr	.equ	usbTxPipeCount + 1
usbRxPipeCount		.equ	usbTxPipe0VarsPtr + 2
usbRxPipe0VarsPtr	.equ	usbRxPipeCount + 1
end_usb_vars		.equ	usbRxPipe0VarsPtr + 2

; Global main flags
usbFlagDeviceStartedB	.equ	0	; Set when we are configured
usbFlagSuspendedB	.equ	1	; Set when if in suspend mode
usbFlagACableB		.equ	2	; Set when an A cable is inserted (error condition)
usbFlagSetAddressB	.equ	3	; Set when Set-Address is PENDING
usbFlagMasterErrorB	.equ	4	; Set when there is a error condition
usbFlagControlAutoProcB	.equ	5	; Set when . . . ? What was I thinking?

; Global event flags
; Is there a use for this?
usbEvMasterErrorB	.equ	0
usbEvDeviceStartB	.equ	1
usbEvDeviceStopB	.equ	2
usbEvSuspendB		.equ	3
usbEvResumeB		.equ	4


; Pipe-specific data
usbPipeFlags		.equ	0
usbPipeTemp		.equ	usbPipeFlags + 1
usbPipeDataProcCb	.equ	usbPipeTemp + 1
usbPipeBufferPtr	.equ	usbPipeDataProcCb + 2
; DataSize is important for autosend/autoreceive
; If not circular buffer:
; For autosend, this will send full packets until DataSize bytes have been sent.
; If DataSize bytes haven't been sent, but there isn't enough data in the
; buffer to send a full packet, it will STALL until enough data is available.
; For autoreceive, it will autobuffer incoming data until DataSize bytes have
; been read.
; If circular buffer:
; After every packet is RX/TX, the callback is called.
usbPipeBufferDataSize	.equ	usbPipeBufferPtr + 2
usbPipeBufferReadPtr	.equ	usbPipeBufferDataSize + 2
usbPipeBufferWritePtr	.equ	usbPipeBufferReadPtr + 2
 
; Pipe flags
usbPipeFlagCbOnIntr	.equ	01h
usbPipeFlagCbOnIntrB	.equ	0
usbPipeFlagCbIsTable	.equ	02h
usbPipeFlagCbIsTableB	.equ	1
usbPipeFlagAutoBuffer	.equ	04h
usbPipeFlagAutoBufferB	.equ	2
usbPipeFlagCircBuffer	.equ	08h
usbPipeFlagCircBufferB	.equ	3
usbPipeFlagSendNull	.equ	10h
usbPipeFlagSendNullB	.equ	4
usbPipeFlagActiveXmit	.equ	20h
usbPipeFlagActiveXmitB	.equ	5
usbPipeFlagBufferFull	.equ	40h
usbPipeFlagBufferFullB	.equ	6
usbPipeFlagBufferEmpty	.equ	80h
usbPipeFlagBufferEmptyB	.equ	7



; Data callback flags
dataProcCbPipeMask	.equ	0Fh
dataProcCbEventIdMask	.equ	0F0h
dataProcCbRxComplete	.equ	00h
dataProcCbTxComplete	.equ	10h
dataProcCbRxPacket	.equ	20h
dataProcCbTxPacket	.equ	30h






.ifdef	NEVER
usbFlags		.equ	flags
usbEventsFlags		.equ	asm_Flag1
usbEventACableConnect	.equ	0
usbEventACableDisconnect .equ	1
usbEventBCableConnect	.equ	2
usbEventBCableDisconnect .equ	3
usbEventInData		.equ	4
usbEventOutData		.equ	5
usbHostRequestsData	.equ	6
usbPeripheralConfigured	.equ	7

usbDriverFlags		.equ	asm_Flag2

usbBuffers

usbInIntr		.equ	usb_vars
usbOutIntr		.equ	usbInIntr + 2
;usb .equ	usbOutIntr + 2
.endif