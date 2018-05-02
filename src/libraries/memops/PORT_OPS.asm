; PORT_OPS.asm
; -- A collection of centralized port I/O functions.

; ALL PORT OUTPUT FUNCTIONS:
; BOTH INPUT ARGS ARE DWORD SIZE
;   ARG1 = Port number (0x0000FFFF & WORD_PORT)
;   ARG2 = Data to output (Size depends on function)
PORT_OUT_BYTE:
    push ebp
    mov ebp, esp
    push edx
    push eax

    mov edx, dword [ebp+8]
    mov eax, dword [ebp+12]
    and edx, 0x0000FFFF
    and eax, 0x000000FF
    out dx, al

 .leaveCall:
    pop eax
    pop edx
    pop ebp
    ret


PORT_OUT_WORD:
    push ebp
    mov ebp, esp
    push edx
    push eax

    mov edx, dword [ebp+8]
    mov eax, dword [ebp+12]
    and edx, 0x0000FFFF
    and eax, 0x0000FFFF
    out dx, ax

 .leaveCall:
    pop eax
    pop edx
    pop ebp
    ret


PORT_OUT_DWORD:
    push ebp
    mov ebp, esp
    push edx
    push eax

    mov edx, dword [ebp+8]
    mov eax, dword [ebp+12]
    and edx, 0x0000FFFF
    out dx, eax

 .leaveCall:
    pop eax
    pop edx
    pop ebp
    ret


; PORT READING FUNCTIONS:
; ARGUMENT IS A DWORD (0x0000FFFF & WORD_PORT)
;   ARG1 = Port Number to read from.
; RESULT IS RETURNED IN THE EAX REGISTER ACCORDING TO THE SIZE REQUEST.
PORT_IN_BYTE:
    push ebp
    mov ebp, esp
    push edx

    mov edx, dword [ebp+8]
    and edx, 0x0000FFFF

    in al, dx

 .leaveCall:
    pop edx
    pop ebp
    ret


PORT_IN_WORD:
    push ebp
    mov ebp, esp
    push edx

    mov edx, dword [ebp+8]
    and edx, 0x0000FFFF

    in ax, dx

 .leaveCall:
    pop edx
    pop ebp
    ret


PORT_IN_DWORD:
    push ebp
    mov ebp, esp
    push edx

    mov edx, dword [ebp+8]
    and edx, 0x0000FFFF

    in eax, dx

 .leaveCall:
    pop edx
    pop ebp
    ret
