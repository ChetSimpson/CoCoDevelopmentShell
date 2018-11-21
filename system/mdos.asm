******************************************************************************
*	Copyright (c) 1996, 1997, 2004, 2018, by Chet Simpson
*	
*	This file is distributed under the MIT License. See notice at the end
*	of this file.
*
******************************************************************************
*
*
*/HDOS.ASM
*
* Entry vectors for different routines
*
*MODE  equ   0   

   lib   mdos.inc

   setdp $00
	opt	l
mdos_start  equ   *
	org   mdos_vectors
	fdb   SETSTAT  * Set status
	fdb   GETSTAT  * Get status
	fdb   DSKCON   * Disk sector IO
	fdb   OPEN     * Open file for input or output
	fdb   OPENI    * Open file for input
	fdb   OPENO    * Open file for output
	fdb   CLOSE    * Close file
	fdb   CLOSEA   * Close all files
	fdb   ENC_IN   * Read from file
	fdb   ENC_OUT  * Write to file
	fdb   SCANDR	* Scan for filename
	fdb   mdosnull * reserved/unused
	fdb   mdosnull * reserved/unused
	fdb   mdosnull * reserved/unused
	fdb   mdosnull * reserved/unused
	fdb   mdosnull * reserved/unused
	org   mdos_start
   opt	nol
*
* DOS buffer/workspace area
*
* FILE I/O variables
*
DBUF0  RMB SECLEN Disk buffer 0
DBUF1  RMB SECLEN Disk buffer 1 (Used for Verify)
FATBL0 RMB FATLEN FAT Table drive 0
FATBL1 RMB FATLEN FAT Table drive 1
FATBL2 RMB FATLEN FAT Table drive 2
FATBL3 RMB FATLEN FAT Table drive 3
FATBL4 RMB FATLEN FAT Table drive 4
FATBL5 RMB FATLEN FAT Table drive 5
FCBV1  RMB NUMFCB*2 FCB Data buffer pointers
FCBADR RMB 2 Start of file control blocks
DNAMBF RMB 8 Disk filename
DEXTBF RMB 3 Disk extention
DFLTYP RMB 1 Filetype
DASCFL RMB 1 ASCII flag
DEFDRV RMB 1 Default drive
FCBACT RMB 1 Number of FCB's currenly active
*
* EXISTING FILE
*
V973 RMB 1 Sector number
V974 RMB 2 Ram directory image
V976 RMB 1 First granual number
*
* UNUSED FILE
*
V977 RMB 1 Sector number
V978 RMB 2 Ram directory image
*
WFATVL RMB 2 Number of granuals until WRITE FAT is triggered
ATTCTR RMB 1 Number of retries during an error before giving up
DVERFL RMB 1 Verify flag. $00=no verify
*
FCBTMP RMB 2 FCB temporary pointer
DEVNUM RMB 1 Device number
CINBFL RMB 1 Console in buffer flag 00=not empty
*
CURRNT RMB 6 Current track number
NMIFLG RMB 1 NMI flag
NMIVEC RMB 2 NMI vector jump
DRGRAM RMB 1 RAM image of $FF40
DENSIT RMB 1 Density flag $00=single $20=double
GRANMX RMB 1 Maximum granuals
TIMER  RMB 1 Disk turn off motor timer
*
OPCODE RMB 1 BYTE 0 DSKCON operation code
DRIVE  RMB 1 BYTE 1 DSKCON drive
TRACK  RMB 1 BYTE 2 DSKCON track
SECTOR RMB 1 BYTE 3 DSKCON sector
DCBPT  RMB 2 BYTE 4 DSKCON buffer pointer
STATUS RMB 1 BYTE 6 DSKCON status
*
DFLBUF RMB FCBLEN*NUMFCB FCB and data buffers
*
encrypt	fcb	$00
*
* Unused/reserved vector entries
*
mdosnull clra
			rts

DERROR JMP DERROR
*
*
*
* ERROR codes
*
DF LDB #$01 Disk full
 BRA DERROR
WP LDB #$02 Write protect
 BRA DERROR
FS LDB #$03 File structure
 BRA DERROR
VF LDB #$04 Verification error
 BRA DERROR
NE LDB #$05 File not found
 BRA DERROR
FM LDB #$06 File mode (Internal)
 BRA DERROR
IO LDB #$07 Disk I/O error 
 BRA DERROR
AO LDB #$08 File already open (Internal)
 BRA DERROR
*
* Move ACCB bytes from (X) to (U)
*
MOVEBT EQU *
* CLRA
* FCB $1F,%00000110 TFR D,W
* FCB $11,$38,%00100011 TFR X+,U+
* RTS
*
 LDA ,X+ Get byte
 STA ,U+ Store byte
 DECB Are we done yet?
 BNE MOVEBT No, do some more
 RTS Return
*
* Clear ACCB bytes and save X
*
CLRX PSHS X Store X on stack
CLRX0 CLR ,X+ Clear memory
 DECB Are we done yet?
 BNE CLRX0 No, go do some more
 PULS X,PC Return
*
* Clear ACCB bytes
*
CLR CLR ,X+
 DECB
 BNE CLR
 RTS
*
* Open a disk file for input
*
OPENI PSHS B
 STB DEVNUM
 LDA #'I
 BSR OPEN
 PULS B,PC
*
* Open a disk file for output
*
OPENO PSHS B
 STB DEVNUM
 LDA #'O
 BSR OPEN
 PULS B,PC
*
* Open a disk file for read/write
*
OPEN PSHS A Save mode on stack
 LDA DEFDRV
 STA DRIVE
 LDA ,S
 JSR PNTFC0 Point X to FCB for this file
 BNE AO 'File already open' error if file open
 STX FCBTMP Save file buffer pointer
 JSR RAMFAT Make sure file alloc table is valid
 JSR SCANDR Scan dir for 'filename.ext'
 PULS B Get mode
 LDA #INPFIL Get input type file
 PSHS A Save file type on stack
 CMPB #'I Input mode?
 BNE OPEN1 Branch if not
*
* Open a file for input
*
 JSR SCAND8
 JSR CHKFCB
 LDX V974
 LDD DIRTYP,X
 STD DFLTYP
 BSR INTFCB
 JSR REFFCB
OPEN0 JSR PNTFAT
 INC FAT0,X
 LDX FCBTMP
 PULS A
 STA FCBTYP,X
 clra
 RTS
OPEN1 ASL ,S
 CMPB #'O
 LBNE FM
*
* Open a sequential file for output
*
 TST V973
 BEQ OPEN2
 JSR KILL
 LDA V973
 STA V977
 LDX V974
 STX V978
OPEN2 BSR SETDIR
 BSR INTFC0
 BRA OPEN0
*
* Initialize FCB data for input
*
INTFCB BSR INTFC0
 LDU V974
 LDU DIRLST,U
 STU FCBLST,X
 RTS
*
* Initialize file control block
*
INTFC0 LDX FCBTMP
 LDB #FCBCON
 JSR CLRX
 LDA DRIVE
 STA FCBDRV,X
 LDA V976
*
 CMPA GRANMX
 LBHI FS
*
 STA FCBFGR,X
 STA FCBCGR,X
 LDB V973
 SUBB #$03
 ASLB 
 ASLB 
 ASLB 
 PSHS B
 LDD V974
 SUBD #DBUF0
 LDA #$08
 MUL 
 ADDA ,S+
 STA FCBDIR,X
 RTS 
*
* Set up directory and update file allocation table
* entry in first unused sector.
*
SETDIR LDA V977
 LBEQ DF
 STA V973
 STA SECTOR
 LDB #$02
 STB OPCODE
 JSR REDWRT
 LDX V978
 STX V974
 TFR X,U LEAU ,X
 LDB #DIRLEN
 JSR CLR
*
 LDX #DNAMBF
 LDB #$0B
 JSR MOVEBT
 LDD DFLTYP
 STD ,U
 LDB #$21
 JSR FNDGRN
 STA V976
 STA 2,U
 LDB #$03
 STB OPCODE
 JSR REDWRT
SETDI0 PSHS U,X,B,A
 JSR PNTFAT
 INC FAT1,X
 LDA FAT1,X
 CMPA WFATVL
 BCS SETDI1
 JSR KILL1
SETDI1 PULS PC,U,X,B,A

*
* Read a byte and decrypt in
*
DEVIN
ENC_IN	bsr	DEVIN0
			eora	encrypt
			rts
*
* CONSOLE IN
*
DEVIN0 PSHS X,B
 CLR CINBFL
 LDX #FCBV1-2
 LDB DEVNUM
 ASLB
 LDX B,X
 LDB FCBTYP,X
 CMPB #OUTFIL RANFIL
 LBEQ FM
*
* get a byte from a sequential file
*
 LDB FCBDFL,X
 BEQ GETSE0
 COM CINBFL
 PULS PC,X,B
*
GETSE0 LDB FCBCPT,X
 INC FCBCPT,X
 DEC FCBLFT,X
 BEQ GETFCB
 ABX 
 LDA FCBCON,X
 PULS PC,X,B
*
* Get a character from FCB data buffer > to ACCA
*
GETFCB PSHS U,Y
 CLRA 
 LEAU D,X
 LDA FCBCON,U
 PSHS A
 CLR FCBCPT,X
 LDA FCBDRV,X
 STA DRIVE
 BSR REFFCB
 PULS U,Y,A
 PULS PC,X,B
*
* Refill the FCB input data buffer for sequential file
*
REFFCB LDA FCBSEC,X
REFFC0 INCA 
 PSHS A
 CMPA #$09
 BLS REFFC1
 CLRA
REFFC1 STA FCBSEC,X
 LDB FCBCGR,X
 TFR X,U LEAU ,X
 JSR PNTFAT
 ABX
 LDB FATCON,X
 TFR U,X LEAX ,U
 CMPB #$C0
 BCC REFFC2
 PULS A
 SUBA #$0A
 BNE REFFC4
*
 CMPB GRANMX
 LBHI FS
*
 STB FCBCGR,X
 BRA REFFC0
REFFC2 ANDB #$3F
 CMPB #$09
 BLS REFFC3
 JMP FS
*
REFFC3 SUBB ,S+
 BCS REFFC5
 TFR B,A
REFFC4 PSHS A
 LDA #$02
 STA OPCODE
 JSR CONVRT
 LEAU FCBCON,X
 STU DCBPT
 JSR REDWRT
 CLR FCBLFT,X
 LDB ,S+
 BNE REFFC7
 LDD FCBLST,X
 BNE REFFC6
REFFC5 CLRB 
 COM FCBDFL,X
REFFC6 STB FCBLFT,X
REFFC7 RTS
*
* Scan directory for filename in DNAMBF
*
SCANDR CLR V973
 CLR V977
 LDD #$1102
 STA TRACK
 STB OPCODE
 LDB #$03
SCAND0 STB SECTOR
 LDU #DBUF0
 STU DCBPT
 JSR REDWRT
SCAND1 STU V974
 TFR U,Y
 LDA ,U
 BNE SCAND5
 BSR SCAND6
SCAND2 LDX #DNAMBF
SCAND3 LDA ,X+
 CMPA ,U+
 BNE SCAND4
 CMPX #DFLTYP
 BNE SCAND3
 STB V973
 LDA FCBFGR,U
 STA V976
 RTS
*
SCAND4 LEAU DIRLEN,Y
 CMPU #DBUF1
 BNE SCAND1
 INCB
 CMPB #$0B
 BLS SCAND0
 RTS
SCAND5 COMA
 BNE SCAND2
*
* Set pointers for first unused dir entry
*
SCAND6 LDA V977
 BNE SCAND7
 STB V977
 STU V978
SCAND7 RTS
*
SCAND8 TST V973
 BNE SCAND7
 JMP NE
*
* Kill an existing disk file for output
*
KILL LDA #$FF
 JSR CHKFCB
 LDX V974
 CLR DIRNAM,X
 LDB #$03
 STB OPCODE
 JSR REDWRT
 LDB DIRGRN,X
KILL0 BSR PNTFAT
 LEAX FATCON,X
 ABX
 LDB ,X
 LDA #$FF
 STA ,X
 CMPB #$C0
 BCS KILL0
KILL1 LDU #DBUF0
 STU DCBPT
 LDD #$1103
 STA TRACK
 STB OPCODE
 LDB #$02
 STB SECTOR
 BSR PNTFAT
 CLR FAT1,X
 LEAX FATCON,X
 LDB GRANMX
 JSR MOVEBT
*
* Clear out all bytes in fat that don't contain granual data
*
KILL2 CLR ,U+
 CMPU #DBUF1
 BNE KILL2
 JMP REDWRT
*
* Point to correct FCB area
*
PNTFCB PSHS B
 LDB DEVNUM
 FCB SKP2
PNTFC0 PSHS B
 ASLB
 LDX #FCBV1-2
 LDX B,X
 LDB FCBTYP,X
 PULS PC,B
*
* Point X to drive FAT
*
PNTFAT PSHS B,A
 LDA DRIVE
 LDX #DRVGRN
 LDA A,X
 STA GRANMX
 LDA DRIVE
*
 LDB #FATLEN
 MUL 
 LDX #FATBL0
 LEAX D,X
 PULS PC,B,A
*
* Convert granual number to track and sector number
*
CONVRT LDB FCBCGR,X
 LSRB 
 STB TRACK
 CMPB #$11
 BCS CONVR0
 INC TRACK
CONVR0 ASLB 
 NEGB 
 ADDB FCBCGR,X
 BSR MULBY9
 ADDB FCBSEC,X
 STB SECTOR
 RTS 
*
* Multiply by 9
*
MULBY9 PSHS B,A
 ASLB 
 ROLA 
 ASLB 
 ROLA 
 ASLB 
 ROLA 
 ADDD ,S++
RTS0 RTS 
*
* Make sure ram file alloc table data is valid
*
RAMFAT BSR PNTFAT
 TST FAT0,X
 BNE RTS0
 CLR FAT1,X
 LEAU FATCON,X
 LDX #DBUF0
 STX DCBPT
 LDD #$1102
 STA TRACK
 STB OPCODE
 LDB #$02
 STB SECTOR
 JSR REDWRT
 LDB GRANMX
 JMP MOVEBT
*
* Find first free granual
*
FNDGRN BSR PNTFAT
 LEAX FATCON,X
 CLRA 
 ANDB #$FE
 CLR ,-S
FNDGR0 COM B,X
 BEQ PNTFRE
 COM B,X
 INCA 
 CMPA GRANMX
 BCC FNDGR4
 INCB 
 BITB #$01
 BNE FNDGR0
 PSHS B,A
 SUBB #$02
 COM 2,S
 BNE FNDGR3
 SUBB ,S+
 BPL FNDGR2
 LDB ,S
FNDGR1 COM 1,S
FNDGR2 LEAS 1,S
 BRA FNDGR0
FNDGR3 ADDB ,S+
 CMPB GRANMX
 BCS FNDGR2
 LDB ,S
 SUBB #$04
 BRA FNDGR1
FNDGR4 JMP DF
*
* Point X to first free granual position in the FAT
*
PNTFRE LEAS 1,S
 TFR B,A
 ABX 
 LDB #$C0
 STB ,X
 RTS 
*
* Check all active files to make sure a file is not already open
*
CHKFCB PSHS A
 LDB FCBACT
 INCB 
CHKFC0 JSR PNTFC0
 BEQ CHKFC1
 LDA DRIVE
 CMPA FCBDRV,X
 BNE CHKFC1
 LDU V974
 LDA DIRGRN,U
 CMPA FCBFGR,X
 BNE CHKFC1
 LDA FCBTYP,X
 CMPA ,S
 LBNE AO
CHKFC1 DECB 
 BNE CHKFC0
 PULS PC,A
*
* CLOSE ALL FILES
*
CLOSEA LDB FCBACT
 INCB 
CLOSA0 PSHS B
 STB DEVNUM
 BSR CLOSE
 PULS B
 DECB 
 BNE CLOSA0
CLOSDN RTS 
*
* Close a file
*
CLOSE JSR PNTFCB
 CLR DEVNUM
 STX FCBTMP
 LDA FCBTYP,X
 BEQ CLOSDN
 PSHS A
 CLR FCBTYP,X
 LDB FCBDRV,X
 STB DRIVE
 CMPA #OUTFIL
 BNE CLOS1
 LDB FCBLFT,X
 LDA #$80
 ORA FCBCPT,X
 STD FCBLST,X
 INC FCBSEC,X
 LDB FCBCGR,X
 JSR PNTFAT
 STA FAT1,X
 ABX 
 INC FATCON,X
CLOS0 BRA CLOS2
*
CLOS1 CMPA #RANFIL
 BNE CLOS0
 RTS
*
RTS1 RTS 
*
* Check to see if contents of buffer
*  need to be saved to disk.
*
CLOS2 JSR PNTFAT
 DEC FAT0,X
 TST FAT1,X
 BEQ CLOS3
 JSR KILL1
CLOS3 LDX FCBTMP
 PULS A
 CMPA #OUTFIL
 BEQ CLOS4
 CMPA #RANFIL
 BNE RTS1
 LDA $0F,X
 BEQ CLOS5
*
* Write contents of file buffer to disk
*
CLOS4 JSR CONVRT
 LEAU FCBCON,X
 STU DCBPT
 BSR CLOS6
CLOS5 LDA FCBLST,X
 BPL RTS1
 LDB FCBDIR,X
 ANDB #$07
 LDA #$20
 MUL 
 LDU #DBUF0
 STU DCBPT
 LEAY D,U
 LDB FCBDIR,X
 LSRB 
 LSRB 
 LSRB 
 ADDB #$03
 STB SECTOR
 LDD #$1102
 STA TRACK
 BSR CLOS7
 LDD FCBLST,X
 ANDA #$7F
 STD DIRLST,Y
CLOS6 LDB #$03
CLOS7 STB OPCODE
 BRA REDWRT
*
* Encrypt a byte and write it a file
*
DEVOUT
ENC_OUT	eora	encrypt
*
* CONSOLE OUT
*
 PSHS X,B,A
 LDX #FCBV1-2
 LDB DEVNUM
 ASLB
 LDX B,X
 LDB FCBTYP,X
 CMPB #INPFIL
 BEQ DEVERR
*
 CMPB #RANFIL
 BNE WRTBYT
 PULS PC,X,B,A
*
DEVERR LEAS 6,S
 JMP FM
*
*
* WRITE A BYTE INTO A SEQUENTIAL FILE
*
WRTBYT INC FCBLFT,X
 LDB FCBLFT,X
 BEQ WRTBUF
 ABX 
 STA FCBCON-1,X
 PULS PC,X,B,A
*
* WRITE OUT A FULL BUFFER AND RESET BUFFER
*
WRTBUF PSHS U,Y
 STA SECLEN+FCBCON-1,X
 LDB FCBDRV,X
 STB DRIVE
 INC FCBSEC,X
 JSR CLOS4
 TFR X,Y LEAY ,X
 LDB FCBCGR,X
 JSR PNTFAT
 ABX 
 LEAU FATCON,X
 LDA FCBSEC,Y
 CMPA #$09
 BCS WRTBU0
 DEC FCBSEC,Y
 INC FCBCPT,Y
 JSR FNDGRN
 CLR FCBSEC,Y
 CLR FCBCPT,Y
 STA FCBCGR,Y
 FCB SKP2
WRTBU0 ORA #$C0
 STA ,U
 TFR Y,X
* JSR SETDI0
 PULS U,Y
 PULS PC,X,B,A
*
* READ/WRITE DBUF0 TO DISK
*
REDWRT PSHS B
 LDB #$05
 STB ATTCTR
 PULS B
REDWR0 JSR DSKCON
 TST STATUS
 BEQ REDWR1
 LDA STATUS
 BITA #$40
 LBNE WP
 JMP IO
REDWR1 PSHS A
 LDA OPCODE
 CMPA #$03
 PULS A
 BNE REDWR3
 TST DVERFL
 BEQ REDWR3
*
 PSHS U,X,B,A
 LDA #$02
 STA OPCODE
 LDU DCBPT
 LDX #DBUF1
 STX DCBPT
 JSR DSKCON
 STU DCBPT
 LDA #$03
 STA OPCODE
 LDA STATUS
 BNE REDWR4
 CLRB 
REDWR2 LDA ,X+
 CMPA ,U+
 BNE REDWR4
 DECB 
 BNE REDWR2
 PULS U,X,B,A
REDWR3 RTS 
REDWR4 PULS U,X,B,A
 DEC ATTCTR
 BNE REDWR0
 JMP VF
*
* Initialize disk buffer area
*
InitMDOS   pshs  u,x,y,b,a
 LDX #DBUF0
 LDA $EB
 PSHS A
DOD0 CLR ,X+
 CMPX #DFLBUF
 BLO DOD0
 LDA #19
 STA WFATVL
 LDX #DFLBUF
 STX FCBADR
*
 LEAX 1,X
 LDB #NUMFCB
 STB FCBACT
 LDU #FCBV1
*
DODX STX ,U++
 CLR FCBTYP,X
 DECB
 BNE DODX
*
* STX FCBV1
* CLR FCBTYP,X
*
* LEAX FCBLEN+SECLEN,X
* STX FCBV1+2
* CLR FCBTYP,X
*
* LEAX FCBLEN+SECLEN,X
* STX FCBV1+4
* CLR FCBTYP,X
*
* LDA #2
* STA FCBACT
*
*
* Set NMI vectors
*
 LDA #$7E
 STA $FEFD
 LDX #NMISRV
 STX $FEFE
*
* Set number of granuals of the disk
*
 LDA #158 Get maximum number of granuals allowed
 STA GRANMX
*
 PULS A
 STA DEFDRV
 STA DRIVE
*
* Set to double density
*
 LDA #$20
 STA DENSIT
*
* Set current tracks to 255
*
 LDX #CURRNT
 LDB #$06
DOD1 COM ,X+
 DECB
 BNE DOD1
*
 CLR $FF40
 LDA #$D0
 STA $FF48
 EXG A,A
 EXG A,A
 LDA $FF48
 puls a,b,x,y,u,pc

MOTOFF   pshs  a
         LDA DRGRAM
         ANDA #$B0
         STA DRGRAM
			STA $FF40
         puls  a,pc


*
* GDSKCON routine
*
CHECK LDB ,X
 PSHS X
 BPL CHECK0
 JSR RESTOR
 CLRB
CHECK0 STB $FF49
 PULS PC,X
*
RATE LDA #$03
RATE0 LDB 1,Y
 LDX #SKIP
 SUBA B,X
 STA $FF48
RATE1 LDA $FF48
RATE2 PSHS U,Y,X,DP,B,A,CC
	nop
	nop
	nop
	nop
 PULS PC,U,Y,X,DP,B,A,CC
*
DDELAY LDX #$00
DELAY0 LEAX -1,X
	nop
	BNE DELAY0
 RTS
*
DNRERR LDA #$80
 STA STATUS
 PULS U,Y,X,B,A,PC
*
DSKCON PSHS U,Y,X,B,A
 LDX #DRVSEL
 LDA DRIVE
 TST A,X
 BEQ DNRERR
 LDY #OPCODE
 LDA #$02
 PSHS A
*
DSK10 CLR TIMER
 LDB 1,Y
 LDX #DRVSEL
 LDA DRGRAM
 ANDA #$A8
 ORA B,X
*
 PSHS A
 LDA DENSIT
 ANDA #$20
 ORA ,S+
*
 LDB 2,Y
 CMPB #$16
 BCS DSK20
 ORA #$10
DSK20 TFR A,B
 ORA #$08
 STA DRGRAM
 STA $FF40
 BITB #$08
 BNE DSK30
 JSR DDELAY
 JSR DDELAY
* CMPX #DDELAY
DSK30 BSR WAIT
 BNE DSK40
 CLR STATUS
 LDX #VECTOR
 LDB ,Y
 ASLB 
 JSR [B,X]
DSK40 PULS A
 LDY #OPCODE
 LDB STATUS
 BEQ DSK50
 DECA 
 BEQ DSK50
 PSHS A
 BSR RESTOR
 BNE DSK40
 BRA DSK10
DSK50 LDA #$20 Get timer for drive shut off
 STA TIMER Store it to data variable
*
* This routine checks for matching physical drives
* for current tracks numbers.
*
 LDX #DRVSEL Point X to drive selection data 
 LDY #CURRNT Point Y to current track data
 LDA DRIVE Get current drive
 LDB A,Y Get current track of drive just accessed
 PSHS B Store onto stack
 LDA A,X Get physical drive pointer
 ANDA #$03 And set to 3 physical drives
 PSHS A And store onto stack
*
 LDB #$06 Set to 6 possible drives
DSK100 LDA ,X+ Get drive selection byte
 ANDA #$03 Set to 3 physical drives
 CMPA ,S Is it the same as the drive just accessed?
 BEQ DSK110 Yes - Go get data
 LDA ,Y NO - get current track of that drive
 BRA DSK120 Go store it
DSK110 LDA 1,S Get current track of drive just accessed
DSK120 STA ,Y+ Store current track
 DECB Are we done yet?
 BNE DSK100 No, go do some more
 LEAS 2,S Adjust stack
*
 PULS PC,U,Y,X,B,A
*
* Restore head to track 0
*
RESTOR LDX #CURRNT
 LDB 1,Y
 CLR B,X
 JSR RATE
 JSR RATE2
 BSR WAIT
 BSR MDELAY
 ANDA #$10
 STA STATUS
NOOPER RTS 
*
* Wait for 1793 to become unbusy. Force NMI irq it timed out
*
WAIT LDX #$00
WAIT0 LEAX -$01,X
 BEQ WAIT1
 JSR RATE1
 BITA #$01
 BNE WAIT0
 RTS 
WAIT1 LDA #$D0
 STA $FF48
 JSR RATE2
 LDA $FF48
 LDA #$80
 STA STATUS
 RTS 
*
MDELAY LDX #$222E
MDELY0 LEAX -$01,X
 BNE MDELY0
 RTS 
*
* Read one sector
*
DREAD LDA #$80
 BRA DODISK
*
DWRITE LDA #$A0
*
DODISK PSHS A
 LDX #CURRNT
 LDB 1,Y
 ABX 
 JSR CHECK
 CMPB 2,Y
 BEQ DSK70
 LDA 2,Y
 STA $FF4B
 STA ,X
 LDA #$17
 JSR RATE0
 JSR RATE2
 NOP 
 BSR WAIT
 BNE DSK60
 BSR MDELAY
 ANDA #$18
 BEQ DSK70
 STA STATUS
DSK60 PULS PC,A
DSK70 LDA 3,Y
 STA $FF4A
 LDX #DSKDON
 STX NMIVEC
 LDX 4,Y
 LDA $FF48
 LDA DRGRAM
 ORA #$80
 PULS B
 LDY #$00
 LDU #$FF48
 COM NMIFLG
 pshs cc
 orcc #$50
 STB $FF48
 JSR RATE2
 CMPB #$80
 BEQ ACK
 LDB #$02
DSK80 BITB ,U
 BNE WRTSEC
 LEAY -$01,Y
 BNE DSK80
DSK90 CLR NMIFLG
 puls cc
 JMP WAIT1
*
* Write one sector
*
WRTSEC LDB ,X+
 STB $FF4B
 STA $FF40
 BRA WRTSEC
*
* Wait for 1793 to acknolwdge ready to read data
*
ACK LDB #$02
ACK0 BITB ,U
 BNE REDSEC
 LEAY -$01,Y
 BNE ACK0
 BRA DSK90
*
* Read sector
*
REDSEC LDB $FF4B
 STB ,X+
 STA $FF40
 BRA REDSEC
*
* Go here when read/write is done
*
DSKDON LDA $FF48
 ANDA #$7C
 STA STATUS
 puls cc
 RTS 
*
* NMI service routine
*
NMISRV LDA NMIFLG
 BEQ NMIDON
 LDX NMIVEC
 STX 10,S
 CLR NMIFLG
NMIDON RTI 
*
*
* Operation jump vectors
*
VECTOR EQU *
 FDB RESTOR
 FDB NOOPER
 FDB DREAD
 FDB DWRITE
*
* Drive select values
*
DRVSEL EQU *
 FCB $01
 FCB $02
 FCB $00
 FCB $00
 FCB $00
 FCB $00
*
* Skip rate for drives
*
SKIP EQU *
 FCB $03
 FCB $03
 FCB $03
 FCB $03
 FCB $03
 FCB $03
*
DRVGRN EQU *
 FCB $4E
 FCB $4E
 FCB $00
 FCB $00
 FCB $00
 FCB $00
*

*
* Get status
*
GETSTAT
; scan to see if file exists
				cmpa	#gs_fileexist
				bne	getstat10
				jsr	SCANDR
				tst	V973
				rts
; get dskcon status
getstat10
			   cmpa  #gs_drivest
				bne   getstatn
				ldb   #STATUS
				bra   getstatr


getstatn    lda   #$ff           * set unknown status code
				bra   getstatr       * go return

getstatr    clra                 * set no error
getstate    puls  b,x,y,pc       * return



setstatmsg  fcc   "MDOS setstat"
				fcb   $0d,00

******************************************************************
* Set status
*  enter:
*     acca  - Status code
*        x  - Parameter 1
*        y  - Parameter 2
*     accb  - Parameter 3
*  return:
*     acca  - 0-pass, other=error code
*
SETSTAT     pshs  y,x,b
				cmpa  #ss_writmode   * Write mode or below?
				bhi   setstat5       * go next
				sta   OPCODE         * Yes set opcode
				bra   setstatr       * return

setstat5    cmpa  #ss_drive      * drive code
            bne   setstat10      * no, go next
				stb   DRIVE          * yup, set the drive
            bra   setstatr       * return

setstat10   cmpa  #ss_track      * set track?
            bne   setstat15      * no, go next
            stb   TRACK          * yup, set track
            bra   setstatr       * return

setstat15   cmpa  #ss_sector     * set sector?
            bne   setstat20      * no, go next
            stb   SECTOR         * yup, set sector
            bra   setstatr       * return

setstat20   cmpa  #ss_buffer     * set buffer area?
            bne   setstat25      * no, next
            stx   DCBPT          * set buffer
				bra   setstatr       * return

setstat25   cmpa  #ss_buffer0    * set default buffer?
            bne   setstat30      *no, next
            ldx   #DBUF0         * get buffer
            stx   DCBPT          * et it
            bra   setstatr       * go return

setstat30   cmpa  #ss_buffer1    * set default buffer?
            bne   setstat40      *no, next
            ldx   #DBUF1         * get buffer
				stx   DCBPT          * et it
				bra   setstatr       * go return
* copy filename pointed to by X into filename buffer
setstat40	cmpa	#ss_setfn		* set filename code?
				bne	setstat50		* nope, keep goiing
				ldy	#DNAMBF			* point to buffer
				ldb	#11
setstat42	lda	,x+
				sta	,y+				* clear the buffer out to spaces
				decb
				bne	setstat42
				bra	setstatr			* return
* set file io handle number
setstat50	cmpa	#ss_setfnum
				bne	setstat60
				cmpb	#$0f
				bhi	setstatn
				stb	DEVNUM
				bra	setstatr
* turn the drive motor off
setstat60	cmpa	#ss_motoroff
				bne	setstat70
				clr	$ff40
				jsr	MOTOFF
				bra	setstatr
; set error handler
setstat70	cmpa	#ss_seterror
				bne	setstat80
				stx	DERROR+1
				bra	setstatr
; set encryption
setstat80
				cmpa	#ss_setenc
				bne	setstat90
				stb	encrypt
				bra	setstatr
;
setstat90
;
* return error
setstatn    lda   #$ff           * set unknown status code
				bra   setstate       * go return


setstatr    clra                 * set no error
setstate    puls  b,x,y,pc       * return




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
