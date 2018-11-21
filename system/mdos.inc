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
FCBTYP EQU 0 File mode type
FCBDRV EQU 1 File drive
FCBFGR EQU 2 First granual of file
FCBCGR EQU 3 Current granual of file
FCBSEC EQU 4 Current sector of file
FCBCPT EQU 5 Next character pointer
FCBDIR EQU 6 Directory entry
FCBLST EQU 7 Number of bytes in last sector (2 byte value)
FCBDFL EQU 9 Input flag. $00=data left
FCBLFT EQU 10 Number of characters in buffer
FCBCON EQU 11 Offset fo FCB data buffer
*
FAT0   EQU 0 Active file counter
FAT1   EQU 1 Valid data flag
FATCON EQU 2 Offset to FAT table
*
FATLEN EQU 158+FATCON FAT table length
FCBLEN EQU 256+FCBCON FCB buffer length
DIRLEN EQU $20 Length of each directory entry
*
* Directory entry locations
*
DIRNAM EQU 0 Filename 
DIREXT EQU 8 Extension
DIRTYP EQU 11 File type
DIRASC EQU 12 ASCII flag
DIRGRN EQU 13 First granual
DIRLST EQU 14 Number of bytes used in last sector 
*
SECLEN EQU 256 Sector length
NUMFCB EQU 3  Number of FCB's program can handle
*
INPFIL EQU $10 Input file type
OUTFIL EQU $20 Output file type
RANFIL EQU $40 Random file type
APNFIL EQU $20 (Append file mode is same as output)
*
CR     EQU $0D Carriage return
SPACE  EQU $20 Space
SKP1   EQU $21 Skip 1 byte (BRN)
SKP2   EQU $8C Skip 2 bytes (CMPX)




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
