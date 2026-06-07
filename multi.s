section .data
    ;global variables for part 3
    align 2
    lfsr_state: dw 0xACE1  
    lfsr_mask:  dw 0xB400

    byte_fmt: db "%02hhx", 0
    byte_nopad_fmt: db "%x", 0
    nl_fmt: db 10, 0

    x_struct: db 5
    x_num:    db 0xaa, 1, 2, 0x44, 0x4f
    
    y_struct: db 6
    y_num:    db 0xaa, 1, 2, 3, 0x44, 0x4f

section .bss
    inbuf: resb 502

section .text
    global main
    global get_max_min
    global add_multi
    global getmulti
    global print_multi
    global rand_num
    global PRmulti
    
    extern malloc
    extern fgets
    extern stdin
    extern printf
    extern free


main:
    push    ebp
    mov     ebp, esp
    push    ebx
    push    esi
    push    edi

    mov     ecx, [ebp + 8]   ; ecx = argc
    mov     edx, [ebp + 12]  ; edx = argv

    ;check if there are no command line arguments
    cmp     ecx, 1
    je      .run_default

    ;check if argv[1] exists and check the flag
    mov     eax, [edx + 4]   ; eax = argv[1]
    movzx   ebx, byte [eax]
    cmp     bl, '-'          ;make sure it starts with a '-'
    jne     .run_default
    
    movzx   ebx, byte [eax + 1]
    cmp     bl, 'I'
    je      .run_stdin
    cmp      bl, 'i'
    je       .run_stdin
    cmp     bl, 'R'
    je      .run_random
    cmp     bl, 'r'
    je      .run_random

.run_default:
    ;print x
    push    x_struct
    call    print_multi
    add     esp, 4

    ;print y
    push    y_struct
    call    print_multi
    add     esp, 4

    ;add x+y
    push    y_struct
    push    x_struct
    call    add_multi
    add     esp, 8
    
    ;print calculation result
    mov     ebx, eax
    push    eax
    call    print_multi
    push    ebx
    call    free
    add     esp, 4
    jmp     .exit

.run_stdin:
    ;read first multi-precision integer from stdin and save pointer
    call    getmulti       
    mov     esi, eax
    
    ;read second multi-precision integer from stdin and save pointer
    call    getmulti       
    mov     edi, eax

    ;print both structs
    push    esi
    call    print_multi
    add     esp, 4

    push    edi
    call    print_multi
    add     esp, 4

    ;add struct 1 + struct 2
    push    edi
    push    esi
    call    add_multi
    add     esp, 8
    mov     ebx, eax         ;save the pointer to calculation result struct

    ;print calculation result
    push    ebx
    call    print_multi
    add     esp, 4

    push    esi
    call    free
    add     esp, 4

    push    edi
    call    free
    add     esp, 4

    push    ebx
    call    free
    add     esp, 4
    jmp     .exit

.run_random:
    ;generate random multi-precision struct 1
    call    PRmulti
    mov     esi, eax
    
    ;generate random multi-precision struct 2
    call    PRmulti
    mov     edi, eax

    ;print random struct 1
    push    esi
    call    print_multi
    add     esp, 4

    ;print random struct 2
    push    edi
    call    print_multi
    add     esp, 4

    ;add them together
    push    edi
    push    esi
    call    add_multi
    add     esp, 8
    mov     ebx, eax         ;save computation result address

    ;print sum output
    push    ebx
    call    print_multi
    add     esp, 4

    push    esi
    call    free
    add     esp, 4

    push    edi
    call    free
    add     esp, 4

    push    ebx
    call    free
    add     esp, 4

.exit:
    mov     eax, 0
    pop     edi
    pop     esi
    pop     ebx
    mov     esp, ebp
    pop     ebp
    ret


;part 1a - print struct multi in hexadecimal

print_multi:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    mov esi, [ebp + 8]
    movzx ebx, byte [esi]        ; total number of bytes
    lea edi, [esi + ebx]         ; edi = pointer to MSB byte

.trim_leading_zero_bytes:
    cmp ebx, 1
    jbe .print_first
    cmp byte [edi], 0
    jne .print_first
    dec edi
    dec ebx
    jmp .trim_leading_zero_bytes

.print_first:
    movzx eax, byte [edi]
    push eax
    push dword byte_nopad_fmt
    call printf
    add esp, 8

    dec edi
    dec ebx
    jz .print_nl

.print_loop:
    cmp ebx, 0
    je .print_nl

    movzx eax, byte [edi]
    push eax
    push dword byte_fmt
    call printf
    add esp, 8

    dec edi
    dec ebx
    jmp .print_loop

.print_nl:
    push dword nl_fmt
    call printf
    add esp, 4

    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret


;part 1b - read hex string from stdin and store as struct multi

getmulti:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    push dword [stdin]
    push dword 502
    push dword inbuf
    call fgets
    add esp, 12
    test eax, eax
    jz .fail

    ; count hex digits until '\n' or '\0'
    xor ecx, ecx
.len_loop:
    mov al, [inbuf + ecx]
    cmp al, 0
    je .len_done
    cmp al, 10
    je .len_done
    inc ecx
    jmp .len_loop

.len_done:
    ; if odd number of digits, prepend one '0' to make it even
    test ecx, 1
    jz .have_even

    mov edx, ecx
.shift_right:
    cmp edx, 0
    je .insert_zero
    mov al, [inbuf + edx - 1]
    mov [inbuf + edx], al
    dec edx
    jmp .shift_right

.insert_zero:
    mov byte [inbuf], '0'
    inc ecx

.have_even:
    mov edi, ecx
    mov eax, ecx
    shr eax, 1
    mov esi, eax                 ; size in bytes

    inc eax                      ; +1 for struct size field
    push eax
    call malloc
    add esp, 4
    test eax, eax
    jz .fail

    mov ebx, eax                 ; result pointer
    mov edx, esi
    mov [ebx], dl

    xor ecx, ecx                 ; byte index
    lea edx, [inbuf + edi - 1]   ; points at last hex digit

.pair_loop:
    cmp ecx, esi
    jge .ok

    mov al, [edx - 1]            ; high nibble char
    call .hex_to_nibble
    shl al, 4
    mov ah, al

    mov al, [edx]                ; low nibble char
    call .hex_to_nibble
    or al, ah

    mov [ebx + 1 + ecx], al
    inc ecx
    sub edx, 2
    jmp .pair_loop

.ok:
    mov eax, ebx
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

.fail:
    xor eax, eax
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

.hex_to_nibble:
    cmp al, '9'
    jbe .digit
    and al, 0xDF
    sub al, 'A'
    add al, 10
    ret
.digit:
    sub al, '0'
    ret


;part 2a - sorting by struct size

get_max_min:
    movzx ecx, byte [eax]    ; ecx = struct1->size 
    movzx edx, byte [ebx]    ; edx = struct2->size

    cmp ecx, edx
    jae .ordered             ; if struct1 >= struct2, they are already in order
    xchg eax, ebx            ; if not, swap them so EAX is always larger
.ordered:
    ret


;part 2b - adding two structs together byte by byte

add_multi:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    sub esp, 12

    mov eax, [ebp + 8]     ;eax = pointer to struct p
    mov ebx, [ebp + 12]    ;ebx = pointer to struct q

    ;sorting by size
    call get_max_min
    mov esi, eax             ;esi = max_struct
    mov edi, ebx             ;edi = min_struct

    movzx ecx, byte [esi]    ; ecx = max_len
    movzx edx, byte [edi]    ; edx = min_len
    mov [ebp - 20], edx      ; save min_len
    mov eax, ecx
    sub eax, edx
    mov [ebp - 16], eax      ; remaining bytes from max after overlap

    ;size to allocate = max_len + 1, unless max_len is already 255
    cmp ecx, 255
    je .have_result_len
    inc ecx

.have_result_len:
    mov [ebp - 24], ecx      ; save result array length (without struct header)
    mov eax, ecx
    inc eax                  ; +1 extra byte for the size field
    push eax
    call malloc
    add esp, 4
    
    mov ebx, eax             ; ebx = pointer to newly allocated struct
    mov ecx, [ebp - 24]
    mov [ebx], cl            ; result_struct->size = size of the internal number array

    xor eax, eax      ;array index i = 0
    clc               ;clear carry flag

    mov ecx, [ebp - 20]      ; min_len loop counter
    jecxz .setup_max_loop

.add_min_loop:
    mov dl, [esi + 1 + eax]  ;load byte from max_struct (offset 1 skips for 'size')
    adc dl, [edi + 1 + eax]  ;add byte from min_struct + carry flag
    mov [ebx + 1 + eax], dl  ;store in result_struct

    inc eax
    dec ecx
    jnz .add_min_loop

.setup_max_loop:
    mov ecx, [ebp - 16]
    jecxz .finalize_carry

.add_max_loop:
    mov dl, [esi + 1 + eax]
    adc dl, 0
    mov [ebx + 1 + eax], dl

    inc eax
    dec ecx
    jnz .add_max_loop

.finalize_carry:
    setc dl                  ;save carry before any flag-clobbering instruction

    ;checking if we have room to store the final carry byte (size < 255 case)
    movzx ecx, byte [ebx]
    cmp eax, ecx
    jge .add_complete

    mov [ebx + 1 + eax], dl

.add_complete:
    mov eax, ebx       ;return the pointer to the new allocated struct in eax
    add esp, 12
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret


;part 3 - pseudo-random number generator

rand_num:
    push ebp
    mov ebp, esp
    push ebx

    mov ax, [lfsr_state]
    mov bx, [lfsr_mask]

    and bx, ax
    
    ;xor top byte with bottom byte to find bit parity
    mov cx, bx
    shr cx, 8
    xor cl, bl
    jp .parity_even
    mov cx, 1           ; odd parity - feedback bit is 1
    jmp .shift
.parity_even:
    mov cx, 0          ; even parity - feedback bit is 0

.shift:
    shl cx, 15            ;move the feedback bit to MSB position
    shr ax, 1                ;shift running state right by 1
    or ax, cx
    mov [lfsr_state], ax     ;save new LFSR state
    
    pop ebx
    mov esp, ebp
    pop ebp
    ret

PRmulti:
    push ebp
    mov ebp, esp
    push ebx
    push esi

.get_valid_len:
    call rand_num
    and al, 0xFF             ;keep lower 8 bits for size length
    cmp al, 0
    je .get_valid_len        ;if length is 0, fetch a new random byte instead
    
    movzx esi, al            ;esi = length 'n' in bytes
    mov dl, al               ;save 8-bit length for header write

    lea eax, [esi + 1]
    push edx
    push eax
    call malloc
    add esp, 4
    pop edx
    mov ebx, eax            ;ebx = allocated random struct
    mov [ebx], dl

    xor ecx, ecx             ;byte tracker index = 0
.fill_random_loop:
    cmp ecx, esi
    jge .fill_done

    push ecx 
    call rand_num
    pop ecx

    mov [ebx + 1 + ecx], al  ;store random byte into data payload
    inc ecx
    jmp .fill_random_loop

.fill_done:
    mov eax, ebx             ;return completed random struct pointer
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret