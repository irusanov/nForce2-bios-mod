cbrom %1 /xgroup awardext.rom
cbrom %1 /acpi ACPITBL.BIN
cbrom %1 /epa AwardBmp.bmp
cbrom %1 /ygroup awardeyt.rom
rem cbrom %1 /fnt1 font1.awd
cbrom %1 /group0 _EN_CODE.BIN
rem echo a | cbrom %1 /pci NVPXES.NIC
echo a | cbrom %1 /pci bootmngr.rom
echo b | cbrom %1 /pci 4402.bin
cbrom %1 /oem0 spectrum.exe
rem cbrom %1 /logo NF7-256n.bmp
cbrom %1 /isa NF7_ISA_OROM_v1.BIN

cbrom %1 /d