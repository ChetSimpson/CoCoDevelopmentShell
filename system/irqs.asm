******************************************************************************
*	Copyright (c) 1996, 1997, 2004, 2018, by Chet Simpson
*	
*	This file is distributed under the MIT License. See notice at the end
*	of this file.
*
******************************************************************************
*
********************************************************
* Generic IRQ and SWI calls for system
*


ivec_FIRQ      equ   $fef4
ivec_IRQ       equ   $fef7
ivec_SWI       equ   $fefa
ivec_SWI2      equ   $fefe
ivec_SWI3      equ   $fef1
ivec_NMI       equ   $fefd



default_IRQ    lda   $ff03			* Get IRQ status
					bpl   IRQdone		* IF plus, it was not 60hz/50hz
					inc	VSYNCIRQ		* Increment count
					lda   $ff02			* Reset flag
IRQdone        rti


InitIRQS pshs  a,x,cc
			orcc  #$50

			lda   #$7e
			ldx   #default_IRQ
			sta   >ivec_IRQ
			stx   >ivec_IRQ+1

			ldx   #IRQdone
			sta   >ivec_FIRQ
			stx   >ivec_FIRQ+1

;			sta   >ivec_NMI
;			stx   >ivec_NMI+1

;			ldx   #default_SWI
;			sta   >ivec_SWI
;			stx   >ivec_SWI+1

;			ldx   #default_SWI2
;			sta   >ivec_SWI2
;			stx   >ivec_SWI2+1

;			ldx   #default_SWI3
;			sta   >ivec_SWI3
;			stx   >ivec_SWI3+1

			clr	>VSYNCIRQ

			puls  a,x,cc,pc




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
