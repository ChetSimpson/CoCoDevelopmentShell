******************************************************************************
*	Copyright (c) 1996, 1997, 2004, 2018, by Chet Simpson
*	
*	This file is distributed under the MIT License. See notice at the end
*	of this file.
*
******************************************************************************
*
*  Main system functions (currently undefined)
*
system_start	equ		*
				org		system_vectors
				fdb		InitSystem
				fdb		PrintHex8
				fdb		INKEY
				fdb		systemnull
				fdb		systemnull
				fdb		systemnull
				fdb		systemnull
				fdb		systemnull
				fdb		systemnull
				fdb		systemnull
				fdb		systemnull
				fdb		systemnull
				fdb		systemnull
				fdb		systemnull
				fdb		SysPutChar
				fdb		xprintf
				org		system_start

systemnull		clra
				rts

				rmb   127
systemstack		rmb   1


InitSystem		puls	d                 * get return pc
				clr		113
				orcc	#$50              * disable interrupts
* setup the stacks and other system pointers
				lds		#systemstack      * point to new system stack
				pshs	d                 * save return pc onto new stack
				clr		$ffd9             * Set for 2mhz mode
* Set up init reg 0
				lda		#MMUEN+MC3+MC2    * Enable MMU, make $FExx constant,
				sta		INIT0             * and enable SCS ($ff40-$ff5f).
* Clear the palettes
				if		game_daemon
				ldx		#PALSLOTS         * point to palette slots
				ldb		#$10              * there are 16 of them
InitSys10		clr		,x+               * set to 0
				decb                    * done yet?
				bne		InitSys10         * Nope
				clr		$ff9a					* Clear border
				endif
* Set up MMU slots for task 0 and 1
				ldx		#MMUT0            * poin to mmu task 0
				lda		#$78              * Get starting MMU block
				ldb		#$08              * only 8 per task
InitSys20		sta		8,x               * set task 1
				sta		,x+               * set task 0
				inca
				decb                    * done yet?
				bne		InitSys20         * nope, keep going

* Init the system
				jsr		InitIRQS          * Init interrupt service routines
				ifn		game_daemon
				jsr		InitScreen        * Init hardware video terminal
				ldb		#$01
				jsr		InitACIA          * Init serial device (port 1)
				incb
				jsr		InitACIA          * Init serial device (port 2)
				endif
				jsr		InitMDOS          * Init MDOS
				rts



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
