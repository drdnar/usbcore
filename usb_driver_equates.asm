usbLineEventsIntrMask	.equ	cidFall | cidRise | vbusRise | vbusFall
usbCoreAllIntrMask	.equ	usbIntrSuspend | usbIntrResume | usbIntrReset | usbIntrSof | usbIntrConnect | usbIntrDisconnect | usbIntrSessReq | usbVbusError



; TODO: Call back invocation mode
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
usbPipeVarsSize		.equ	16
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
usbPipeConfig		.equ	usbPipeFlags + 1
usbPipeMaxPacketMask	.equ	0F0h
; If the call back is code, it is called with DE = ptr to usbPipeFlags and
; A = pipe number.
; For RX pipes, if the call back if a processing table, you'll have to specify
; different tables for different pipes, or have some other means of figuring
; out which pipe's data you're processing.
usbPipeDataProcCb	.equ	usbPipeConfig + 1
usbPipeDataProcCbPg	.equ	usbPipeDataProcCb + 2
usbPipeBufferPtr	.equ	usbPipeDataProcCbPg + 1
usbPipeBufferPtrPg	.equ	usbPipeBufferPtr + 2
; DataSize is important for autosend/autoreceive
; For autosend, this will send full packets until DataSize bytes have been sent.
; If DataSize bytes haven't been sent, but there isn't enough data in the
; buffer to send a full packet, it will STALL until enough data is available.
; For autoreceive, it will autobuffer incoming data until DataSize bytes have
; been read.
usbPipeBufferDataSize	.equ	usbPipeBufferPtrPg + 1
; ReadPtr:
;  - If TX pipe, this is the pointer that indicates how much data has been
;    sent.  (This is updated only after a complete packet is sent to the FIFO.)
;  - If RX pipe, this is used for ReadRxBuffer.
usbPipeBufferReadPtr	.equ	usbPipeBufferDataSize + 2
usbPipeBufferReadPtrPg	.equ	usbPipeBufferReadPtr + 2
usbPipeBufferWritePtr	.equ	usbPipeBufferReadPtrPg + 1
 
; Pipe flags
;usbPipeFlagCbOnIntr	.equ	01h
;usbPipeFlagCbOnIntrB	.equ	0
usbPipeFlagCbIsTable	.equ	02h
usbPipeFlagCbIsTableB	.equ	1
; For TX:
;  - Automatically break up TX into max-size packets, except the last.
;  - You can use Write[Control]Packet to send individual packets if you don't
;    want autobuffering.
; For RX:
;  - Automatically buffer every RX into the RAM buffer.
;  - If not set, no data are read from buffer.  Your call back must manually
;    read the data.
usbPipeFlagAutoBuffer	.equ	04h
usbPipeFlagAutoBufferB	.equ	2
; Set to call the call back after every TX/RX packet.
usbPipeFlagCbEveryXmit	.equ	08h
usbPipeFlagCbEveryXmitB	.equ	3
; Probably remove this?
usbPipeFlagSendNull	.equ	10h
usbPipeFlagSendNullB	.equ	4
; If not autobuffer:
;  - TX pipe: This is set when you send a packet, and reset when it's done
;    sending.
;  - RX pipe: This flag is ignored.
; If autobuffer:
;  - This is set until DataSize bytes have been sent.  After that, ActiveXmit
;    is reset and DataProcCb is called.
usbPipeFlagActiveXmit	.equ	20h
usbPipeFlagActiveXmitB	.equ	5
; For TX pipe:
;  - This is set if you use the write buffer function and the buffer is full.
; For RX pipe:
;  - This is set when the RX buffer is full.
usbPipeFlagBufferFull	.equ	40h
usbPipeFlagBufferFullB	.equ	6
; For TX pipe:
;  - This is set when all possible bytes in buffer have been sent.
; For RX pipe:
;  - This is set when you have read all possible bytes from the buffer.
; Note that this can be set at the same time as the BufferFull flag.  This
; would happen when the buffer has been filled, and all bytes have been read
; from it.  For example, for a TX pipe, you've used WriteTxBufferByte until it's
; full, thereby setting BufferFull, and then the driver has sent all bytes,
; thereby setting BufferEmpty.  (Not a concern if you manually add bytes to the
; buffer.)
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