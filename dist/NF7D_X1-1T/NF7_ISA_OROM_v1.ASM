; *************************************************************************************
; NVIDIA nForce2 custom option ROM for Abit NF7
; v1.0
; author: irusanov
; 23 Nov 2019
; Credits to tictac, pinczakko, polygon and TzK
; *************************************************************************************
use16                                         ; 16bit mode
ROM_SIZE_IN_BLOCK = 4                         ; 1 means ROM size is 1 block (512 bytes)
ROM_SIZE_IN_BYTE = ROM_SIZE_IN_BLOCK * 512    ; number of 512 byte blocks

define PCI_ADDR_PORT    0xCF8
define PCI_DATA_PORT    0xCFC
define CMOS_ADDR_PORT   0x70
define CMOS_DATA_PORT   0x71

macro configurePort pci
{
    mov eax, pci
    mov dx, PCI_ADDR_PORT
    out dx, eax
}

macro readPciReg pci
{
    configurePort pci
    mov dx, PCI_DATA_PORT
    in eax, dx
}

macro writePciReg pci, data, mask
{
    readPciReg pci
    and eax, mask
    or eax, data
    out dx, eax
}

macro readCmosReg reg, mask
{
    mov al, reg                                 ; set CMOS index
    out CMOS_ADDR_PORT, al                      ; send register offset
    in al, CMOS_DATA_PORT                       ; read CMOS data
    and al, mask                                ; mask the data and zero unneeded bits
}

ROMStart:
    db 0x055, 0x0AA                             ; ROM Header 55,AA -> Bootable rom
    db (ROMEnd - ROMStart)/512                  ; ROM Size in 512 bytes
    jmp MAIN                                    ; jump to main routine
    db 0                                        ; checksum, to be filled in later
    times (256)-($-$$) db 0                     ; locate Main routine at 100h

MAIN:
    ; save all registers for later restore
    pushfd
    pusha

    call set_video_mode
    call print_newline
    mov si, rom_line_1                          ; put string position into SI
    call print_string

    mov si, rom_line_2
    call print_string

    mov si, rom_line_3
    call print_string

    call print_newline

; --------------------------------------------------------------------------------
set_trc:
    ; read tRC from CMOS
    readCmosReg 0x75, 0x1F

    cmp al, 0
    je set_trfc

    xor ebx, ebx
    mov bl, al
    writePciReg 0x80000190, ebx, 0xFFFFFFE0

; --------------------------------------------------------------------------------
set_trfc:
    ; read tRFC from CMOS
    readCmosReg 0x76, 0x1F

    cmp al, 0
    je set_slew_rate

    xor ebx, ebx
    mov bh, al
    writePciReg 0x80000190, ebx, 0xFFFFE0FF

; --------------------------------------------------------------------------------
set_slew_rate:
    ; read slew rate from CMOS
    readCmosReg 0x78, 0x0F

    cmp al, 0
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
    ; read drive strength from CMOS
    readCmosReg 0x78, 0xF0

    cmp al, 0
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
    ; read tREF from CMOS
    readCmosReg 0x77, 0x1F

    cmp al, 0
    je codeend

    xor ebx, ebx

    cmp al, 0x01
    je .tref1
    cmp al, 0x02
    je .tref2
    cmp al, 0x03
    je .tref3
    cmp al, 0x04
    je .tref4
    cmp al, 0x05
    je .tref5
    cmp al, 0x06
    je .tref6
    cmp al, 0x07
    je .tref7
    cmp al, 0x08
    je .tref8
    cmp al, 0x09
    je .tref9
    cmp al, 0x0A
    je .tref10
    cmp al, 0x0B
    je .tref11
    cmp al, 0x0C
    je .tref12
    cmp al, 0x0D
    je .tref13
    cmp al, 0x0E
    je .tref14
    cmp al, 0x0F
    je .tref15
    cmp al, 0x10
    je .tref16
    cmp al, 0x11
    je .tref17
    cmp al, 0x12
    je .tref18
    cmp al, 0x13
    je .tref19
    cmp al, 0x14
    je .tref20
    cmp al, 0x15
    je .tref21
    cmp al, 0x16
    je .tref22
    cmp al, 0x17
    je .tref23
    cmp al, 0x18
    je .tref24
    cmp al, 0x19
    je .tref25
    cmp al, 0x1A
    je .tref26
    cmp al, 0x1B
    je .tref27
    cmp al, 0x1C
    je .tref28
    cmp al, 0x1D
    je .tref29
    cmp al, 0x1E
    je .tref30

  .tref1:
    mov ebx, 0x0010                           ; 0016 Cycles
    jmp .end
  .tref2:
    mov ebx, 0x0020                           ; 0032 Cycles
    jmp .end
  .tref3:
    mov ebx, 0x0040                           ; 0064 Cycles
    jmp .end
  .tref4:
    mov ebx, 0x0080                           ; 0128 Cycles
    jmp .end
  .tref5:
    mov ebx, 0x0184                           ; 0388 Cycles
    jmp .end
  .tref6:
    mov ebx, 0x0204                           ; 0516 Cycles
    jmp .end
  .tref7:
    mov ebx, 0x0288                           ; 0648 Cycles
    jmp .end
  .tref8:
    mov ebx, 0x0308                           ; 0776 Cycles
    jmp .end
  .tref9:
    mov ebx, 0x030C                           ; 0780 Cycles
    jmp .end
  .tref10:
    mov ebx, 0x038C                           ; 0908 Cycles
    jmp .end
  .tref11:
    mov ebx, 0x0408                           ; 1032 Cycles
    jmp .end
  .tref12:
    mov ebx, 0x0490                           ; 1168 Cycles
    jmp .end
  .tref13:
    mov ebx, 0x0510                           ; 1296 Cycles
    jmp .end
  .tref14:
    mov ebx, 0x0600                           ; 1536 Cycles
    jmp .end
  .tref15:
    mov ebx, 0x0610                           ; 1552 Cycles
    jmp .end
  .tref16:
    mov ebx, 0x0618                           ; 1560 Cycles
    jmp .end
  .tref17:
    mov ebx, 0x0718                           ; 1816 Cycles
    jmp .end
  .tref18:
    mov ebx, 0x0800                           ; 2048 Cycles
    jmp .end
  .tref19:
    mov ebx, 0x0810                           ; 2064 Cycles
    jmp .end
  .tref20:
    mov ebx, 0x0920                           ; 2336 Cycles
    jmp .end
  .tref21:
    mov ebx, 0x0A00                           ; 2560 Cycles
    jmp .end
  .tref22:
    mov ebx, 0x0A20                           ; 2592 Cycles
    jmp .end
  .tref23:
    mov ebx, 0x0C00                           ; 3072 Cycles
    jmp .end
  .tref24:
    mov ebx, 0x0C30                           ; 3120 Cycles
    jmp .end
  .tref25:
    mov ebx, 0x0E30                           ; 3632 Cycles
    jmp .end
  .tref26:
    mov ebx, 0x0E64                           ; 3684 Cycles
    jmp .end
  .tref27:
    mov ebx, 0x1020                           ; 4128 Cycles
    jmp .end
  .tref28:
    mov ebx, 0x1064                           ; 4196 Cycles
    jmp .end
  .tref29:
    mov ebx, 0x1240                           ; 4672 Cycles
    jmp .end
  .tref30:
    mov ebx, 0x1264                           ; 4708 Cycles
    jmp .end

  .end:
    writePciReg 0x80000160, ebx, 0xFFFF0000
    jmp codeend

; --------------------------------------------------------------------------------
; Sets the video mode, using function 00h from INT10
; http://www.ctyme.com/intr/int-10.htm
set_video_mode:
    mov ah, 00h                               ; INT10/AH=00h - set video mode function
    mov al, 12h                               ; EGA,VGA, 16 colors
    int 10h

    ret

; --------------------------------------------------------------------------------
; Prints a new string to the tty
; IN: SI = message location
print_string:
    mov ah, 0Eh                               ; INT10 tty function
    xor bx, bx
    mov bl, 0Eh                               ; set text color, 0Eh = Yellow

  .repeat:
    mov al, [cs:si]                           ; get char from string
    inc si
    cmp al, 0
    je .done

    int 10h
    jmp .repeat

  .done:
    ret

; --------------------------------------------------------------------------------
; Prints a new line to the tty
print_newline:
    mov ah, 0x0E
    mov al, 13
    int 10h
    mov al, 10
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

    inc al
    mov cx, 0Fh
    mov dx, 4240h                           ; 1mil us = 1 second
    mov ah, 86h                             ; INT 15h, 86h (134) Wait
    int 15h
    jmp .repeat

  .done:
    ret

; --------------------------------------------------------------------------------
codeend:
    ; wait
    mov bl, 3
    call delay

    popa
    popfd
    ; return far to system bios routine
    retf

  ; String ends with 0x0d (Carriage return) and 0x0a (linefeed) to
  ; advance cursor to the beginning of next line
  rom_line_1 db " ABIT NF7 v2 -- OC OPTION ROM", 0x0D, 0x0A, 0
  rom_line_2 db " version 1.00", 0x0D, 0x0A, 0
  rom_line_3 db " 23/11/2019", 0x0D, 0x0A, 0
  ; use 00h as the padding bytes until we reach the ROM size
  ; The last byte (512th) will be the patch_byte for the checksum
  ; patch_byte is calculated and automagically inserted below
  times (ROM_SIZE_IN_BYTE-$) db 0
  PREV_CHKSUM = 0
  repeat $
  load CHKSUM byte from %-1
  CHKSUM = (PREV_CHKSUM + CHKSUM) mod 0x100
  PREV_CHKSUM = CHKSUM
  end repeat
  ; store the patch_byte
  store byte (0x100 - CHKSUM) at ($-1)
ROMEnd:
