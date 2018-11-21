******************************************************************************
*	Copyright (c) 1996, 1997, 2004, 2018, by Chet Simpson
*	
*	This file is distributed under the MIT License. See notice at the end
*	of this file.
*
******************************************************************************
*
* download protocol
*
pack_type      fcb   $00         * type of packet
pack_size      fdb   $0000       * packet size
pack_bufptr    fdb   $0000       * packet buffer pointer
pack_check     fdb   $0000       * packet checksum
*
dfilename      zmb   8           * filename
dext           zmb   3           * extension
dtype          zmb   1           * filetype
dyear          zmb   1           * year
dmonth         zmb   1
dday           zmb   1
dhour          zmb   1
dminute        zmb   1
dsecond        zmb   1
*
TIMEOUT_ERROR  equ   $01
INVALID_PACK   equ   $02         * invalid packet
INVALID_CHECK  equ   $03         * checksum error
INVALID_EOPM   equ   $04         * invalid end of packet marker
INVALID_SIZE   equ   $05         * invalid packet size ( > 4096)
*
HEADERSIG      equ   $af54       * header signature
ENDMARKER      equ   $54af       * end of packet marker
XACK           equ   $05         * packet ok ack
NACK           equ   $25         * packet not ok ack
FILE_SAVING    equ   $af         * saving recieved file
FILE_SAVED     equ   $ae         * file saved
NEEDS_UPDATING equ   $ed         * yes, file needs updating
*
packet_NAME    equ   $30         * filename info packet type
packet_DATA    equ   $31         * data packet type
packet_EOT     equ   $94         * end of transmission packet
*
mmu_block      fcb   $00         * current mmu block we are in
*
timeflag       fcb   $00         * timeout flag
pack_errflg    fcb   $00         * packet error type

packet_retry   fcb   $00         * retry count for packet

type_table     fdb   $0000       * BASIC file
               fdb   $0200       * binary executable
               fdb   $01FF       * ASCII file

*****************************************************
* Scan directory for filename
*
scandir        pshs  b,y
               ldd   #$1103      * point to directory
               std   TRACK       * set the track
               lda   #$02        * get operation
               sta   OPCODE      * set it
scandir0       ldx   #DBUF0      * point to buffer 0
               stx   DCBPT       * set for dskcon
               jsr   DSKCON      * load dir
               ldy   #dfilename  * point to filename
scandir5       lda   ,x          * get first char
               tsta              * deleted char?
               beq   scandir20   * yes, skip it
               cmpa  #$ff        * end of directory?
               beq   scandirnot  * yup
               ldb   #10         * check 11 characters
scandir10      lda   b,x         * get char from buffer
               cmpa  b,y         * same as filename?
               bne   scandir20   * nope, go to next one
               tstb              * done yet?
               beq   scandirfnd  * we found it!
               decb
               bra   scandir10   * 
scandir20      leax  $20,x       * point to next line
               cmpx  #DBUF0+256  * end of this buffer?
					blo   scandir5    * nope, keep checking
               inc   SECTOR      * go to next sector
               lda   SECTOR      * get sector
               cmpa  #18         * end of dir?
               blo   scandir0    * nope, keep going


scandirnot     lda   #$ff        * didn't find one
               bra   scandirdon  * finish up
scandirfnd     clra
scandirdon     jsr   MOTOFF      * turn motor off
               puls  b,y,pc  * return

*****************************************************
* Get character while waiting
*
dgetchar       pshs  b,x
               clr   timeflag    * reset timeout flag
               ldb   sys_comport * get com port
               ldx   #$8000      * timeout counter
dgetchar0      jsr   sGetChar    * go get key
               bcs   dgotkey     * got a key
               leax  -1,x
               bne   dgetchar0   * keep going
               com   timeflag    * timed out, set flag
               clra
dgotkey        puls  b,x,pc      * return



*****************************************************
* get word
*
getword        jsr   dgetchar    * get a character
               tst   timeflag    * timeout?
               bne   getword0    * yes
               tfr   a,b         * move acca into accb for later use
               jsr   dgetchar    * get a character
               tst   timeflag    * timeout?
               bne   getword0    * yes
               exg   a,b         * switch them
               rts
getword0       com   timeflag
               rts



*****************************************************
* Get packet
*
get_packet     pshs  a,b,x,y
               clr   pack_errflg * reset packet error flag
               ldb   sys_comport * get the com port to talk to
               lda   #$de        * tell the pc we are ready
               jsr   sPutChar
* Get packet signature
               jsr   getword     * get a character
               tst   timeflag    * timeout?
               bne   pack_error  * yes
               cmpd  #HEADERSIG  * valid header signature?
               beq   get_packet0 * yes
               lda   #INVALID_PACK * invalid packet code
               bra   pack_error0 * go do error
* get packet type
get_packet0    jsr   dgetchar    * get a character
               tst   timeflag    * timeout?
               bne   pack_error  * yes
               sta   pack_type   * save it
* Get packet size
               jsr   getword     * get a character
               tst   timeflag    * timeout?
               bne   pack_error  * yes
               cmpd  #4096       * invalid size?
               bls   get_packet5 * no
               lda   #INVALID_SIZE * get invalid size code
               bra   pack_error0 * go do error
get_packet5    std   pack_size   * save it
* get packet data
               pshs  x,y         * save registers
               ldy   pack_size   * get size of packet data
               cmpy  #$0         * is there data to get?
               beq   get_packet11 * nope.
get_packet10   jsr   dgetchar    * get a character
               tst   timeflag    * timeout?
               bne   get_packet11 * yes
               sta   ,x+         * save in start of packet info
               leay  -1,y        * done getting all of packet data
               bne   get_packet10 * no, keep going
get_packet11   puls  x,y         * restore registers
               tst   timeflag    * did we time out getting the packet
               bne   pack_error  * yes, error on this packet
* get packet checksum information
               jsr   getword     * get word
               tst   timeflag    * timeout?
               bne   pack_error  * yes
               std   pack_check  * save in start of packet info
* get end of packet marker
               jsr   getword     * get word
               tst   timeflag    * timeout?
               bne   pack_error  * yes
               cmpd  #ENDMARKER  * valid end of packet?
               beq   get_packet99   * yes, finish
               lda   #INVALID_EOPM  * end of packet marker
               bra   pack_error0
get_packet99   clra
*
pack_error     tst   timeflag
               beq   pack_error0
               lda   #TIMEOUT_ERROR
pack_error0    sta   pack_errflg * set packet error flag
               puls  a,b,x,y,pc  * restore used registers and return


download_msg	fcz	"Receiving file "
download_msg2	fcc	"Saving..."
					fcb	$00
*****************************************************
* Download service routine
*
srv_download   jsr   dgetchar
					cmpa  #$90
					beq   srv_down0
					rts
srv_down0		ldx	#download_msg
					jsr	xprintf
					lda   #$a0        * ack the request
               jsr   sPutChar
               jsr   sPutChar
*  save MMU status
               lda   $ffa0       * get current mmu block
               pshs  a           * save it on the stack
               clr   $ffa0       * set to first mmu block in machine
               clr   mmu_block   * set mmu_image container
               ldx   #$0         * point to start of mmu block
srv_down10     clr   packet_retry   * clear retry count for this packet
srv_down15     jsr   get_packet  * get packet

* check for packet types
               lda   pack_type      * get type sent
               cmpa  #packet_EOT    * end of transmission?
               beq   srv_downeot    * yes, we are done
               cmpa  #packet_NAME   * filename?
               beq   srv_downname   * set filename info
               cmpa  #packet_DATA   * data packet?
               beq   srv_downdata   * process data
               inc   packet_retry   * increment retries
               lda   #NACK          * invalid packet type, request retry
               jsr   sPutChar      * sent NACK
               lda   packet_retry   * get the count
               cmpa  #10            * done yet?
               lbeq   srv_downdone  * yup, too many retries
               bra   srv_down15
*
* Process filename
*
srv_downname   pshs  x,y,d          * save registers
               ldy   #dfilename     * point to filename buffer
               ldb   #18            * 18 bytes
srv_downnam0   lda   ,x+            * get char
               sta   ,y+            * put it into data
               decb                 * done yet?
               bne   srv_downnam0   * nope

					lda	#'[
					jsr	PutChar
					ldb	#$08
					ldx	#dfilename
@a					lda	,x+
					jsr	PutChar
					decb
					bne	@a
					lda	#'.
					jsr	PutChar
					ldb	#$03
@b					lda	,x+
					jsr	PutChar
					decb
					bne	@b
					lda	#']
					jsr	PutChar
					lda	#$20
					jsr	PutChar


					puls  x,y,d          * restore registers
					bra   srv_downdat0   * yup keep going

*
* Process incoming data and adjust pointers
*
srv_downdata   pshs  b
               ldd   pack_size   * get packet size
               leax  d,x         * adjust pointer
               puls  b
               cmpx  #$2000      * end of mmu block
               blo   srv_downdat0 * nope
               ldx   #$00        * reset X pointer to 0
               inc   mmu_block   * go to next mmu
               lda   mmu_block   * get mmu block
               sta   $ffa0       * set mmu
srv_downdat0   stx   pack_bufptr * save current buffer pointer
               lda   #XACK       * acknowledge
               jsr   sPutChar    * send ack
               jmp   srv_down10  * keep downloading

* end of transmission
srv_downeot    pshs  d,x,y
					lda   #XACK
					ldb   sys_comport * get com port
					jsr   sPutChar    * send to server
					ldx   #$10

srv_dwnsavw0   lda   #FILE_SAVING *
*               ldb   sys_comport * get com port
					jsr   sPutChar    * send to server
					jsr   dgetchar    * get character while waiting
					cmpa  #XACK       * did it get there?
					beq   srv_dwnsavw5
					leax  -1,x
					bne   srv_dwnsavw0   * keep checking

srv_dwnsavw5   ldx   #dfilename  * point to filename
					ldy   #DNAMBF     * point to mdos filename buffer
					ldb   #11         * 11 characters in full filename
srv_downeot0   lda   ,x+         * copy filename over
					sta   ,y+
					decb
					bne   srv_downeot0
* change to table
					ldb   dtype       * get type of file
					cmpb  #$08        * out of range of possible
					lbhs  srv_dontsave   * yes
					ldx   #type_table * no, point to table
					aslb              * adust for word
					abx               * adjust table offset
					ldd   ,x          * get RS-DOS file type
					std   DFLTYP      * set file type
					ldx	#download_msg2
					jsr	xprintf
					ldb   #$01        * get file handle
					jsr   OPENO       * open for output

* save the file out
					ldb   #$01        * get file handle
					lda   mmu_block   * get mmu blocks used
					pshs  a           * save on stack
					clr   $ffa0       * set to first mmu block
					clr   mmu_block   * set mirror image
               tst   ,s          * are we on the last mmu block used
               beq   srv_donesav5   * yes, save it out

srv_donesav0   ldx   #$0         * nope, point to start of mmu block
               ldy   #$2000      * get number of bytes to save
srv_donesav1   lda   ,x+         * get byte
               jsr   DEVOUT      * save byte
               leay  -1,y        * done yet?
               bne   srv_donesav1   * no, keep going
               inc   mmu_block   * go to next mmu block
               lda   mmu_block   * get it
               sta   $ffa0       * set mmu block
               dec   ,s          * decrement the number of blocks left
               bne   srv_donesav0   * keep saving mmu blocks
srv_donesav5   ldx   #$0         * point to start of buffer
               ldy   pack_bufptr * get number of bytes to save
               cmpy  #$0
               beq   srv_donesavx   * if its empty, close it
srv_donesav6   lda   ,x+         * get byte
               jsr   DEVOUT      * save byte
               leay  -1,y        * done yet?
               bne   srv_donesav6   * no, keep going

srv_donesavx   puls  a
               ldb   #$01        * get file handle
               jsr   CLOSE       * close file
               jsr   scandir     * go file the file entry in the directory
               leax  16,x        * adjust to empty portion of entry
               ldd   dyear
               std   ,x++
               ldd   dday
               std   ,x++
               ldd   dminute
               std   ,x++
               lda   #$03
               sta   OPCODE
               jsr   DSKCON
					jsr   MOTOFF      * turn motor off
					lda	#$0d
               jsr	PutChar

               lda   #FILE_SAVED * tell server file was saved
               ldb   sys_comport * get com port
               jsr   sPutChar    * send to server

srv_dontsave   puls  d,x,y
               lda   #XACK       * acknowledge
               jsr   sPutChar    * send ack

*  restore MMU and return
srv_downdone   puls  a
               sta   $ffa0
               rts

*****************************************************88
* Get file status
*
srv_status     pshs  d,x,y,u        * save registers
               ldb   sys_comport    * get used com port
               jsr   dgetchar       * get timed characer
               cmpa  #$91           * really a status request?
               bne   srv_statdone   * nope, return
* acknowledge status request
               lda   #$a1           * ack the request
               ldb   sys_comport    * get com port used
               jsr   sPutChar
               jsr   sPutChar
* set up MMU blocks for packet buffer
               lda   $ffa0          * get current mmu block
               pshs  a              * save it on the stack
               clr   $ffa0          * set to first mmu block in machine
               clr   mmu_block      * set mmu_image container
* Get filename packet
               ldx   #$0            * point to start of mmu block
               jsr   get_packet     * get packet
               lda   #XACK
               ldb   sys_comport    * get com port
               jsr   sPutChar       * send to server
               lda   pack_type      * get packet type
               cmpa  #packet_NAME   * filename?
               bne   srv_stat1don   * set filename info
* copy over filename to compare buffer
               ldy   #dfilename     * point to filename buffer
               ldb   #11            * get number of characters to copy
srv_stat10     lda   ,x+            * get char
               jsr   toupper
               sta   ,y+            * copy it
               decb                 * done yet?
               bne   srv_stat10     * nope, keep it up
               ldb   #7             * copy over time stamp data
srv_stat15     lda   ,x+
               sta   ,y+
               decb
               bne   srv_stat15
               jsr   scandir        * go look for it
               tsta                 * did we fine it?
               bne   srv_statupdat  * nope, update it
* ok, the file exists, check the time of creation
               leax  16,x          * point to file timestamp
               ldy   #dyear         * point to packet timestamp
               ldb   #6             * there are 6 bytes to check
srv_stat20     lda   ,x+
               cmpa  ,y+
               bne   srv_statupdat  * file needs updating
               decb                 * done yet?
               bne   srv_stat20     * nope, keep checking
               clra                 * file is ok
               bra   srv_statupdat0 * don't update it

* ok it nees updating, send back status code end return
srv_statupdat  lda   #NEEDS_UPDATING * tell the server ok
srv_statupdat0 ldb   sys_comport    
               jsr   sPutChar       * really tell it
* restore old mmu and return
srv_stat1don   puls  a              * get old MMU off of stack
               sta   $ffa0          * set it
srv_statdone
               clra
               ldb   sys_comport    * get com port used
					jsr   sPutChar
					jsr   sPutChar
					puls  d,x,y,u,pc     * return




srv_req_msg	fcb	$0d
				fcc	"System update initiated"
				fcb	$0d,$00
*
* Do server requests
*
srv_request	cmpa	#$fe
		bne     @b
		lda     #$fe
		ldb     sys_comport * get the com port to talk to
		jsr     sPutChar
		jsr     dgetchar
		cmpa    #$fd
		beq     @a
@b		rts
@a		lda     #$fd
		ldb     sys_comport * get the com port to talk to
		jsr     sPutChar
		ldx		#srv_req_msg
      jsr		xprintf

@a		jsr     dgetchar
		tsta
		beq     @a
*
* Check for download
*
		cmpa  #$90           * Is this a download request
		bne   @b					* no, keep checking
		jsr   srv_download	* Go download a file
		bra   @a					* Keep going
@b		cmpa  #$91           * is this a status request?
		bne   @c					* nope
		jsr   srv_status     * got get status
@c		cmpa	#$92				* Is this an encrypt mode?
		bne	@z
		jsr   do_encrypt		*
		bra	@a
@z		cmpa    #$ff
		bne     @a
		rts



do_encrypt
		lda   #$a2
		ldb   sys_comport * get the com port to talk to
		jsr   sPutChar		* Send ack
		lda   #$a2
		ldb   sys_comport * get the com port to talk to
		jsr   sPutChar		* Send ack
		jsr	dgetchar
		cmpa	#$93
		beq	@a
		rts
@a		jsr	dgetchar		* Get encrypt character
		sta	encrypt		* save it
@b		rts



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
