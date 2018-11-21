******************************************************************************
*	Copyright (c) 1996, 1997, 2004, 2018, by Chet Simpson
*	
*	This file is distributed under the MIT License. See notice at the end
*	of this file.
*
******************************************************************************

*
*
*
				org	$dd00

game_daemon     equ     $1      * 0=no, 1=yes


vectors		rmb	128

				lib   ..\system\scos.asm
startmarker	equ	*
				lib   input.asm
				lib   command.asm
				ifn	game_daemon
				lib   download.asm
				endif

				ifn	game_daemon
copyright   fcb   $0c
				fcc   "MediaLink MC6809/HT6309 CDS V1.1 [BETA]"
				fcb   $0d
				fcc   "Copyright (c) 1996 MediaLink Development Systems"
				fcb   $0d
				fcc   "Written by Chet Simpson"
				fcb   $0d,$0d
PromptText  fcc   "CoCo:"
				fcb   $00
				endif

				if		game_daemon
startupcmd		fcc		"run SAINT1.MLB"
				fcb		$0d,$00
				endif


errormsgs   fdb   unknownerr
				fdb   diskfull
				fdb   writeprot
				fdb   filestruct
				fdb   verifyerr
				fdb   filenotfnd
				fdb   filemode
				fdb   diskio
				fdb   alreadyopen

unknownerr  fcc   "Unknown"
				fdb   $0d00
errormsg		fcz	"Error: "
diskfull    fcz   "Disk full"
writeprot   fcz   "Write Protect"
filestruct  fcz   "File structure"
verifyerr   fcz   "Verify"
filenotfnd  fcz   "File not found"
filemode    fcz   "File mode"
diskio      fcz   "Disk I/O"
alreadyopen fcz   "File is already open."

errorhand	cmpb	#$05
				bne	errhnd1
				pshs	b
				lda	#'[
				jsr	SysPutChar
				ldx	#DNAMBF
				ldb	#$08
errhnd0		lda	,x+
				jsr	SysPutChar
				decb
				bne	errhnd0
				lda	#'.
				jsr	SysPutChar
				ldb	#$03
errhnd00		lda	,x+
				jsr	SysPutChar
				decb
				bne	errhnd00

				lda	#']
				jsr	SysPutChar
				lda	#$20
				jsr	SysPutChar
				puls	b
errhnd1		ldx	#errormsg
				jsr	printf
				ldx   #errormsgs
				cmpb  #$08
				bls   errorhand0
				clrb
errorhand0  aslb
				abx
				ldx   ,x
				jsr   printf
				jsr	MOTOFF
				if		game_daemon
@a				bra	@a
				endif
				ifn	game_daemon
				lda	#$0d
				jsr	SysPutChar
				jmp   exec0
				endif


exec        jsr   [v_initsystem]
				orcc  #$50
				ldx   #errorhand        * point to new error handler
				stx   DERROR+1          * set new error handler

				ifn	game_daemon
				ldb   #$01
				stb   sys_comport
				ldx   #copyright
				jsr   printf
				lda	#$40
				sta	MMUT0
				lda	#$38
				pshs	a,u
				clra
				clrb
				tfr   d,x
				tfr   d,y
@a				ldu	#$2000
@b				pshu	d,x,y		; clear 64 bytes
				pshu	d,x,y
				pshu	d,x
				cmpu	#$00
				bne	@b
				inc	MMUT0
				dec	,s
				bne	@a
				puls	a,u

exec0       ldx   #PromptText
				jsr   printf
				jsr   LineInput
				cmpa  #$80
				blo	@a
				jsr	srv_request
				lda	#$0d
				jsr	SysPutChar
				bra	exec0
@a				ldx   #linputbuf
				jsr   ParseLine
				stb   $e00
				pshs  b
				tfr   a,b
				aslb
				ldx   #commandjmp
				abx
				puls  b
				jsr   [,x]
				bra   exec0
				endif
;
; Used to load a single program
;
				if		game_daemon
				ldx	#linputbuf
				ldy	#startupcmd
@a				lda	,y+
				sta	,x+
				tsta
				bne	@a
				jsr	CommandRun
				ldx   #linputbuf
				jsr   ParseLine
				stb   $e00
				pshs  b
				tfr   a,b
				aslb
				ldx   #commandjmp
				abx
				puls  b
				jsr   [,x]
@b				bra	@b
				endif
				opt	l
endmarker	equ	*
				opt	nol
				end   exec



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
