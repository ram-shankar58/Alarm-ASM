; Ultra-simple clockman that actually works
section .data
    msg1 db "CLOCKMAN - Basic Alarm Manager",10,0
    msg2 db "1=Add 2=List 3=Exit: ",0  
    msg3 db "Time (4 digits): ",0
    msg4 db "Added!",10,0
    msg5 db "Alarms:",10,0
    msg6 db "None",10,0
    msg7 db "Invalid",10,0
    newline db 10,0

section .bss
    buffer resb 16
    alarms resb 400
    count resb 1

section .text
global _start

strlen:
    xor rax, rax
.loop:
    cmp byte [rdi + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    ret

print:
    call strlen
    mov rdx, rax
    mov rax, 1
    mov rdi, 1
    syscall
    ret

read:
    mov rax, 0
    mov rdi, 0
    mov rsi, buffer
    mov rdx, 16
    syscall
    ret

_start:
    mov byte [count], 0

main_loop:
    mov rsi, msg1
    call print
    
    mov rsi, msg2  
    call print
    
    call read
    
    mov al, [buffer]
    cmp al, '1'
    je add_alarm
    cmp al, '2'
    je list_alarms  
    cmp al, '3'
    je exit_prog
    
    mov rsi, msg7
    call print
    jmp main_loop

add_alarm:
    mov rsi, msg3
    call print
    
    call read
    
    ; Store alarm
    movzx rax, byte [count]
    mov rbx, 4
    mul rbx
    
    mov cl, [buffer]
    mov [alarms + rax], cl
    mov cl, [buffer + 1]
    mov [alarms + rax + 1], cl  
    mov cl, [buffer + 2]
    mov [alarms + rax + 2], cl
    mov cl, [buffer + 3]
    mov [alarms + rax + 3], cl
    
    inc byte [count]
    
    mov rsi, msg4
    call print
    jmp main_loop

list_alarms:
    movzx rcx, byte [count]
    cmp rcx, 0
    je no_alarms
    
    mov rsi, msg5
    call print
    
    xor rbx, rbx
print_loop:
    cmp rbx, rcx
    jge main_loop
    
    mov rax, rbx
    mov rdx, 4
    mul rdx
    
    ; Print 4 chars
    mov dl, [alarms + rax]
    mov [buffer], dl
    mov dl, [alarms + rax + 1]  
    mov [buffer + 1], dl
    mov dl, [alarms + rax + 2]
    mov [buffer + 2], dl
    mov dl, [alarms + rax + 3]
    mov [buffer + 3], dl
    mov byte [buffer + 4], 0
    
    mov rsi, buffer
    call print
    mov rsi, newline
    call print
    
    inc rbx
    jmp print_loop

no_alarms:
    mov rsi, msg6
    call print
    jmp main_loop
    
exit_prog:
    mov rax, 60
    xor rdi, rdi
    syscall