******************************************************************************
*	Copyright (c) 1996, 1997, 2004, 2018, by Chet Simpson
*	
*	This file is distributed under the MIT License. See notice at the end
*	of this file.
*
******************************************************************************
*
****************************************************
* 80x28 video screen driver
*

SCREENMMU   equ   $7c
SCREENADDR  equ   $8000
SCREENMMUS  equ   MMUT0+4

*
*  Vector entry points
*
screen_start equ   *
   org   screen_vectors
   fdb   InitScreen     * set stat
   fdb   screennull     * get stat
   fdb   screennull     * reset
   fdb   ClearScreen    * clear screen
   fdb   ScreenOut      * Screen out
   fdb   screennull     * reserved
   fdb   screennull     * reserved
   fdb   screennull     * reserved
   org   screen_start

screenaddr  fdb   $0000
screenx     fcb   $00
screeny     fcb   $00
screenattr  fcb   $00



screennull  clra
            rts

**********************************
* Init the screen driver
*
InitScreen     pshs  b,x,y
* Init 80x25 hardware text screen
               jsr   ClearScreen
               ldd   #$0315
               std   CCVMR             * Set video mode register
               clr   CCVSR             * Set video scroll register
               ldd   #$f000
               std   CCVOR0            * Set vertical offset register
               clr   CCHOR             * Set horizontal offset register
               lda   #$01
               sta   CCBRDR            * Set boarder color
               sta   PALSLOTS          * set background
               sta   PALSLOTS+15
               lda   #$ff
               sta   PALSLOTS+7
               sta   PALSLOTS+8        * set forground


               lda   #$ff
               sta   sys_vterm         * set to use video terminal
               bsr   CursorOn          * turn the cursor on
               clra
               puls  b,x,y,pc


**********************************
* turn the cursor off
*
CursorOff      pshs  a,x
               lda   screenattr
               bra   SetCursor
**********************************
* turn the curson on
*
CursorOn       pshs  a,x
               lda   screenattr
               coma
**********************************
* Set the cursor
SetCursor      anda  #$3f
               ldx   screenaddr
               ldb   SCREENMMUS     * get old mmu block
               pshs  b              * save on stack
               ldb   #SCREENMMU     * get mmu used for screen
               stb   SCREENMMUS     * set it
               sta   1,x
               puls  b
               stb   SCREENMMUS
               puls  a,x,pc




**********************************
* Clear the screen
*
ClearScreen    pshs  d,x
ClearScreen0   lda   SCREENMMUS
               pshs  a
               lda   #SCREENMMU
               sta   SCREENMMUS
               ldx   #SCREENADDR
               stx   screenaddr
               clr   screenx
               clr   screeny
               lda   #$20
               ldb   screenattr
ClearScreen5   std   ,x++
               cmpx  #SCREENADDR+$f00
               blo   ClearScreen5
               puls  a
               sta   SCREENMMUS
               puls  d,x,pc

**********************************
*
*
PutChar        
ScreenOut      cmpa  #$7f           * non printable character
               blo   ScreenOut0    * yes, exit
               rts
ScreenOut0     pshs  d,x            * save registers
               jsr   CursorOff      * turn the cursor off
               cmpa  #$20           * ascii char?
               bhs   ScreenOut50    * yes
* process control code
               cmpa  #$0c           * clear screen code?
               beq   ClearScreen0   * yes, clear it
               cmpa  #$0d           * CR code?
               beq   ScreenEnter    * yes
               cmpa  #$08           * backspace char?
               beq   ScreenBS       * yes
               bra   ScreenOut98    * non supported control code, exit
* output an ascii character
ScreenOut50    ldb   SCREENMMUS     * get old mmu block
               pshs  b              * save on stack
               ldb   #SCREENMMU     * get mmu used for screen
               stb   SCREENMMUS     * set it
               ldb   screenattr     * get attribute
               ldx   screenaddr     * point to current position
               std   ,x++           * store character
               stx   screenaddr     * set new screen address
               jsr   CursorOn       * reset the cursor
               puls  b              * get old mmu
               stb   SCREENMMUS     * set it

* increment column position and wrap if needed
IncScreenX     inc   screenx        * go to next column
               lda   screenx        * get column
               cmpa  #80            * scrolled to next line?
               bne   ScreenOut98    * no, return

ScreenEnter    ldx   screenaddr
               inc   screeny        * go to next line
               ldb   #80
               subb  screenx
               aslb
               abx
               stx   screenaddr

               clr   screenx        * yes, set to start of line
               lda   screeny        * get line count
               cmpa  #24            * end of screen?
               bne   ScreenOut98    * nope, return
* yes, reset and stay at bottom line
               dec   screeny        * go back up one line count
               leax  -160,x         * adjust for 80 characters with attrib's
               stx   screenaddr     * adjust
               jsr   ScrollUp       * scroll the screen up

ScreenOut98    jsr   CursorOn       * turn the cursor on
               puls  d,x,pc
ScreenOut99    rts

ScreenBS       tst   screenx        * start of line?
               beq   ScreenBS25     * no, do it
               dec   screenx
               bra   ScreenBS50

ScreenBS25     tst   screeny        * start of screen?
               beq   ScreenOut99    * yes, do nothing
               lda   #79            * move to end of line
               sta   screenx        
               dec   screeny        * go up one line
              
ScreenBS50     ldx   screenaddr     * get screen address
               leax  -2,x           * adjust it one character
               lda   #$20           * lets erase whats there
               sta   ,x             *
               stx   screenaddr     * set it
               bra   ScreenOut98    * go turn cursor back on and return



ScrollUp       pshs  y
               ldb   SCREENMMUS     * get screen mmu
               pshs  b              * save on stack
               ldb   #SCREENMMU     * get mmu used for screen
               stb   SCREENMMUS     * set it
               ldx   #SCREENADDR    * point to start of screen
               ldy   #SCREENADDR+160   * point to next line
ScrollUp10     ldd   ,y++           * copy up
               std   ,x++
               ldd   ,y++
               std   ,x++
               ldd   ,y++
               std   ,x++
               ldd   ,y++
               std   ,x++
               cmpx  #SCREENADDR+$e60  * at the end of the scroll?
               blo   ScrollUp10        * nope, keep going

               ldy   #80            * clear 80 chars at bottom
               ldb   screenattr     * get attribute
               lda   #$20           * get space char
ScrollUp20     std   ,x++           * clear
               leay  -1,y           * done yet
               bne   ScrollUp20     * nope, keep going
               puls  b              * get old mmu
               stb   SCREENMMUS     * set it
               puls  y,pc
               


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
