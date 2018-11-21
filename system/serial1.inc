******************************************************************************
*	Copyright (c) 1996, 1997, 2004, 2018, by Chet Simpson
*	
*	This file is distributed under the MIT License. See notice at the end
*	of this file.
*
******************************************************************************
*
*************************************************
* 6550/6551 Serial driver internal include file *
*************************************************
*
* Port locations for serial port 1
*
ACIA1_data     equ   $ff68
ACIA1_status   equ   $ff69
ACIA1_command  equ   $ff6a
ACIA1_control  equ   $ff6b
*
* Port locations for serial port 2
*
ACIA2_data     equ   $ff6c
ACIA2_status   equ   $ff6d
ACIA2_command  equ   $ff6e
ACIA2_control  equ   $ff6f
*
*  Offset for com port table
*
Offset_data    equ   0
Offset_status  equ   2
Offset_command equ   4
Offset_control equ   6
*
*
* Status register definitions
*
STAT_parity    equ   $01   * Parity error
STAT_framing   equ   $02   * framing error
STAT_overrun   equ   $04   * data overrun error
STAT_recvfull  equ   $08   * reveiver data register full
STAT_tranfull  equ   $10   * transmit data register full
STAT_DCD       equ   $20   * Device carrier detect
STAT_DSR       equ   $40   * 
STAT_IRQ       equ   $80   * IRQ enable
*
* Command register definitions
*
CMND_ParityMsk equ   $d0   * parity bit mask locations
CMND_ParityNon equ   $00   * Set for no parity
CMND_ParityOdd equ   $20   * Set for odd parity
CMND_ParityEvn equ   $60   * Set for Even parity
CMND_ParityMrk equ   $80   * Set for mark parity
CMND_ParitySpc equ   $d0   * Set for space parity

CMND_EchoMask  equ   $10   * Echo bit mask location
CMND_EchoEcho  equ   $10   * Set for echo

CMND_DTRMask   equ   $01  * Data terminal ready
CMND_DTREnable equ   $01  * Enable reciever and all IRQ's (DTR low)

CMND_RIEMask   equ   $02  * Reciever interrupt enable
CMND_RIEDisable   equ   $02   * Disable IRQ

CMND_TranMask  equ   $0c   * Transmission control mask
CMND_TranDHOFF equ   $00   * IRQ Disabled, RTS high, transmitter off 
CMND_TranELON  equ   $04   * IRQ Enabled, RTS low, transmitter on
CMND_TranDLON  equ   $08   * IRQ Disabled, RTS high, transmitter on
CMND_TranDLBRK equ   $0c   * IRQ disabled, RTS low, transmit break
*
* Control register items
*
CONT_StopMask  equ   $80   * Stop bits mask
CONT_stopbit1  equ   $00   * 1 stop bit
CONT_stopbit2  equ   $80   * 2 stop bit

CONT_WordMask  equ   $60   * Word length mask
CONT_Word5     equ   $60   * 5bit
CONT_Word6     equ   $40   * 6 bits
CONT_Word7     equ   $20   * 7 bits
CONT_Word8     equ   $00   * 8 bits

CONT_ClockMask equ   $10   * Clock source mask
CONT_ClockExt  equ   $00   * External clock source
CONT_ClockGen  equ   $10   * Internal baud rate generator

CONT_BaudMask  equ   $0f   * Baud rate mask



******************************************************************************
*	
*	Copyright (c) 1996, 1997, 2004, 2018, by Chet Simpson
*	
*	Permission is hereby granted, free of charge, to any person
*	obtaining a copy of this software and associated documentation
*	files (the "Software"), to deal in the Software without
*	restriction, including without limitation the rights to use,
*	copy, modify, merge, publish, distribute, sublicense, and/or sell
*	copies of the Software, and to permit persons to whom the
*	Software is furnished to do so, subject to the following
*	conditions:
*	
*	The above copyright notice and this permission notice shall be
*	included in all copies or substantial portions of the Software.
*	
*	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
*	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
*	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
*	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
*	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
*	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
*	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
*	OTHER DEALINGS IN THE SOFTWARE.
*	
******************************************************************************
