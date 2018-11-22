@echo off
cls
kasm -I../system server.asm -o=server.x
kasm -I../system srvload.asm -o=server.bin
file2dsk server.bin
del server.x
REM del server.bin


