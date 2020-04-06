cbrom %1 /xgroup release
cbrom %1 /acpi release
cbrom %1 /epa release
cbrom %1 /ygroup release
rem cbrom %1 /fnt1 release
cbrom %1 /group0 release
cbrom %1 /oem0 release
echo a | cbrom %1 /pci release
echo b | cbrom %1 /pci release
rem cbrom %1 /logo release
cbrom %1 /isa release

cbrom %1 /d