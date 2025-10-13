section .data
    menu db "=== CLOCKMAN ===",10,"1. Add alarm",10,"2. List alarms",10,"3. Exit",10,"Choice: ",0
    prompt db "Enter time (HHMM): ",0
    added db "Alarm added!",10,0
    no_alarms db "No alarms.",10,0
    list_header db "Alarms:",10,0
    invalid db "Invalid!",10,0
    newline db 10,0

section .bss
    input resb 10
    alarms resb 400
    count resb 1

section .text
global _start

print:
    push rbp
    mov rbp, rsp
    push rdi
    push rcx
    xor rcx, rcx
.count_loop:
    cmp byte [rdi + rcx], 0
    je .print_now
    inc rcx
    jmp .count_loop
.print_now:
    mov rax, 1
    mov rdi, 1
    pop rsi
    mov rdx, rcx
    syscall
    pop rcx
    pop rbp
    ret

read_input:
    push rbp
    mov rbp, rsp
    mov rax, 0
    mov rdi, 0
    mov rsi, input
    mov rdx, 10
    syscall
    
    ; Remove newline
    mov rcx, 0
.remove_nl:
    cmp byte [input + rcx], 10
    je .found_nl
    cmp byte [input + rcx], 0
    je .done
    inc rcx
    jmp .remove_nl
.found_nl:
    mov byte [input + rcx], 0
.done:
    pop rbp
    ret

add_alarm:
    push rbp
    mov rbp, rsp
    
    mov rdi, prompt
    call print
    call read_input
    
    ; Simple store - just copy the 4 digits
    movzx rax, byte [count]
    mov rcx, rax
    imul rcx, 4
    
    mov al, [input]
    mov [alarms + rcx], al
    mov al, [input + 1]  
    mov [alarms + rcx + 1], al
    mov al, [input + 2]
    mov [alarms + rcx + 2], al
    mov al, [input + 3]
    mov [alarms + rcx + 3], al
    
    inc byte [count]
    
    mov rdi, added
    call print
    
    pop rbp
    ret

list_alarms:
    push rbp
    mov rbp, rsp
    
    movzx rax, byte [count]
    cmp rax, 0
    je .no_alarms_found
    
    mov rdi, list_header
    call print
    
    xor rbx, rbx
.print_loop:
    cmp rbx, rax
    jge .done
    
    mov rcx, rbx
    imul rcx, 4
    
    ; Print the 4 characters
    mov dl, [alarms + rcx]
    mov [input], dl
    mov dl, [alarms + rcx + 1]
    mov [input + 1], dl
    mov dl, [alarms + rcx + 2]
    mov [input + 2], dl
    mov dl, [alarms + rcx + 3]
    mov [input + 3], dl
    mov byte [input + 4], 0
    
    mov rdi, input
    call print
    mov rdi, newline
    call print
    
    inc rbx
    jmp .print_loop
    
.done:
    pop rbp
    ret
    
.no_alarms_found:
    mov rdi, no_alarms
    call print
    pop rbp
    ret

_start:
.main_loop:
    mov rdi, menu
    call print
    call read_input
    
    mov al, [input]
    cmp al, '1'
    je .add
    cmp al, '2'
    je .list
    cmp al, '3'
    je .exit
    
    mov rdi, invalid
    call print
    jmp .main_loop
    
.add:
    call add_alarm
    jmp .main_loop
    
.list:
    call list_alarms
    jmp .main_loop
    
.exit:
    mov rax, 60
    xor rdi, rdi
    syscall