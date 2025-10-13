section .data
    banner db "=== CLOCKMAN ALARM SYSTEM ===",10,0
    menu db "1=Add  2=List  3=Exit: ",0
    prompt db "Time (HHMM): ",0
    success db "Added!",10,0
    header db "Your alarms:",10,0
    empty db "No alarms set",10,0
    invalid db "Try again",10,0
    nl db 10,0

section .bss
    input resb 8
    alarms resb 100
    count resb 1

section .text
global _start

; Print fixed-length string
print_msg:
    mov rax, 1
    mov rdi, 1  
    ; rsi already has address
    ; rdx already has length
    syscall
    ret

; Print null-terminated string  
print_str:
    push rsi
    push rcx
    mov rcx, 0
.count:
    cmp byte [rsi + rcx], 0
    je .print
    inc rcx
    jmp .count
.print:
    mov rax, 1
    mov rdi, 1
    mov rdx, rcx
    syscall
    pop rcx
    pop rsi
    ret

; Read input
read_input:
    mov rax, 0
    mov rdi, 0
    mov rsi, input
    mov rdx, 8
    syscall
    ret

_start:
    mov byte [count], 0

.main:
    ; Print banner
    mov rsi, banner
    call print_str
    
    ; Print menu
    mov rsi, menu  
    call print_str
    
    ; Get choice
    call read_input
    
    ; Check choice
    cmp byte [input], '1'
    je .add
    cmp byte [input], '2'  
    je .list
    cmp byte [input], '3'
    je .exit
    
    ; Invalid
    mov rsi, invalid
    call print_str
    jmp .main

.add:
    ; Ask for time
    mov rsi, prompt
    call print_str
    
    ; Get time
    call read_input
    
    ; Store it (simple copy of 4 chars)
    movzx rax, byte [count]
    mov rbx, 4
    mul rbx  ; rax = offset
    
    mov cl, [input]
    mov [alarms + rax], cl
    mov cl, [input + 1]  
    mov [alarms + rax + 1], cl
    mov cl, [input + 2]
    mov [alarms + rax + 2], cl
    mov cl, [input + 3]
    mov [alarms + rax + 3], cl
    
    inc byte [count]
    
    mov rsi, success
    call print_str
    jmp .main

.list:
    movzx rcx, byte [count]
    test rcx, rcx
    jz .empty
    
    mov rsi, header
    call print_str
    
    xor rbx, rbx
.loop:
    cmp rbx, rcx
    jge .main
    
    ; Get alarm offset
    mov rax, rbx  
    mov rdx, 4
    mul rdx
    
    ; Copy to input buffer for printing
    mov dl, [alarms + rax]
    mov [input], dl
    mov dl, [alarms + rax + 1]
    mov [input + 1], dl
    mov dl, [alarms + rax + 2] 
    mov [input + 2], dl
    mov dl, [alarms + rax + 3]
    mov [input + 3], dl
    mov byte [input + 4], 0
    
    ; Print it
    mov rsi, input
    call print_str
    mov rsi, nl
    call print_str
    
    inc rbx
    jmp .loop
    
.empty:
    mov rsi, empty
    call print_str
    jmp .main
    
.exit:
    mov rax, 60
    xor rdi, rdi
    syscall