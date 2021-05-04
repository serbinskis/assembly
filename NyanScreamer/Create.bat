@echo off
title NyanScreamerMBR
color 0a

:Check
if exist disk.img goto QEMU
if exist Build\frames.bin del Build\frames.bin >nul
if exist Build\stage2-uncompressed.bin del Build\stage2-uncompressed.bin >nul
if exist Build\stage2-compressed.bin del Build\stage2-compressed.bin >nul
md Build >nul
cls


:Start
cd Data\Frames
..\..\Programs\png2bin.exe 00.png 01.png 02.png ..\..\Build\frames.bin



:Next
cd ..\Source >NUL
..\..\Programs\nasm.exe -f bin main.asm -o ..\..\Build\stage2-uncompressed.bin
..\..\Programs\compress.exe ..\..\Build\stage2-uncompressed.bin ..\..\Build\stage2-compressed.bin >nul
..\..\Programs\nasm.exe -o ..\..\disk.img bootloader.asm
cd ..\.. >NUL


:QEMU
pause
Programs\QEMU\qemu -s -soundhw pcspk -fda disk.img
exit