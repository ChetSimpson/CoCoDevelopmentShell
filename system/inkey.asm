******************************************************************************
*	Copyright (c) 1996, 1997, 2004, 2018, by Chet Simpson
*	
*	This file is distributed under the MIT License. See notice at the end
*	of this file.
*
******************************************************************************
*
*
*/INKEY.ASM
*

CASE   FCB $FF
DEBNCE FDB $045E
KEYBUF FCB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
REPT1  FCB $00
REPT2  FCB $00
REPT3  FCB $00
REPSPD FCB $30
REPTIM FCB $08
*
* Special keys values (unshifted,shifted) 
*
TABLE EQU *
 FCB $0B,$5F Up arrow
 FCB $0A,$5B Down arrow
 FCB $08,$15 Left arrow
 FCB $09,$5D Right arrow
 FCB $20,$20 Space bar
 FCB $30,$12 Zero key
 FCB $0D,$0D [ENTER]
 FCB $0C,$5C [CLEAR]
 FCB $03,$1B [BREAK]
 FCB $00,$00 [ALT]
 FCB $00,$00 [CTRL]
 FCB $00,$00 F1,SF1 [F1]
 FCB $00,$00 F2,SF2 [F2]
 FCB '@,$5E  [@] "at"
*
REPEAT LDX #KEYBUF
REP0 LDA ,X+
 CMPA #$FF
 BNE REP5
 CMPX #KEYBUF+8
 BNE REP0
 CLR REPT1
 CLR REPT2
 RTS
*
REP5 LDA REPT1
 CMPA #$80
 BEQ REP1
 INCA
 STA REPT1
 RTS
*
REP1 LDA REPT2
 CMPA REPTIM
 BEQ REP6
 CLR REPT1
 INCA
 STA REPT2
 RTS
*
REP6 LDA REPT3
 INC REPT3
 CMPA REPSPD
 BEQ REP7
 INCA
 STA REPT3
 RTS
*
REP7 CLR REPT3
 LDX #KEYBUF
 LDA #$FF
*
REP8 STA ,X+
 CMPX #KEYBUF+8
 BNE REP8
*
 RTS
*
INKEY PSHS U
 JSR REPEAT
 BSR KEYIN
 TSTA
 BEQ INKEYD
 LDU #$FF00
 PSHS A
 CLRB
 JSR TESTCT
 BEQ INKEY8
 LDA ,S
 ANDA #$5F
 CMPA #$41
 BLO INKEY7
 CMPA #$5A
 BHI INKEY7
 ANDA #$1F
 STA ,S
 BRA INKEY9
*
INKEY7 COMB
 BRA INKEY9
*
INKEY8 JSR TESTAT
 BEQ INKEY9
 CLR REPT1
 CLR REPT2
 LDA ,S
 ANDA #$5F
 ORA #$80
 STA ,S
*
INKEY9 PULS A
INKEYD TSTA
 PULS U,PC
*
KEYIN PSHS U,X,B
*JSR REPEAT
 LDU #$FF00
 LDX #KEYBUF
 CLRA 
 DECA 
 PSHS X,A
 STA $02,U
*
ROTATE ROL $02,U
 BCC RECOVR
 INC ,S
 BSR READ0
 STA $01,S
 EORA ,X
 ANDA ,X
 LDB $01,S
 STB ,X+
 TSTA 
 BEQ ROTATE
 LDB $02,U
 STB $02,S
 LDB #$F8
*
CONV ADDB #$08
 LSRA 
 BCC CONV
 ADDB ,S
 BEQ AT
 CMPB #$1A
 BHI SPECIL
 ORB #$40
 BSR TESTSH
 ORA CASE
 BNE ASCII
 ORB #$20
*
ASCII STB ,S
 LDX DEBNCE
 BSR DELAY
 LDB #$FF
 BSR READ
 INCA 
 BNE RECOVR
*
 LDB $02,S
 BSR READ
 CMPA $01,S
*
RECOVR PULS X,A
 BNE NOKEY
 CMPA #$12
 BNE RETURN
 COM CASE
NOKEY CLRA 
*
RETURN PULS PC,U,X,B
*
TESTSH LDA #$7F
*
TEST STA $02,U
 LDA ,U
 COMA 
 ANDA #$40
 RTS 
*
TESTCT LDA #$EF
 BRA TEST
*
TESTAT LDA #$F7
 BRA TEST
*
READ STB $02,U
*
READ0 LDA ,U
 ORA #$80
 TST $02,U
 BMI REDRET
 ORA #$C0
REDRET RTS 
*
AT LDB #$37
*
SPECIL LDX #TABLE-$36
 CMPB #$21
 BLO SPEC0
 LDX #TABLE-$54
 CMPB #$30
 BHS SPEC0
 BSR TESTSH
 CMPB #$2B
 BLS KSHIFT
 EORA #$40
*
KSHIFT TSTA 
 BNE ASCII
 ADDB #$10
 BRA ASCII
SPEC0 ASLB 
 BSR TESTSH
 BEQ GETASC
 INCB 
GETASC LDB B,X
 BRA ASCII
*
DELAY LEAX -1,X
 BNE DELAY
 RTS



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
