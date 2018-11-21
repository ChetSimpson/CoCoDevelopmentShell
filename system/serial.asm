******************************************************************************
*	Copyright (c) 1996, 1997, 2004, 2018, by Chet Simpson
*	
*	This file is distributed under the MIT License. See notice at the end
*	of this file.
*
******************************************************************************
*
***************************
* 6550/6551 Serial driver *
***************************

         lib   serial.inc
         lib   serial1.inc

************************************************************************
* Vector entry points
*
serial_start   equ   *
               org   serial_vectors
               fdb   serialnull
               fdb   serialnull
               fdb   serialnull
               fdb   serialnull
               fdb   serialnull
               fdb   sGetChar
               fdb   sPutChar
               fdb   serialnull
               org   serial_start


serialnull     clra
               rts



************************************************************************
* Macro definitions
*
getaciatable   macro
               ldx   #ComPorts         * point to com port table
               aslb                    * adjust port number
               abx                     * add it to the table offset
               ldx   ,x                * point to specified port table
               endm




************************************************************************
*  Port lookup tables
*
ComPorts fdb   $0000       * Null com port
         fdb   ComPort1
         fdb   ComPort2
*
* Com port 1 locations
*
ComPort1 fdb   ACIA1_data
			fdb   ACIA1_status
         fdb   ACIA1_command
         fdb   ACIA1_control
*
* Com port 2 locations
*
ComPort2 fdb   ACIA2_data
         fdb   ACIA2_status
         fdb   ACIA2_command
         fdb   ACIA2_control

************************************************************************
* Initialize serial port at 19200, 8, n, 1
*
InitACIA pshs  d
         jsr   ResetACIA
			lda   #Baud19200
			bsr   SetBaud
			lda   #WordLen8
			bsr   SetWord
			lda   #StopBit1
			bsr   SetStop
			lda   #ParityNone
			jsr   SetParity
			lda   #ClockGen
			jsr   SetClock

* Set command register
			lda   #EchoNormal
			jsr   SetEcho
			lda   #DTREnable
			jsr   SetDTR
			lda   #RIRQDisable
			jsr   SetRIRQ
			lda   #TIRQDisableLON
			jsr   SetTIRQ
			puls  d,pc

************************************************************************
* Get a character from the serial port. On return:
* cc = clear: Character not recieved
* cc = set: Character recieved
*
sGetChar pshs  x,b                        * Save registers
			getaciatable            	* Point to ACIA register table
			lda   	[Offset_status,x]	* Get status bit
			anda  	#STAT_recvfull    * have we recieved a char?
			beq   	NoChar            * No data available
			lda   	[Offset_data,x]	* get data
			orcc  	#$01              * Set data there
                        puls    b,x,pc            * return
NoChar   andcc 	#$fe              * Clear carry flag, no data
			clra
                        puls    b,x,pc            * return

************************************************************************
* Put character to the serial port
*  Enter:
*     ACCA  byte to put
*     ACCB  Port number
*
sPutChar pshs  x,b               *save x
			getaciatable            * Point to ACIA register table
sPutWait ldb   [Offset_status,x]	* Get status register
			andb  #STAT_tranfull    * Is the transmission buffer full?
			beq   sPutWait          * yes, wait until its available
			sta   [Offset_data,x]		* Send data
			puls  b,x,pc

************************************************************************
* Set the baud rate for something else
*
SetBaud  pshs  x,d	               * Save registers
			getaciatable               * Point to ACIA register table
			lda   [Offset_control,x]     * Get current control register
			anda  #~CONT_BaudMask      * mask out current baud rate
			ora   ,s                   * or in new baud value
			sta 	[Offset_control,x]     * Set control register
			puls  d,x,pc               * return

************************************************************************
* Set word length
*
SetWord  pshs  x,d	               * Save registers
			getaciatable               * Point to ACIA register table
			lda   [Offset_control,x]   	* Get current control register
			anda  #~CONT_WordMask      * mask out current word value
			ora   ,s	                  * or in new word
			sta   [Offset_control,x]   	* Set control register
			puls  d,x,pc               * return

************************************************************************
* Set stopbits
*
SetStop  pshs  x,d                * Save registers
			getaciatable               * Point to ACIA register table
			lda   [Offset_control,x]   * Get current control register
			anda  #~CONT_StopMask     * mask out current stop bits
			ora   ,s	                  * or in new stop bits
			sta   [Offset_control,x]   * Set control register
			puls  d,x,pc               * return

************************************************************************
* Set clock source
*
SetClock pshs  x,d                * Save registers
			getaciatable               * Point to ACIA register table
			lda   [Offset_control,x]   * Get current control register
			anda  #~CONT_ClockMask     * mask out current clock type
			ora   ,s                  * or in new clock type
			sta   [Offset_control,x]   * Set control register
			puls  d,x,pc               * return


************************************************************************
* Set parity bits
*
SetParity   pshs  x,d             * Save registers
			getaciatable               * Point to ACIA register table
			lda   [Offset_command,x]   * Get current command register
			anda  #~CMND_ParityMsk     * mask out current parity type
			ora   ,s                  * or in new parity
			sta   [Offset_command,x]   * Set command register
			puls  d,x,pc               * return

************************************************************************
* Set Echo
*
SetEcho     pshs  x,d                * Save registers
				getaciatable               * Point to ACIA register table
				lda   [Offset_command,x]   * Get current command register
				anda  #~CMND_EchoMask      * mask out current echo value
				ora   ,s                  * or in new echo value
				sta   [Offset_command,x]   * Set command register
				puls  d,x,pc               * return

************************************************************************
* Set DTR
*
SetDTR      pshs  x,d                * Save registers
				getaciatable               * Point to ACIA register table
				lda   [Offset_command,x]	   * Get current command register
				anda  #~CMND_DTRMask       * mask out current DTR value
				ora   #CMND_DTRMask	      * or in new DTR
SetDTR0		sta   [Offset_command,x]	   * Set command register
				puls  d,x,pc               * return

************************************************************************
* Set Receiver IRQ
*
SetRIRQ     pshs  x,d                * Save registers
				getaciatable               * Point to ACIA register table
				lda   [Offset_command,x]   * Get current command register
				anda  #~CMND_RIEMask       * mask out current reciever IRQ value
				ora   ,s                  * or in new receiver IRQ value
				sta   [Offset_command,x]   * Set command register
				puls  d,x,pc               * return

************************************************************************
* Set Receiver IRQ
*
SetTIRQ     pshs  x,d                * Save registers
				getaciatable               * Point to ACIA register table
				lda   [Offset_command,x]   * Get current command register
				anda  #~CMND_TranMask      * mask out current transmitter irq
				ora   ,s                  * or in new transmitter irq value
				sta   [Offset_command,x]   * Set command register
				puls  d,x,pc               * return

************************************************************************
* Reset the acia chip
*
ResetACIA   pshs  d,x                  * Save registers
				getaciatable               * Point to ACIA register table
				clr   [Offset_status,x]    * Clear status register (reset)
				puls  d,x,pc               * return

************************************************************************
* DetectACIA chip
* return:
*  cc clear: not present
*  cc cc set: acia present
DetectACIA  pshs  d,x                * Save registers
				getaciatable               * Point to ACIA register table
				lda   [Offset_command,x]   * Get command register
				coma                       * compliment it
				sta   [Offset_command,x]   * store new value
				cmpa  [Offset_command,x]   * Is it the same...see later
				coma                       * compliment it again
				sta   [Offset_command,x]   * restore original value
				beq   DetectYes            * Yes it is there.
				andcc #$fe                 * clear carry
				puls  d,x,pc             * return
DetectYes   orcc  #$01                 * set carry
				puls  d,x,pc             * return



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
