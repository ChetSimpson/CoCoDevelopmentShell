@echo off
cls
casm server.asm -N=server.x
casm srvload.asm -N=server.bin
copy server.bin ..\saint\output\saint.bin
del server.x
del server.bin


