; UHCI.asm
; -- Implement support functions for the UHCI specification.

UHCI_PCI_CONTROLLER_CLASS_ID        equ 0x0C
UHCI_PCI_CONTROLLER_SUBCLASS_ID     equ 0x03
UHCI_PCI_CONTROLLER_INTERFACE_ID    equ 0x00
; The UHCI IO port is contained in BAR4 (offset 20h), see below for implementation

; Since there are 8 max supported USB devices of one type,
;  the driver needs to account for the fact that there may be 8 controllers.
UHCI_BARIO_ARRAY:   ; use this accessor for queries to a drive/controller id. Ex: BARIO_N = [UHCI_BARIO_ARRAY+((N-1)*2)]
UHCI_BARIO_1    dw 0x0000
UHCI_BARIO_2    dw 0x0000
UHCI_BARIO_3    dw 0x0000
UHCI_BARIO_4    dw 0x0000
UHCI_BARIO_5    dw 0x0000
UHCI_BARIO_6    dw 0x0000
UHCI_BARIO_7    dw 0x0000
UHCI_BARIO_8    dw 0x0000
; Each BAR I/O address is a BASE address (hence "BaseAR") for a configuration I/O port.
; Universal HCI follows this standard for its I/O Config Port Accesses:
;  [BASE+00h->WORD] : USBCMD, USB Command
;  [BASE+02h->WORD] : USBSTS, USB Status
;  [BASE+04h->WORD] : USBINTR, USB Interrupt-Enable
;  [BASE+06h->WORD] : FRNUM, USB Frame Number
;  [BASE+08h->DWORD]: FRBASE, USB Frame Base Address
;  [BASE+0Ch->DWORD]: SOFMOD, Start of Frame Modification
;  [BASE+10h->WORD] : PORTSC1, Port 1 Status/Control
;  [BASE+12h->WORD] : PORTSC2, Port 2 Status/Control
UHCI_USBCMD     equ 00h
UHCI_USBSTS     equ 02h
UHCI_USBINTR    equ 04h
UHCI_FRNUM      equ 06h
UHCI_FRBASE     equ 08h
UHCI_SOFMOD     equ 0Ch
UHCI_PORTSC1    equ 10h
UHCI_PORTSC2    equ 12h


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;DEBUGGING FUNCTIONS. To be deleted later when code is 100% bulletproof (never going to happen (; ).




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;POLLING/BOOLEAN/MISC FUNCTIONS.







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;READ/WRITE/STATUS FUNCTIONS.


; INPUTS:
;   ARG1: Size of value to read.
;   ARG2: Register Offset.
;   ARG3: BARIO# base I/O port.
; *--*--* All arguments are pushed in a single DWORD --> (ARG3<<16|ARG2<<8|ARG1).
;          This will be referenced in the driver specification as a ROO variable (Register, Offset, Opsize).
; OUTPUTS:
;   EAX = Value read.
; -- Reads a configuration register of the specified size, at the specified offset.
USB_UHCI_readFromBARIO:
    FunctionSetup
    MultiPush ebx,ecx,edx
    ZERO eax,ebx,ecx,edx

    mov strict word dx, [ebp+10]    ;arg3 - USB BARIO address
    mov strict byte cl, [ebp+9]     ;arg2 - added offset to read address
    add dl, cl
    mov strict byte bl, [ebp+8]     ;arg1 - size of operation

    cmp byte bl, BYTE_OPERATION
    je .readByte
    cmp byte bl, WORD_OPERATION
    je .readWord
    ; assume dword
    in eax, dx
    jmp .leaveCall
  .readByte:
    in al, dx
    jmp .leaveCall
  .readWord:
    in ax, dx
    jmp .leaveCall

 .leaveCall:
    MultiPop edx,ecx,ebx
    FunctionLeave


; INPUTS:
;   ARG1: Size of value to write (ARG4).
;   ARG2: Register Offset.
;   ARG3: BARIO# base I/O port
;   ARG4: Value to write.
; *--*--* The first 3 arguments are pushed in a single DWORD --> (ARG3<<16|ARG2<<8|ARG1).
;          This will be referenced in the driver specification as a ROO variable (Register, Offset, Opsize).
; NO OUTPUTS.
; -- Write a value of the specified size to the BARIO register specified, at the specified offset.
USB_UHCI_writeToBARIO:
    pushad
    mov ebp, esp
    xor ebx, ebx
    xor eax, eax        ; EAX = value to write
    xor edx, edx        ;  DX = Port to write to.

    mov strict byte bl, [ebp+36]    ;arg1
    mov strict word dx, [ebp+38]    ;arg3
    add strict byte dl, [ebp+37]    ;arg2 add offset to register.
    cmp byte bl, BYTE_OPERATION   ;byte
    je .byteWrite
    cmp byte bl, WORD_OPERATION   ;word
    je .wordWrite
    ;assume dword.
    mov dword eax, [ebp+40]
    out dx, eax
    jmp .leaveCall
  .byteWrite:
    mov strict byte al, [ebp+40]
    out dx, al
    jmp .leaveCall
  .wordWrite:
    mov strict word ax, [ebp+40]
    out dx, ax
    jmp .leaveCall

 .leaveCall:
    popad
    ret




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;SETUP FUNCTIONS.


; Find devices on the PCI bus(es) that match the class code of a UHCI.
USB_INTERNAL_findMatchingUHCI:
    pushad

    xor eax, eax
    mov al, UHCI_PCI_CONTROLLER_CLASS_ID
    shl eax, 8
    mov al, UHCI_PCI_CONTROLLER_SUBCLASS_ID
    shl eax, 8
    mov al, UHCI_PCI_CONTROLLER_INTERFACE_ID
    shl eax, 8
    ; Leave al = 0 (Revision does not matter right now).

    push dword eax
    call PCI_returnMatchingDevices  ; Get matching UHCI devices on the PCI bus.
    add esp, 4

    popad
    ret


; Set up the BARIO variables that will contain each USB controller's I/O port bases.
USB_INTERNAL_iterateUHCIBARs:
    pushad
    mov esi, PCI_MATCHED_DEVICE1
    mov edi, UHCI_BARIO_1   ; start at MATCHED_DEVICE1 & BARIO1
    xor ecx, ecx   ;set counter to 0
 .iterateBAR:
    xor eax, eax    ; returns for readConfigWord
    xor ebx, ebx    ; register access
    xor edx, edx    ; holds BAR
    cmp dword [esi], 0x00000000     ; check for empty PCI_MATCHED_DEVICE
    je .leaveCall  ; this line is the origin of a known possible bug. See top of this file.
    mov dword ebx, [esi]    ; ebx = (Bus<<24|Device<<16|Function<<8|00h)
    mov bl, PCI_BAR4    ; get IO-port addr (UHCI i/o addy is located on the PCI bus addr @BAR4)

    push dword ebx
    call PCI_configReadWord
    add esp, 4
    mov word dx, ax  ;now get the low word.

    ; EDX = [BAR4] of PCI_MATCHED_DEVICE[n]
    ; [BAR4] (I/O) format = bits 31-2 = 4-byte-aligned base addr, bits 1-0 = 01b
    ;  `---> so the BAR needs to be &0xFFFFFFFC to get the true base address.
    and dx, 0xFFFC
    mov word [edi], dx

    add edi, 2      ; next BARIO.
    add esi, 4      ; next MATCHED_DEVICE
    inc cl
    cmp byte cl, 8  ; were 8 devices filled? If so, leave before overflow!
    je .leaveCall
    jmp .iterateBAR

 .leaveCall:
    popad
    ret
