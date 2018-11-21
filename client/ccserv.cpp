//	
//	Copyright (C) 1996, 1997, 2014, 2018, by Chet Simpson
//	
//	This file is distributed under the MIT License. See notice at the end
//	of this file.
//	

/////////////
/////////////
//// This program is intended to get you started using the ASYNC
//// library. MYPROG is just a simple little dumb (stupid, actually)
//// terminal emulator. It doesn't process ANSI codes, so, depending on
//// what you talk to, you may seem some strange characters from time to
//// time.
////
//// The first thing to do is to make sure that ASYNCS.LIB (assuming
//// that you'll be using the small memory model) and ASYNC.H are in
//// your LIB and INCLUDE directories, respectively. Use CREASYNC.BAT to
//// create the ASYNCx.LIB files if you haven't already done so.
////
//// To compile MYPROG.C, just issue the command
////
////   tcc -ms myprog asyncs.lib
////
//// This will compile MYPROG.C and link it with the functions it needs
//// from ASYNCS.LIB to produce the executable file MYPROG.EXE.
////
//// This program was originally intended to talk to a 2400 baud modem
//// using no parity, 8 data bits, and 1 stop bit. Change the parameters
//// to a_open in main() if you want to change these communication
//// parameters.
/////////////
/////////////
#include <ctype.h>
#include <bios.h>
#include <conio.h>
#include <dos.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "../../include/async.h"
#include "window.h"
#include "upload.h"


#define ALT_X		0x2d
#define key_F1		0x3b
#define key_F2		0x3c
#define key_F3		0x3d
#define key_F4		0x3e
#define key_F5		0x3f
#define key_F6		0x40
#define key_F7		0x41
#define key_F8		0x42
#define key_F9		0x43
#define key_F10	0x44


void PCCCServer(ASYNC *port);
ASYNC *InitServer(int port, int sendbuf, int recvbuf)
{
	ASYNC *com;
	text_info	tinfo;
	init_asynch();

	com=a_open(port,19200,PAR_NONE,8,1,sendbuf,recvbuf);

	if (!com)
		{
		cprintf("Cannot open COM%i.\r\n", port);
		return NULL;
		}
/* Set up the screen and other nifty things */
	textmode(C4350);
	gettextinfo(&tinfo);
	window2.bottom = tinfo.screenheight-5;
	window3.top = tinfo.screenheight-4;
	window3.bottom = tinfo.screenheight;
	SetActiveWindow(&window3);
	clrscr();
//	cprintf("[ALT-X] Exit program   [F2] Update  [F3]");

	SetActiveWindow(&window1);
	clrscr();
	cprintf("     MediaLink PC->CoCo MC6809/HT6309 Cross Development Server version 1.0 \n\r");
	cprintf("  Copyright (c) 1996 MediaLink Development Systems  -  Written by Chet Simpson\n\r");
	cprintf(" Port: %i", port);
	SetActiveWindow(&window2);
	clrscr();

	return (com);
}


int main(void)
{
	ASYNC *com;
	int comport = 2;
	FILE *config;
	int eoflag = 0;
	char buffer[500];
	int param, count, size;
	char *params[50];
//
// Open COM2 at 2400 buad for no parity, 8 data bits, 1 stop bit, using
// a 4096-byte input buffer and no output buffer.
//
	config = fopen("update.scr", "rt");
	if(config)
		{
		while(eoflag == 0)
			{
			if(fgets(buffer, 500, config) == NULL) eoflag++;
			else
				{
				/* convert to all lowercase and strip CR from buffer */
				for(param = count = 0; count < strlen(buffer); count++)	/* find all params in line */
					{
					if((buffer[count] == 0x0d) || buffer[count] == 0x0a)
							buffer[count] = 0;	/* reset cr to EOL */

					buffer[count] = tolower(buffer[count]);		/* convert to lower case */
					}
				/* get all params */
				size = strlen(buffer);
				for(count = 0; count < size;)
					{
					params[param++] = &buffer[count];	/* mark another parameter */
					while((buffer[count] != ' ') && (buffer[count] != 0x00)) count++;	/* skip to whitespace */
					buffer[count++] = 0;
					while(buffer[count] == ' ' && buffer[count] != 0x00) count++;	/* skip until non-whitespace */
					}
				if(strcmp(params[0], "port") == NULL) comport = atoi(params[1]);

				}
			}
		}

	fclose(config);
	com = InitServer(comport, 4096, 4096);
//
// Start the dumb terminal emulator.
//
	PCCCServer(com);
//
// Close COM2. (Never forget to do this.)
//
	a_close(com,0);
	return 0;
} // end of void main().

void PCCCServer(ASYNC *port)
{
	int ch;//,x,y;
	do
		{// If a key has been pressed, read it from the keyboard.
		if (bioskey(1)) ch=bioskey(0);
		else ch=0;
		// If Alt-X was pressed, leave this loop.
		if(!(ch & 0xff) && ch != 0)
			{
			switch(ch >>8)
				{
				case ALT_X:
					a_iflush(port);
					a_oflush(port);
					return;
				case key_F1:
					UploadUpdate(port, 1);
					break;
				case key_F2:
					UploadUpdate(port, 0);
					break;

				default:
					cprintf("\n\rValue: %04X\n\r", ch);
				}
			}
		else
			{
			// If a key was pressed, the scan code off of ch and transmit it.
			ch &= 0xff;
			if (ch) a_putc(ch,port);
			}

		// If a character has been received, display it.
		ch=a_getc(port);

		if (ch !=-1)
			{
			if(ch < 32)	/* process control characters */
				{
				switch(ch)
					{
					case 0: // Ignore null characters.
						break;
					case 7: // Beep for bell characters.
						sound(1000);
						sleep(1);
						nosound();
						break;
					case 8: // Do back spaces manually.
						cprintf("\x8\x20\x8\0");
						break;
					case 0x0c:
						clrscr();
						break;
					case '\n': // Ignore linefeeds.
						break;
					case '\r': // Treat carriage returns as carriage return/line feeds.
						cputs("\r\n");
						break;
					}
				}
			else if(ch > 127)	/* process command requests */
				{
				}
			else putch(ch); /* print the character */
			}
  } while(1);
} // end of dumbterm(port).



//	
//	Copyright (C) 1996, 1997, 2014, 2018, by Chet Simpson
//	
//	Permission is hereby granted, free of charge, to any person
//	obtaining a copy of this software and associated documentation
//	files (the "Software"), to deal in the Software without
//	restriction, including without limitation the rights to use,
//	copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the
//	Software is furnished to do so, subject to the following
//	conditions:
//	
//	The above copyright notice and this permission notice shall be
//	included in all copies or substantial portions of the Software.
//	
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//	OTHER DEALINGS IN THE SOFTWARE.
//	
