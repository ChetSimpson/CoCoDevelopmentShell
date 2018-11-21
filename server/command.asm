******************************************************************************
*	Copyright (c) 1996, 1997, 2004, 2018, by Chet Simpson
*	
*	This file is distributed under the MIT License. See notice at the end
*	of this file.
*
******************************************************************************

*********************************************************
* Command handler
*

msg_vsync	fcz	"VSYNC caught at:"

commandline fcz   "reset"
				fcz   "cls"
				fcz	"echo"
				fcz	"run"
				fcz   "load"
				fcz   "exec"
				fcz	"clear"
				fcc	"vsync"
				ifn	game_daemon
            fcb	$00
				fcc   "dir"
            endif
				fcb   $ff

unknowncmd  fcc   "Unknown command!"
				fcb   $0d,00
syntaxerr   fcc   "Syntax error in command line"
				fcb   $0d,00

commandjmp
				fdb   CommandNull
				fdb   CommandNull
				fdb	CommandRest
				fdb   CommandCls
				fdb	CommandEcho
				fdb	CommandRun
				fdb   CommandLoad
				fdb   CommandExec
				fdb	CommandClear
				fdb	CommandVsync
				ifn	game_daemon
				fdb   CommandDir
				endif


execjmp     fdb   execfault         * jump vector for EXEC command

****************************************************
* Find delimeter
*  enter:
*     x  - pointer to string
*  return:
*  accb  - size of string
FindDelim   pshs  x,a
				ldx   #linputbuf
            clrb
FindDelim0  lda   ,x+
				jsr   tolower
            cmpa  #$61
            blo   DelimFound
            cmpa  #$7a
            bhi   DelimFound
            incb
				bra FindDelim0
DelimFound  puls  x,a,pc
   

*****************************************************
* Parse an input line for commands
*  enter:
*     x  - pointer to string
*  return:
*  acca  - command occurance in table   
*
ParseLine   pshs  y,x,b          *save stuff on stack
				ldy   #commandline   * point to command table
				bsr   FindDelim      * find delimeter
				clra
				pshs  x,d            * save X and b
				cmpb  #$08           * larger than max command?
				bhi   ParseError     * yes, cause error
				tstb                 * Is there a line to parse?
				bne   Parse0         * yes
				lda   #$01           * no set to no line
				bra   ParseDone      * return

Parse0      inc   ,s             * increment command table occurance
				ldb   1,s            * restore b
				ldx   2,s            * restore X

Parse1      lda   ,x+            * get char from line
				jsr   tolower        * convert to lower case
				cmpa  ,y+            * Found a difference yet?
				bne   ParseNext      * yes, skip to next command
				decb                 * done with line yet?
				bne   Parse1         * nope, keep going

* No differences, check to see if at commands end
				lda   ,y             * Get character ad command pointer
				tsta                 * if its 0, we've found one
				beq   ParseFound     * go do something with it
				cmpa  #$ff           * if its ff we've found one
				beq   ParseFound     * go do something with it

* No match with this command do to the next one
ParseNext   lda   ,y+
				tsta
				beq   Parse0         * found next command go check
				cmpa  #$ff           * end of commands?
				beq   ParseError     * yup, no command found, error out
				bra   ParseNext      * Keep until we find end of this command

ParseFound  lda   ,s             * Get a count stack
				inca
				bra   ParseDone      * and go return
ParseError  clra                 * clear acca, cause error
ParseDone   leas  4,s
				puls  b,y,x,pc       * retrore regs and return

CommandNull rts
CommandRest jmp   exec

setstaterr  fcc   "SetStat error encountered"
				fcb   $0d,00

CommandVsync
				ldx	#msg_vsync
				jsr	printf
				lda	VSYNCSAVE
				jsr	PrintHex8
				lda	#$0d
				jmp	SysPutChar

CommandClear
				rts
CommandEcho	ldx   #linputbuf
				jsr	FindDelim
				tstb
				beq	CommandEcho5
				incb
				abx
CommandEcho0
				lda	,x+
				tsta
				beq	CommandEcho5
				cmpa	#$0d
				beq	CommandEcho5
				jsr	SysPutChar
				bra	CommandEcho0
CommandEcho5
				lda	#$0d
				jsr	SysPutChar
				rts

CommandCls  lda   #$0c
				jmp   SysPutChar

temp_flag0  equ   4
temp_sector equ   3
temp_entry  equ   2
temp_word   equ   0


unknownfile fcc   "Unknown filetype!"
				fdb   $0d00
eoferrmsg   fcc   "EOF Error!"
				fdb   $0d00
loadingmsg  fcc   "Loading. . ."
				fdb   $0d00

*
* Get word, return in X
*
loadgword   pshs  d        * save D
				jsr   DEVIN    * get msb of word
				pshs  a        * save
				jsr   DEVIN    * get msb of word
				tfr   a,b      * send to ACCB
				puls  a        * get msb again
				tfr   d,x      * send to X
				puls  D,pc     * get D and return

CommandRun	jsr	CommandLoad
				bcs	@a
				jmp	CommandExec
@a				rts

CommandLoad		pshs  d,x,y
				ldx   #DNAMBF
				ldd   #$2008
load0			sta   ,x+
				decb
				bne   load0
				ldd   #$4249
				std   ,x++
				lda   #'N
				sta   ,x
* find space
				ldx   #linputbuf
load1			lda   ,x+      * get character from buffer
				cmpa  #$0d     * CR?
				lbeq   loadserr * yes, error
				cmpa  #$20     * space?
				bne   load1    * nope, keep going
* get filename and extension
				ldy   #DNAMBF  * point to mdos filename buffer
				ldb   #$08     * max filename
load2			lda   ,x+      * get char
				cmpa  #$0d     * CR?
				beq   doload   * yes, load it
				cmpa  #'.      * extension delimeter?
				beq   loadext  * get get extension
				jsr   toupper  * convert to upper case
				sta   ,y+      * save in 
				decb           * done yet?
				bne   load2    * nope
				lda   ,x+      * get get character
				cmpa  #'.      * extension delim?
				beq   loadext  * yes get extension
				cmpa  #$0d     * CR?
				beq   doload   * yes
				bra   loadserr * nope, error in command line
loadext			ldb   #$03     * 3 chars max in extension
				ldy   #DNAMBF+8   * point to extension area
loadext1		lda   ,x+      * get char
				cmpa  #$0d     * CR?
				beq   doload   * yes, load it
				jsr   toupper  * convert to upper case
				sta   ,y+      * save it
				decb           * done yet?
				bne   loadext1 * nope
				lda   ,x
				cmpa  #$0d     * done yet?
				bne   loadserr
doload
				ldb   #$01     * get file handle
				jsr   OPENI    * open file for input
				stb   DEVNUM   * save device number of mdos
				ldx   #loadingmsg * point to message
				jsr   printf
loadhdr			jsr   DEVIN    * get header type
				jsr   loadgword   * get size
				tfr   x,y         * save in Y
				jsr   loadgword   * get address
				cmpa  #$00        * load block ?
				beq   loadblock   * yes
				cmpa  #$FF        * execution block?
				beq   loadexec    * yes
				ldx   #unknownfile   * get unknown file type message
				jsr   printf      * print it
				bra   loaddone
loadblock		tst   CINBFL      * end of file?
				bne   loadeoferr  * yup, end of file error
				jsr   DEVIN       * get char from file
				sta   ,x+         * save in memory
				leay  -1,y        * done yet?
				bne   loadblock   * nope, keep loading block
				bra   loadhdr     * go to next header
loadeoferr		ldx   #eoferrmsg  * point to message
				jsr   printf      * print it
				bra   loaddone    * cleanup and exit
loadexec		stx   execjmp
loaddone		ldb   #$01        * get file handle
				jsr   CLOSE       * close it
				jsr   MOTOFF
				andcc	#$fe
				puls  d,x,y,pc


loadserr		puls  d,x,y
				jsr   MOTOFF
				ldx   #syntaxerr
				orcc	#$01
				jmp   printf

CommandExec	pshs	a,b,x,y,u,cc,dp
				jsr   [execjmp]
				puls	a,b,x,y,u,cc,dp,pc
execfault   rts

				ifn	game_daemon
Dir		   fcc   "                             Directory of drive 0"
				fcb   $0d,$0d,00

CommandDir  pshs  d,x
				ldx   #Dir
				jsr   printf

				lda   #ss_readmode
				jsr   SETSTAT

				lda   #ss_track
				ldb   #17
				jsr   SETSTAT

				lda   #ss_drive
				clrb
				jsr   SETSTAT

				lda   #ss_buffer0
				jsr   SETSTAT

				leas  -5,s
				ldb  #$03
				stb   temp_sector,s
				lda   #ss_sector        * prepare to set sector
				decb							* get sector to set to
				jsr   SETSTAT				* go set it
				jsr   DSKCON		      * go read it

cdir0       lda   #ss_sector        * prepare to set sector
				ldb   temp_sector,s     * get sector to set to
				jsr   SETSTAT		      * go set it
				jsr   DSKCON		      * go read it
				lda   #$08              * get number of entries per sector
				sta   temp_entry,s      * save it
				ldx   #DBUF0            * point to buffer

cdir10      lda   ,x
				tsta                    * is entry empty?
				beq   cdir50            * yes, go next
				cmpa  #$ff              * at the end of the dir?
				beq   cdirdone          * yes, cleanup and exit

				ldb   #$08              * get number of chars to print
				stx   temp_word,s       * save x
* remove trailing spaces
				leax  7,x               * adjust to end of filename
cdir15      lda   ,x
				cmpa  #$20              * is it a space?
				bne   cdir17            * nope
				leax  -1,x
				decb                    * done checking?
				bne   cdir15            * nope, keep going
cdir17      ldx   temp_word,s       * restore x pointer
				pshs  b                 * save number of chars in filename
				lda   #12               * get tab skips
				suba  ,s+               * subtract number of chars in filename
				sta   temp_flag0,s      * save in flag area
				tstb                    * is this a blank line?
				beq   cdir25            * yes, print extension only
cdir20      lda   ,x+
				jsr   tolower           * convert to lowercase
				jsr   SysPutChar        * send char to screen
				decb                    * done yet?
				bne   cdir20            * nope
cdir25      ldd   #$2e03            * Get '.' and extension count
				jsr   SysPutChar        * output a space
				ldx   temp_word,s       * restore x pointer
				leax  8,x               * adjust to point to extension
cdir30      lda   ,x+
				jsr   tolower           * convert to lowercase
				jsr   SysPutChar        * output a space
				decb                    * done yet?
				bne   cdir30            * nope, keep going
				lda   #$20              * get space character
				ldb   temp_flag0,s      * get number of chars to print
cdir35      jsr   SysPutChar
				decb                    * done yet?
				bne   cdir35            * nope
				ldx   temp_word,s       * get x
cdir50      leax  $20,x             * adjust to next directory entry
				dec   temp_entry,s      * done with sector?
				bne   cdir10            * nope
				inc   temp_sector,s     * done with dir track?
				lda   temp_sector,s
				cmpa  #18
				blo   cdir0             * nope, keep going

cdirdone    leas  5,s
				jsr   MOTOFF
				lda   #$0d
				jsr   SysPutChar
				jsr   SysPutChar
				puls  d,x,pc
            endif



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
