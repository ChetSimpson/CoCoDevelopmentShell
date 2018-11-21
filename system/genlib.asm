******************************************************************************
*	Copyright (c) 1996, 1997, 2004, 2018, by Chet Simpson
*	
*	This file is distributed under the MIT License. See notice at the end
*	of this file.
*
******************************************************************************
*
* General interface library*
*

sys_comport fcb   $00   * Com port to use to get a key from
sys_vterm   fcb   $00   * Use video terminal?
*
* Get a single key from keyboard or serial port
*
				if		game_daemon
PutChar		rts
				endif

SysGetChar  	pshs  x,b
SysGetChar0
				ifn	game_daemon
				tst   sys_comport
				beq   SysGetSkip
				ldb   sys_comport
				jsr   sGetChar
				bcs   SysGotChar
	            endif
SysGetSkip		jsr   INKEY
            	beq   SysGetChar0
SysGotChar  	puls  x,b,pc
*
*
*
SysPutChar  	pshs  b
				ifn   game_daemon
				tst   sys_comport
				beq   SysPutSkip
				ldb   sys_comport
				jsr   sPutChar
            	endif
SysPutSkip  	tst   sys_vterm
            	beq   SysPutDone
            	jsr   PutChar
SysPutDone  	puls  b,pc



************************************************************************
* Print string to serial port
*
printf      pshs  a,x
printf0     lda   ,x+
            beq   printf1
            bsr   SysPutChar
				bra   printf0
printf1     puls  a,x,pc

xprintf     pshs  a,x
				tst   sys_vterm
				beq   xprintf1
xprintf0    lda   ,x+
				beq   xprintf1
				jsr   PutChar
				bra   xprintf0
xprintf1    puls  a,x,pc


****************************************************
* Convert character to lower case
*  enter:
*     acca - char to convert
*  return:
*     acca - converted char
*
tolower     cmpa  #$40
            bls   nolower
            cmpa  #$5b
            bhs   nolower
            ora   #$20
nolower     rts

****************************************************
* Convert character to upper case
*  enter:
*     acca - char to convert
*  return:
*     acca - converted char
*
toupper     cmpa  #$60
            bls   nolower
				cmpa  #$7b
            bhs   nolower
            anda  #$df
            rts

****************************************************
* Print register ACCA or ACCD as hex number
*
HexTable       fcc   "0123456789ABCDEF"

PrintHex8      pshs  d,x
               ldx   #HexTable
               tfr   a,b
               lsra
               lsra
               lsra
               lsra
               anda  #$0f
               lda   a,x
					jsr   SysPutChar
					tfr   b,a
					anda  #$0f
					lda   a,x
               jsr   SysPutChar
               puls  d,x,pc

PrintHex16     pshs  d
               bsr   PrintHex8
               tfr   b,a
               bsr   PrintHex8
               puls  d,pc



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
