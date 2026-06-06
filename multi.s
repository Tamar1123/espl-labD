section .data
    ;global variables for part 3
    align 2
    lfsr_state: dw 0xACE1  
    lfsr_mask:  dw 0xB400

section .text
    global get_max_min
    global add_multi
    global rand_num
    global PRmulti
    
    extern malloc


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

    mov eax, [ebp + 8]     ;eax = pointer to struct p
    mov ebx, [ebp + 12]    ;ebx = pointer to struct q

    ;sorting by size
    call get_max_min
    mov esi, eax             ;esi = max_struct
    mov edi, ebx             ;edi = min_struct

    movzx ecx, byte [esi]    ; ecx = max_len
    movzx edx, byte [edi]    ; edx = min_len

    ;size to allocate = max_len + 1
    mov eax, ecx
    cmp eax, 255   ;255 = max_len limit
    je .allocate
    inc eax                

.allocate:
    mov edx, eax             
    inc eax             ;+1 extra byte for the size field
    push edx                 
    push eax                 
    call malloc              
    add esp, 4
    pop edx                  
    
    mov ebx, eax             ; ebx = pointer to newly allocated struct
    mov [ebx], dl            ; result_struct->size = size of the internal number array

    ;bounds for addition loops
    movzx ecx, byte [esi]    ;max_len
    movzx edx, byte [edi]    ;min_len
    
    xor eax, eax      ;array index i = 0
    clc               ;clear carry flag

.add_min_loop:
    cmp eax, edx
    je .add_max_loop         ;when done adding overlapping bytes, go to remaining bytes

    mov cl, [esi + 1 + eax]  ;load byte from max_struct (offset 1 skips for 'size')
    adc cl, [edi + 1 + eax]  ;add byte from min_struct + carry flag
    mov [ebx + 1 + eax], cl  ;store in result_struct

    inc eax
    jmp .add_min_loop

.add_max_loop:
    movzx ecx, byte [esi]
    cmp eax, ecx
    je .finalize_carry       ;if we reached the end of max_len handle final overflow

    mov cl, [esi + 1 + eax]
    adc cl, 0 
    mov [ebx + 1 + eax], cl

    inc eax
    jmp .add_max_loop

.finalize_carry:
    ;checking if we have room to store the final carry bit (if size < 255)
    movzx ecx, byte [ebx]
    cmp eax, ecx
    jge .add_complete

    mov cl, 0
    adc cl, 0                ;capture final carry bit
    mov [ebx + 1 + eax], cl

.add_complete:
    mov eax, ebx       ;return the pointer to the new allocated struct in eax
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

    lea eax, [esi + 1]
    push eax
    call malloc
    add esp, 4
    mov ebx, eax            ;ebx = allocated random struct
    mov [ebx], sil

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