******************************************************************************
*	Copyright (c) 1996, 1997, 2004, 2018, by Chet Simpson
*	
*	This file is distributed under the MIT License. See notice at the end
*	of this file.
*
******************************************************************************
*
***********************************************
* 6550/6551 Serial driver public include file *
***********************************************


***Control register constants***
*
* Baud rate constants
*
Baud300        equ   6
Baud600        equ   7
Daud1200       equ   8
Baud2400       equ   10
Baud4800       equ   12
Baud9600       equ   14
Baud19200      equ   15
*
* Word length constants
*
WordLen5       equ   $60
WordLen6       equ   $40
WordLen7       equ   $20
WordLen8       equ   $00
*
* Stop bit constants
*
StopBit1       equ   $00
StopBit2       equ   $80
*
* Clock generator source
*
ClockExt       equ   $00   * External clock source
ClockGen       equ   $10   * Internal baud rate generator

***Command register constants***
*
* Parity constants
*
ParityNone     equ   $00
ParityOdd      equ   $20
ParityEven     equ   $60
ParityMark     equ   $80
ParitySpace    equ   $e0
*
* Echo more for receiver
*
EchoNormal     equ   $00
EchoEcho       equ   $10
*
* Data terminal ready
*
DTRDisable     equ   $00
DTREnable      equ   $01
*
* Receiver IRQ enable
*
RIRQEnable     equ   $00
RIRQDisable    equ   $02
*
* Transmitter IRQ enable
*
TIRQDisableHO  equ   $00
TIRQEnableLO   equ   $04
TIRQDisableLON equ   $08
TIRQDisableBrk equ   $0c



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
