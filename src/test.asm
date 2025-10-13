section .data
    hello db "Hello from Clockman!",10,0

section .text
global _start

_start:
    ; Print hello message
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, hello      ; message
    mov rdx, 19         ; length
    syscall
    
    ; Exit
    mov rax, 60         ; sys_exit  
    mov rdi, 0          ; status
    syscall