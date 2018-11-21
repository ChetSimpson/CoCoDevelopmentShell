@echo off
as9 scos.asm %1 %2 %3 %4 %5 %6 %7 %8 %9
dir | grep -i "system.bin"
check system.bin


