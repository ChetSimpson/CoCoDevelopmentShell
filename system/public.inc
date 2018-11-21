******************************************************************************
*	Copyright (c) 1996, 1997, 2004, 2018, by Chet Simpson
*	
*	This file is distributed under the MIT License. See notice at the end
*	of this file.
*
******************************************************************************
*
*************************************
* Public data and other information *
*************************************

               ifn   vectors
vectors        equ   $dd00
               endif
**********************************************
* Vector entry points
*
system_vectors    equ   vectors+$00
mdos_vectors      equ   vectors+$20    *
screen_vectors    equ   vectors+$40    *
serial_vectors    equ   vectors+$50    *

*
* Entry points for system calls
*
v_initsystem   equ   system_vectors
v_PrintHex8    equ   system_vectors+2
v_inkey		   equ   system_vectors+4
v_sysrsv13     equ   system_vectors+6
v_sysrsv12     equ   system_vectors+8
v_sysrsv11     equ   system_vectors+10
v_sysrsv10     equ   system_vectors+12
v_sysrsv9      equ   system_vectors+14
v_sysrsv8      equ   system_vectors+16
v_sysrsv7      equ   system_vectors+18
v_sysrsv6      equ   system_vectors+20
v_sysrsv5      equ   system_vectors+22
v_sysrsv4      equ   system_vectors+24
v_sysrsv3      equ   system_vectors+26
v_sysputchar	equ   system_vectors+28
v_xprintf		equ   system_vectors+30
*
* Entry vectors for screen routines
*
v_scrsetstat   equ   screen_vectors
v_scrgetstat   equ   screen_vectors+2
v_scrreset     equ   screen_vectors+4
v_scrcls       equ   screen_vectors+6
v_scrout       equ   screen_vectors+8
v_scrrsv3      equ   screen_vectors+10
v_scrrsv2      equ   screen_vectors+12
v_scrrsv1      equ   screen_vectors+14

*
* Entry vectors for mdos routines
*
v_mdossetstat  equ   mdos_vectors
v_mdosgetstat  equ   mdos_vectors+2
v_sectorio     equ   mdos_vectors+4
v_fileopen     equ   mdos_vectors+6
v_fileopenin   equ   mdos_vectors+8
v_fileopenout  equ   mdos_vectors+10
v_fileclose    equ   mdos_vectors+12
v_filecloseall equ   mdos_vectors+14
v_fileread     equ   mdos_vectors+16
v_filewrite    equ   mdos_vectors+18
v_mdosrsv6     equ   mdos_vectors+20
v_mdosrsv5     equ   mdos_vectors+22
v_mdosrsv4     equ   mdos_vectors+24
v_mdosrsv3     equ   mdos_vectors+26
v_mdosrsv2     equ   mdos_vectors+28
v_mdosrsv1     equ   mdos_vectors+30
*
* Serial entry points
*
v_aciasetstat  equ   serial_vectors
v_aciagetstat  equ   serial_vectors+2
v_openport     equ   serial_vectors+4
v_closeport    equ   serial_vectors+6
v_sGetChar     equ   serial_vectors+8
v_sPutChar     equ   serial_vectors+10
v_serialrsv2   equ   serial_vectors+12
v_serialrsv1   equ   serial_vectors+14

*********************************************
* CoCo III FF9x register/bit definitions
* These have been kept the same as those found
* in the unravelled series for consistency.
bit0     equ   $01
bit1     equ   $02
bit2     equ   $04
bit3     equ   $08
bit4     equ   $10
bit5     equ   $20
bit6     equ   $40
bit7     equ   $80

PIA0		equ	$ff00
DAPORT	equ	$ff20
PIA1		equ	$ff20

INIT0    equ   $ff90          * Initialization register 0
INIT1    equ   $ff91          * Initialization register 1
IRQENR   equ   $ff92          * Interrupt request enabler register (IRQ)
FIRQENR  equ   $ff93          * Fast interrupt enable register (FIRQ)
TIMSB    equ   $ff94          * Timer most significant byte
TILSB    equ   $ff95          * Timer least significant byte
CCVMR    equ   $ff98          * CoCo video mode register
CCVRR    equ   $ff99          * Video resolution register
CCBRDR   equ   $ff9a          * Border color register
CCVSR    equ   $ff9c          * Video scroll register
CCVOR0   equ   $ff9d          * Vertical offset register (MSB)
CCVOR1   equ   $ff9e          * Vertical offset register (LSB)
CCHOR    equ   $ff9f          * Horizontal offset register
MMUT0    equ   $ffa0          * MMU Task 0
MMUT1    equ   $ffa8          * MMU Task 1
PALSLOTS equ   $ffb0          * Palette slots


*** Definitions for INIT0 ***
COCO     equ   bit7           * CoCo compatible mode
MMUEN    equ   bit6           * MMU enable
IEN      equ   bit5           * GIME IRQ enable
FEN      equ   bit4           * GIME FIRQ enable
MC3      equ   bit3           * RAM at $FFxx is constant (at $7FFxx)
MC2      equ   bit2           * Standard SCS
MC1      equ   bit1           * ROM Map control
MC0      equ   bit0           * ROM map control

*** Definitions for INIT1 ***
TINS     equ   bit5           * Timer input selection 1=70ns, 0=63.5us
TR       equ   bit0           * MMU Task register

*** Definitions for IRQENR and FIRQENR ***
TMR      equ   bit5           * Timer interrupt enable
HBORD    equ   bit4           * Horizontal interrupt border enable
VBORD    equ   bit3           * Vertical interrupt border enable
EI2      equ   bit2           * Serial interrupt data enable
EI1      equ   bit1           * Keyboard interrupt enable
EI0      equ   bit0           * Cart interrupt enable
*
*
*** Definitions for CCVMR (Video mode reigster )***
BP       equ   bit7           * 0 = Text, 1 = Graphics
BPI      equ   bit5           * Burst phase invert (color select)
MOCH     equ   bit4           * Monochrome select
H50      equ   bit3           * 50/60hz power
LROW1    equ   0              * 1 line per row
LROW2    equ   bit1           * 2 line per row
LROW3    equ   bit2           * 3 line per row
LROW8    equ   bit1+bit2      * 8 line per row
LROW9    equ   bit3           * 9 line per row
LROW10   equ   bit1+bit3      * 10 line per row
LROW12   equ   bit2+bit3      * 12 line per row

*** Definitions for CCVRR (Video resolution register) ***
LPF192   equ   0              * 192 lines
LPF199   equ   bit5           * 199/200 lines
LPF200   equ   bit5           * 199/200 lines
LPF225   equ   bit5+bit6      * 225 lines
GRES160  equ   bit4+bit3+bit2 * 160 bytes per line
GRES128  equ   bit4+bit3      * 128 bytes per line
GRES80   equ   bit4+bit2      * 80 bytes per line
GRES64   equ   bit4           * 64 bytes per line
GRES40   equ   bit3+bit2      * 40 bytes per line
GRES32   equ   bit3           * 32 bytes per line
GRES20   equ   bit2           * 20 bytes per line
GRES16   equ   0              * 16 bytes per line

TRES80_1 equ   bit4+bit3+bit2 * 80 characters/row
TRES64_1 equ   bit4+bit3      * 64 characters/row
TRES80_2 equ   bit4+bit2      * 80 characters/row
TRES64_2 equ   bit4           * 64 characters/row
TRES40_1 equ   bit3+bit2      * 40 characters/row
TRES32_1 equ   bit3           * 32 characters/row
TRES40_2 equ   bit2           * 40 characters/row
TRES32_2 equ   0              * 32 characters/row
COLR16   equ   bit1           * 16 color display
COLR4    equ   bit0           * 4 color display
COLR2    equ   0              * 2 color display

*** Definitions for CCHOR ***
HVEN     equ   bit7           * horizontal virtual enable




*********************************************
* Set stat code for mdos.asm
*
ss_park     equ   $00   * set restore(park) mode 0
ss_seek     equ   $01   * set seek mode   1
ss_readmode equ   $02   * set read mode   2
ss_writmode equ   $03   * set write mode  3
ss_drive    equ   $04   * Set drive
ss_track    equ   $05   * set track
ss_sector   equ   $06   * set sector
ss_buffer   equ   $07   * set buffer address
ss_buffer0  equ   $08   * set buffer address to default buffer 0
ss_buffer1  equ   $09   * set buffer address to default buffer 1
ss_setfn		equ	$0A	* copy filename into filename buffer
ss_motoroff	equ	$0B	* turn drive motor off
ss_seterror	equ	$0C	* Set error handler
ss_setfnum	equ	$0D	* Set file number
ss_setenc	equ	$0E	* Set encryption byte
*********************************************
* get stat code for mdos.asm
*
gs_drivest  	equ   $01   * Get drive status
gs_fileexist	equ	$02	* Check if file exists


* Globals accessible by everyone
VSYNCSAVE	equ	$feee
VSYNCIRQ		equ	$feef




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
