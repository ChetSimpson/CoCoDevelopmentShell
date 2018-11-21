******************************************************************************
*	Copyright (c) 1996, 1997, 2004, 2018, by Chet Simpson
*	
*	This file is distributed under the MIT License. See notice at the end
*	of this file.
*
******************************************************************************

**********************************
* binary ram loader
*
								opt     nol
				lib   ..\system\public.inc
execjmp     fdb   $00
count			fcb	$00

loader
				orcc  #$50        * disable IRQ's
				if		doscreen
* set video mode
				lda   #MMUEN+MC3+MC2
				sta   INIT0
				ldx   #CCVMR
				ldd   #$0315
				std   ,x                * Set video mode register
				leax  4,x               * skip next bytes (to $ff9c)
				clra
				clrb
				std   ,x++              * reset $ff9c,$ff9d
				std   ,x++              * reset $ff9e, $ff9f

* Set palettes and boarder color
				ldx   #PALSLOTS         * point to palette slots
				ldd   #$0110            * set all 16 to dark blue
loaderc0    sta   ,x+
				decb
				bne   loaderc0
				sta   $ff9a
				endif

				ldu   #binary     * point to binary data
loader0		inc	count
				lda   ,u+         * get header type
				ldy   ,u++        * get size
				ldx   ,u++        * get address/exec
				tsta					* copy it?
				beq   copyblock   * yes
				cmpa  #$FF        * execute it?
				bne   error       * nope, error
execute     stx   execjmp     * save exec jump
				jmp   [execjmp]

error			clr   $400
				sta	$401
				lda	count
				sta	$402
error0		bra   error0

copyblock   lda   ,u+         * get byte from buffer
				sta   ,x+         * save in memory
				leay  -1,y        * done yet?
				bne   copyblock   * nope
				bra   loader0     * go do next block



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
