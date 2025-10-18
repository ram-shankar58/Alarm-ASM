; --------------------------------------------------------
; Pure Assembly Notification (Wayland/Hyprland Safe)
; Uses notify-send and inherits environment
; --------------------------------------------------------

section .data
    path db "/usr/bin/notify-send", 0
    arg0 db "notify-send", 0
    arg1 db "Assembly Notification", 0
    arg2 db "Hello from pure assembly under Hyprland!", 0
    args dq arg0, arg1, arg2, 0       ; argv = [notify-send, title, body, NULL]

section .text
    global _start

_start:
    ; Save stack pointer (we’ll walk it to find envp)
    mov rbx, rsp

    ; fork()
    mov rax, 57
    syscall
    test rax, rax
    jnz .parent

.child:
    ; Extract envp from stack manually
    mov rsi, [rbx]       ; argc
    inc rbx
    lea rbx, [rsp + 8]   ; point after argc
.find_envp:
    mov rax, [rbx]
    add rbx, 8
    test rax, rax
    jnz .find_envp       ; skip argv pointers
    mov rdx, rbx         ; envp starts here

    ; execve("/usr/bin/notify-send", argv, envp)
    mov rax, 59
    lea rdi, [rel path]
    lea rsi, [rel args]
    syscall

    ; if execve fails
    mov rax, 60
    mov rdi, 1
    syscall

.parent:
    ; wait4(-1, NULL, 0, NULL)
    mov rax, 61
    mov rdi, -1
    xor rsi, rsi
    xor rdx, rdx
    xor r10, r10
    syscall

    ; exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall
