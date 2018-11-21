//	
//	Copyright (C) 1996, 1997, 2014, 2018, by Chet Simpson
//	
//	This file is distributed under the MIT License. See notice at the end
//	of this file.
//	
/*
	This uploads a file to the coco
*/
#include <dos.h>
#include <dir.h>
#include <mem.h>
#include <string.h>
#include <conio.h>
#include	<stdio.h>
#include <stdlib.h>
#include <io.h>
#include <ctype.h>

#include "..\..\include\async.h"
#include "window.h"
#include "upload.h"


#define HEADERSIG			0xaf54
#define ENDMARKER			0x54af
#define ACK					0x05
#define NACK				0x25
#define READY				0xde
#define NEEDS_UPDATING	0xed
#define TIMEOUTCOUNT		10

/* define packet types */
#define packet_NAME	0x30
#define packet_DATA	0x31
#define packet_EOT	0x94

/* define coco filetypes */
#define filetype_BIN	0x01
#define filetype_DAT	0x02

/* define return type */
#define packet_OK		0x01
#define packet_BAD	0x02
#define packet_TIMED	0x03
#define packet_SEND	0x04

#define packet_DSIZE	2048


int a_waitchar(ASYNC *port);


int SendByte(unsigned char data, ASYNC *port)
{
	return(a_putc(data, port));
}

int SendWord(unsigned int data, ASYNC *port)
{
	a_putc((data >> 8) & 0xff, port);
	a_putc(data & 0xff, port);
	return 0;
}

int timedwait(ASYNC *port)
{
	int waitflag, ch;

	waitflag = 0;
	while(waitflag++ < 500)
		{
		ch = a_getc(port);	/* chech for incoming character */
		if(ch == -1) delay(10);			/* no wait */
		else return(ch);	/* yes we got one */
		}
	return(-1);
}

int SendPacket(unsigned char *packdata, unsigned int size, unsigned char type, ASYNC *port, int outflag)
{
	unsigned int	checksum;
	int	count;
	int ch;
	unsigned int flag, retry;

	WINDEF	*oldwin;

	oldwin = SetActiveWindow(&window3);

	for(count = 0, checksum = 0; count < size; count++)
		checksum += packdata[count];


	retry = 0;

	while(retry < 10)
		{
		if(outflag != 0)
			{
			gotoxy(1, 5);
			cprintf("Sending packet: [type %4i with %4i bytes and a checksum of %4X]", type, size, checksum);
			gotoxy(30, 2);
			cprintf("Retry: %2i", retry);
			clreol();
			}

		count = 0;
		while(count < 10)
			{
			if(outflag != 0)
				{
				gotoxy(30, 3);
				cprintf("Timeout: %2i", count);
				clreol();
				}
			if(timedwait(port) == READY) break;
			count++;
			}
		if(count < 10)
			{
			if(outflag != 0)
				{
				gotoxy(60,1);
				cprintf("Got READY");
				clreol();
				}

			SendWord(HEADERSIG, port);
			SendByte(type, port);
			SendWord(size, port);
			for(count = 0; count < size; count++)
				{
				a_putc(packdata[count], port);
				}
			SendWord(checksum, port);
			SendWord(ENDMARKER, port);

			if(outflag != 0)
				{
				gotoxy(60,1);
				clreol();
				}
			flag = count = 0;


			while((count < 10) && flag == 0)
				{
				ch = timedwait(port);
				if(ch == ACK) flag = packet_OK;
				else if(ch == NACK) flag = packet_BAD;
				else
					{
					count++;
					if(outflag != 0)
						{
						gotoxy(30, 3);
						cprintf("Timeout: %2i", count);
						clreol();
						}
					}
				}
			}
		if(flag == packet_BAD) retry++;
		else retry = 10;;
		}
	SetActiveWindow(oldwin);
	return(flag);
}

int SendFilenamePacket(char *path, unsigned int type, ASYNC *port, int outflag)
{
	HEADPACK header;
	char	xdrive[MAXDRIVE];
	char	xdir[MAXDIR];
	char	xfname[MAXFILE];
	char	xext[MAXEXT];
	int i;
	ftime		Ftime;
	FILE	*file;

	if((file = fopen(path, "rb")) == NULL) return (-1);
	getftime(fileno(file), &Ftime);
	fclose(file);

	/* build and send filename packet */
	fnsplit(path, xdrive, xdir, xfname, xext);
	memset((void *)&header, 0x20, sizeof(HEADPACK));
	memcpy(header.filename, xfname, strlen(xfname));
	memcpy(header.ext, &xext[1], strlen(&xext[1]));

	for(i = 0; i < 8; i++)
		header.filename[i] = toupper(header.filename[i]);
	for(i = 0; i < 3; i++)
		header.ext[i] = toupper(header.ext[i]);

	header.type = type;
	header.year = Ftime.ft_year;
	header.month = Ftime.ft_month;
	header.day = Ftime.ft_day;
	header.hour = Ftime.ft_hour;
	header.minute = Ftime.ft_min;
	header.second = Ftime.ft_tsec;
	return(SendPacket((unsigned char *)&header, sizeof(HEADPACK), packet_NAME, port, outflag));
}

int UploadFile(char *path, ASYNC *port, char type)
{
	int	flag;
	long	size, tosend = 0, sent = 0, sending, count;
	unsigned char buffer[4096];

	FILE	*file;

	a_putc(0x90, port);	/* send out upload initiate sequence */
	a_putc(0x90, port);
	if(timedwait(port) != 0xa0 && timedwait(port) != 0xa0)
		{
		cprintf("System did not respond\n");
		return (-1);	/* get upload acceptance sequence */
      }

	SetActiveWindow(&window3);
	gotoxy(1,1);
	cprintf("Sending   : %s", path);
	gotoxy(1, 2);
	cprintf("bytes sent: %6i", sent);
	gotoxy(1, 3);
	cprintf("bytes left: %6i", tosend);

	/* build and send filename packet */
	flag = SendFilenamePacket(path, type, port, 1);

	if((file = fopen(path, "rb")) == NULL) return (-1);
	size = filelength(fileno(file));
	tosend = size;
	sent = 0;

	while((tosend != 0) && (flag == packet_OK))
		{
		if(tosend > packet_DSIZE) sending = packet_DSIZE;
		else sending = tosend;
		for(count = 0; count < sending; count++) buffer[(int)count] = (unsigned char)fgetc(file);
		flag = SendPacket(buffer, (int)sending, packet_DATA, port, 1);
		if(flag == packet_OK)
			{
			tosend -= sending;
			sent += sending;
			gotoxy(1, 2);
			cprintf("bytes sent: %6i", sent);
			gotoxy(1, 3);
			cprintf("bytes left: %6i", tosend);
			}
		}
	if(flag == packet_OK) SendPacket(0, 0, packet_EOT, port, 1);	/* send end of file */
	fclose(file);
	flag = timedwait(port);	/* get response */
	if(flag == 0xaf)
		{
		a_putc(ACK, port);	/* send out upload initiate sequence */
		gotoxy(60,1);
		cprintf("Saving file. . .");
		for(count = 0; count <100; count++)
			{
			flag = timedwait(port);
			if(flag == 0xae) break;
			}
		}
	clrscr();

	SetActiveWindow(&window2);
	return(0);
}


int a_waitchar(ASYNC *port)
{
	int temp = -1;

	while(temp == -1)
		if((temp = a_getc(port)) == -1) delay(250);

	return(temp);
}

void do_encrypt(int a, ASYNC *port)
{
	a_iflush(port);
	a_putc(0x92, port);	/* send out upload initiate sequence */
	delay(10);
	if(timedwait(port) != 0xa2)
		{
		cprintf("No response from encryption handler\n\r");
		return;	/* get upload acceptance sequence */
		}
	a_putc(0x93, port);	/* send out upload initiate sequence */
	a_putc((unsigned char)a, port);	/* send out upload initiate sequence */
	cprintf("Encryption value %i set\n\r", a);


}
int GetUploadStatus(char *path, ASYNC *port, unsigned int type)
{
	int	ch;

//	return(NEEDS_UPDATING);
	a_putc(0x91, port);	/* send out upload initiate sequence */
	delay(10);
	a_putc(0x91, port);
	delay(10);
	if(timedwait(port) != 0xa1 && timedwait(port) != 0xa1)
		{
		cprintf("No response getting upload status\n\r");
		return (-1);	/* get upload acceptance sequence */
		}

	SendFilenamePacket(path, type, port, 0);
	ch = timedwait(port);	/* get upload acceptance sequence */
	return(ch);
}

int UploadUpdate(ASYNC *port, int mode)
{
	FILE	*file, *temp;
	/* upload a file */
	char	*params[50];
	char	ask;

	char	buffer[500];
	int	eoflag, count, param, size, err;

	cprintf("\n\rInitiating system update. . .\n\r");

	file = fopen("update.scr", "rt");
	if(file == NULL)
		{
		cprintf("update.scr file not found\n\r");
		return -1;
		}

	a_iflush(port);

	SendByte(0xfe, port);
	if(timedwait(port) != 0xfe)
		{
		SendByte(0xff, port);
		cprintf("CoCo host did not respond!\n\r");
		fclose(file);
		return(0);
		}
	SendByte(0xfd, port);
	if(timedwait(port) != 0xfd)
		{
		SendByte(0xff, port);
		cprintf("CoCo host did not respond!\n\r");
		fclose(file);
		return(0);
		}

	delay(50);

	SetActiveWindow(&window3);
	clrscr();
	SetActiveWindow(&window2);

	count = eoflag = 0;
	while(eoflag == 0)
		{
		if(fgets(buffer, 500, file) == NULL) eoflag++;
		else
			{
			/* convert to all lowercase and strip CR from buffer */
			for(param = count = 0; count < strlen(buffer); count++)	/* find all params in line */
				{
				if((buffer[count] == 0x0d) || buffer[count] == 0x0a)
						buffer[count] = 0;	/* reset cr to EOL */

				buffer[count] = tolower(buffer[count]);		/* convert to lower case */
				}

			if(strncmp(buffer, "ask", 3) == 0) {
				cprintf("%s (Y/N/Q)?", &buffer[3]);
				while(!kbhit());
				cprintf("\n\r");
				ask = tolower(getch());
				while(ask == 'n') {
					if(fgets(buffer, 500, file) == NULL) {
						eoflag++;
						ask = 0;
						*buffer = 0;
					}
					if(strncmp(buffer, "end", 3) == 0) ask++;
				}
				if(ask == 'q') {
					eoflag++;
					*buffer = 0;
				}
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
			if(mode && strcmp(params[0], "encrypt") == NULL)
				{
				do_encrypt(atoi(params[1]), port);
				}
			else if(strcmp(params[0], "update") == NULL)
				{
				if((temp = fopen(params[1], "rb")) != NULL)
					{
					fclose(temp);
					a_iflush(port);
					if((err = GetUploadStatus(params[1], port, filetype_BIN)) ==
							NEEDS_UPDATING)
						{
						cprintf("Updating %s\n\r", params[1]);
						a_iflush(port);
						if(UploadFile(params[1], port, filetype_BIN) == -1)
							{
							SendByte(0xff, port);
							cprintf("CoCo host did not respond!\n\r");
							fclose(file);
							return(0);
							}
//						a_iflush(port);
						}
					else if(err == -1)
						{
						SendByte(0xff, port);
						cprintf("CoCo host did not respond!\n\r");
						fclose(file);
						return(0);
						}
					else cprintf("%s does not need updating. Skipping file\n\r", params[1]);
					}
				else cprintf("%s does not exist. Cannot update\n\r", params[1]);
				}
			}
		}
	fclose(file);
	SendByte(0xff, port);
	fclose(file);
	return(0);
}



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
