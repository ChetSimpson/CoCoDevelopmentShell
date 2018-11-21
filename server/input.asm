******************************************************************************
*	Copyright (c) 1996, 1997, 2004, 2018, by Chet Simpson
*	
*	This file is distributed under the MIT License. See notice at the end
*	of this file.
*
******************************************************************************

***************************************************
* Get a line or key from the keyboard/serial port *
***************************************************

***************************************************************
* Input a CR terminated line from the keyboard or serial port
*
MaxLIBuf    equ   85

linputbuf   zmb   MaxLIBuf
linepos     zmb   1
*
* Erase the line
*
LI_erase    tst   linepos     * Can we erase anymore?
            beq   LI_erase1   * No, return
            lda   #$08        * yes, get backspace char
            jsr   SysPutChar  * Put it out
            dec   linepos     * Decrement count
            bra   LI_erase    * Keep going
LI_erase1   rts               * return

            
*
LineInput   pshs  x
            ldx   #linputbuf  * Point to input buffer
            clr   linepos     * Reset line position
LI0         jsr   SysGetChar  * Go get a key
            cmpa  #$20        * Is it ascii?
            blo   LI_control  * No...do something with it.
            cmpa  #$80        * Is it server control?
            bhs   LI_server   * yes, return with it.
            pshs  a           * save the character
            lda   linepos
            cmpa  #MaxLIBuf-1 * Are we already at the end of the buffer?
            puls  a           * restore character before checking
            blo   LI5         * nope, not yet
            bra   LI0         * yup, we sure are
LI5         jsr   SysPutChar  * put it to devices
            sta   ,x+         * Store it into buffer
            inc   linepos     * go up a position
            bra   LI0
*
* Check control characters
*
LI_control  cmpa  #$08        * backspace?
            bne   LI_con0     * Nope, go to next
            tst   linepos     * Is there anything to backspace?
            beq   LI0         * No, so why do it
            dec   linepos     * go back one
            leax  -1,x
            jsr   SysPutChar  * Yeah, let io process it
            bra   LI0         * Continue getting input

LI_con0     cmpa  #$0d        * Carriage return?
            bne   LI_con5     * No, see next
            jsr   SysPutChar  * output it so we hit the next line
            sta   ,x          * save character
            clra              * clear return condition
            puls  x,pc        * return

LI_con5     bra   LI0         * no other control keys to check
*
* Return server code
*
LI_server   pshs  a
            jsr   LI_erase    * erase the line
LI_serv5    puls  a,x,pc      * return



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
