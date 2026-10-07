; *************************************************************************************
; NVIDIA nForce2 custom option ROM for Abit NF7
; v1.0
; author: irusanov
;
; v1.0: 23 Nov 2019
;   * First release
;
; v1.1: 07 Oct 2026
;   * Optimize code with claude
; 
; Credits to tictac, pinczakko, polygon and TzK
; *************************************************************************************
use16                                         ; 16bit mode
ROM_SIZE_IN_BLOCK = 1                         ; 1 means ROM size is 1 block (512 bytes)
ROM_SIZE_IN_BYTE = ROM_SIZE_IN_BLOCK * 512    ; number of 512 byte blocks

define PCI_ADDR_PORT    0xCF8
define PCI_DATA_PORT    0xCFC
define CMOS_ADDR_PORT   0x70
define CMOS_DATA_PORT   0x71

TREF_COUNT = 30                               ; number of entries in tref_table
DELAY_SECONDS = 3                             ; how long the banner stays on screen

; Read-modify-write of a PCI config dword, through pci_rmw to keep the ROM small
; data must not be ECX
macro writePciReg pci, data, mask
{
    mov eax, pci
    mov ecx, mask
  if ~ data eq ebx
    mov ebx, data
  end if
    call pci_rmw
}

; The index write and the data read must not be split by an interrupt handler
; that also uses port 70h (e.g. the RTC IRQ8 handler), so call this with IF=0.
macro readCmosReg reg, mask
{
    mov al, reg                                 ; set CMOS index
    out CMOS_ADDR_PORT, al                      ; send register offset
    in al, CMOS_DATA_PORT                       ; read CMOS data
    and al, mask                                ; mask the data, sets ZF when the value is 0 (auto)
}

ROMStart:
    db 0x055, 0x0AA                             ; ROM Header 55,AA -> Bootable rom
    db (ROMEnd - ROMStart)/512                  ; ROM Size in 512 bytes
    jmp MAIN                                    ; jump to main routine (offset 3)

MAIN:
    ; save all registers for later restore.
    ; pushad, not pusha: the code below uses EAX, EBX and EDX, and pusha only
    ; saves the low 16 bits, so the BIOS would get its upper halves back clobbered.
    pushfd
    pushad

    call set_video_mode
    xor bx, bx                                  ; BH = video page 0 for all INT 10h/0Eh calls
    call print_newline
    mov si, rom_line_1                          ; put string position into SI
    call print_string

    mov si, rom_line_2
    call print_string

    mov si, rom_line_3
    call print_string

    call print_newline

    cli                                         ; keep CMOS index/data and CF8/CFC pairs atomic

; --------------------------------------------------------------------------------
set_trc:
    ; read tRC from CMOS, D0F1 0x90 [4:0]
    readCmosReg 0x75, 0x1F

    je set_trfc

    movzx ebx, al
    writePciReg 0x80000190, ebx, 0xFFFFFFE0

; --------------------------------------------------------------------------------
set_trfc:
    ; read tRFC from CMOS, D0F1 0x90 [12:8]
    readCmosReg 0x76, 0x1F

    je set_slew_rate

    xor ebx, ebx
    mov bh, al
    writePciReg 0x80000190, ebx, 0xFFFFE0FF

; --------------------------------------------------------------------------------
set_slew_rate:
    ; read slew rate from CMOS (low nibble)
    ; D0F4 0x64 (DIMM0), 0x66 (DIMM1), 0x7C (DIMM2), value in both nibbles
    readCmosReg 0x78, 0x0F

    je set_drive_strength

    xor ebx, ebx
    mov bl, al
    shl bl, 4
    or bl, al
    mov al, bl                                ; save bl
    shl ebx, 16                               ; shift bl to higher 16bit segment
    mov bl, al

    writePciReg 0x80000464, ebx, 0xFF00FF00   ; 66, 64

    and ebx, 0xFF00FFFF

    writePciReg 0x8000047C, ebx, 0xFFFFFF00   ; 7C

; --------------------------------------------------------------------------------
set_drive_strength:
    ; read drive strength from CMOS (high nibble)
    ; D0F4 A: 0x65, 0x67, 0x7D, B: 0x71, 0x73, 0x81, value in both nibbles
    readCmosReg 0x78, 0xF0

    je set_tref

    xor ebx, ebx
    mov bl, al
    shr bl, 4
    or bl, al
    mov al, bl  ; save bl
    shl ebx, 24 ; shift bl to highest 8bit segment
    mov bh, al

    writePciReg 0x80000464, ebx, 0x00FF00FF   ; 67, 65
    writePciReg 0x80000470, ebx, 0x00FF00FF   ; 73, 71

    and ebx, 0x00FFFFFF

    writePciReg 0x8000047C, ebx, 0xFFFF00FF   ; 7D
    writePciReg 0x80000480, ebx, 0xFFFF00FF   ; 81

; --------------------------------------------------------------------------------
set_tref:
    ; read tREF from CMOS, 1..TREF_COUNT, D0F1 0x60 [15:0]
    readCmosReg 0x77, 0x1F

    ; 0 = auto. Anything above the table (0x1F) is ignored;
    je regs_done
    cmp al, TREF_COUNT
    ja regs_done

    movzx bx, al
    dec bx
    shl bx, 1                                 ; word index
    movzx ebx, word [cs:tref_table + bx]

    writePciReg 0x80000160, ebx, 0xFFFF0000

regs_done:
    sti                                       ; INT 15h/86h needs interrupts
    jmp codeend

; --------------------------------------------------------------------------------
; PCI config read-modify-write: reg = (reg & ECX) | EBX
; IN: EAX = config address, EBX = data, ECX = mask
pci_rmw:
    mov dx, PCI_ADDR_PORT
    out dx, eax
    mov dl, PCI_DATA_PORT and 0xFF            ; DX = 0CFCh
    in eax, dx
    and eax, ecx
    or eax, ebx
    out dx, eax
    ret

; --------------------------------------------------------------------------------
; Sets the video mode, using function 00h from INT10
; http://www.ctyme.com/intr/int-10.htm
set_video_mode:
    mov ax, 0012h                             ; INT10/AH=00h set video mode, AL=12h EGA,VGA, 16 colors
    int 10h

    ret

; --------------------------------------------------------------------------------
; Prints a new string to the tty
; IN: SI = message location
;     BH = video page
print_string:
    mov bl, 0Eh                               ; set text color, 0Eh = Yellow

  .repeat:
    mov al, [cs:si]                           ; get char from string
    inc si
    test al, al                               ; 0 terminator
    je .done

    mov ah, 0Eh                               ; INT10 tty function (reloaded, not every BIOS preserves AH)
    int 10h
    jmp .repeat

  .done:
    ret

; --------------------------------------------------------------------------------
; Prints a new line to the tty
; IN: BH = video page
print_newline:
    mov ax, 0x0E0D
    int 10h
    mov ax, 0x0E0A
    int 10h

    ret

; --------------------------------------------------------------------------------
; Waits for a given time in seconds
; IN: BL
delay:
    mov al, 0

  .repeat:
    cmp al, bl
    je .done

    push ax
    mov cx, 0Fh
    mov dx, 4240h                           ; 1mil us = 1 second
    mov ah, 86h                             ; INT 15h, 86h (134) Wait
    int 15h
    pop ax                                  ; INT 15h returns status in AH, keep the counter safe
    inc al
    jmp .repeat

  .done:
    ret

; --------------------------------------------------------------------------------
codeend:
    ; wait
    mov bl, DELAY_SECONDS
    call delay

    popad
    popfd
    ; return far to system bios routine
    retf

  ; tREF register values, index = CMOS value - 1 (same list as nForce2 TWKR)
  tref_table:
    dw 0x0010, 0x0020, 0x0040, 0x0080           ;   16,   32,   64,  128 cycles
    dw 0x0184, 0x0204, 0x0288, 0x0308           ;  388,  516,  648,  776
    dw 0x030C, 0x038C, 0x0408, 0x0490           ;  780,  908, 1032, 1168
    dw 0x0510, 0x0600, 0x0610, 0x0618           ; 1296, 1536, 1552, 1560
    dw 0x0718, 0x0800, 0x0810, 0x0920           ; 1816, 2048, 2064, 2336
    dw 0x0A00, 0x0A20, 0x0C00, 0x0C30           ; 2560, 2592, 3072, 3120
    dw 0x0E30, 0x0E64, 0x1020, 0x1064           ; 3632, 3684, 4128, 4196
    dw 0x1240, 0x1264                           ; 4672, 4708
  if ($ - tref_table) / 2 <> TREF_COUNT
    display "tref_table size does not match TREF_COUNT", 13, 10
    err
  end if

  ; String ends with 0x0d (Carriage return) and 0x0a (linefeed) to
  ; advance cursor to the beginning of next line
  rom_line_1 db " ABIT NF7 v2 -- OC OPTION ROM", 0x0D, 0x0A, 0
  rom_line_2 db " version 1.1", 0x0D, 0x0A, 0
  rom_line_3 db " 07/11/2026", 0x0D, 0x0A, 0
  ; use 00h as the padding bytes until we reach the ROM size
  ; The last byte (512th) will be the patch_byte for the checksum
  ; patch_byte is calculated and automagically inserted below
  if $ >= ROM_SIZE_IN_BYTE
    display "Code does not fit, increase ROM_SIZE_IN_BLOCK", 13, 10
    err
  end if
  times (ROM_SIZE_IN_BYTE-$) db 0
  PREV_CHKSUM = 0
  repeat $
  load CHKSUM byte from %-1
  CHKSUM = (PREV_CHKSUM + CHKSUM) mod 0x100
  PREV_CHKSUM = CHKSUM
  end repeat
  ; store the patch_byte (and 0xFF: a sum of 0 would give 0x100, which doesn't fit a byte)
  store byte ((0x100 - CHKSUM) and 0xFF) at ($-1)
ROMEnd:
