global main
extern printf
extern puts
section .rodata
    argc_fmt: db "argc: %d", 10, 0

section .text
main:
    push    ebp
    mov     ebp, esp
    sub     esp, 12

    mov     eax, [ebp + 8]   ; argc
    mov     [ebp - 4], eax
    mov     eax, [ebp + 12]  ; argv
    mov     [ebp - 8], eax

    push    dword [ebp - 4]
    push    dword argc_fmt
    call    printf
    add     esp, 8

    mov     dword [ebp - 12], 0  ; idx = 0

.print_loop:
    mov     ecx, [ebp - 12]
    cmp     ecx, [ebp - 4]
    jge     .done
    mov     eax, [ebp - 8]
    push    dword [eax + ecx * 4]
    call    puts
    add     esp, 4
    inc     dword [ebp - 12]
    jmp     .print_loop

.done:
    mov     eax, 0
    leave
    ret