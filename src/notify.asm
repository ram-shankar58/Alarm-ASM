; notify.asm - wrapper for notify-send
section .text
global notify_task

notify_task:
    ; rdi = pointer to task string
    lea rsi, [rel args]
    mov rax, 59       ; sys_execve
    lea rdi, [rel cmd] ; "/usr/bin/notify-send"
    xor rdx, rdx
    syscall
    ret

section .data
cmd db "/usr/bin/notify-send",0
args: dq cmd,0
