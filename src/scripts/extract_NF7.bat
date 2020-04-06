cbrom %1 /xgroup 		extract awardext.rom
cbrom %1 /acpi 		extract ACPITBL.BIN
cbrom %1 /epa 		extract AwardBmp.bmp
cbrom %1 /ygroup 		extract awardeyt.rom
rem cbrom %1 /fnt1 		extract font1.awd
cbrom %1 /group0 		extract _EN_CODE.BIN
cbrom %1 /oem0 		extract spectrum.exe
rem echo 1 | cbrom %1 /vga	extract NV1ABIOS.ROM
echo a | cbrom %1 /pci 	extract bootmngr.rom
echo b | cbrom %1 /pci  	extract 4402.bin
rem cbrom %1 /logo 		extract NF7-256n.bmp

cbrom %1 /d