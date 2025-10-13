; ───────────────────────────────
; Clockman Alarm — Complete NASM x86_64
; Author: Ram Shankar (Clockman Edition)
; Description:
;   Add alarms (HH MM Task)
;   Check system time every minute
;   Notify when alarm time matches
; Requirements:
;   - libnotify (for notify-send)
;   - 64-bit Linux
; ───────────────────────────────

section .data
menu:          db 10,"1:Add Alarm  2:List Alarms  3:Remove Alarm  4:Exit",10,0
prompt:        db "Enter alarm: HH MM Task (e.g., 14 30 Take a break):",10,0
added_msg:     db "Alarm added successfully!",10,0
no_alarms:     db "No alarms stored yet.",10,0
list_header:   db 10,"Stored Alarms:",10,0
removed_msg:   db "Alarm removed successfully!",10,0
invalid_opt:   db "Invalid option!",10,0
check_msg:     db "[Clockman] Checking alarms...",10,0
newline:       db 10,0

cmd_notify:    db "/usr/bin/notify-send",0
arg_title:     db "⏰ Clockman Alarm!",0
arg_msg:       db "Alarm time reached!",0

section .bss
input:         resb 256
alarm_hours:   resb 100
alarm_mins:    resb 100
alarm_tasks:   resb 1000
alarm_count:   resb 1
sys_time:      resb 16

section .text
global _start

; ───────────────────────────────
; Helper: print string (rdi=addr)
; ───────────────────────────────
; ───────────────────────────────
; Helper: print string (rdi=addr)
; ───────────────────────────────
print:
    push rdi
    xor rcx, rcx
.find_len:
    cmp byte [rdi + rcx], 0
    je .len_found
    inc rcx
    jmp .find_len
.len_found:
    mov rax, 1
    mov rdi, 1
    pop rsi            ; restore string pointer
    mov rdx, rcx
    syscall
    ret


; ───────────────────────────────
; Helper: read line into `input`
; ───────────────────────────────
read_line:
    mov rax, 0
    mov rdi, 0
    mov rsi, input
    mov rdx, 255
    syscall
    ret

; ───────────────────────────────
; Helper: atoi — converts ASCII digits to int
; input: rdi -> ascii buffer, output: eax
; ───────────────────────────────
atoi:
    xor rax, rax
    xor rcx, rcx
.next:
    mov bl, [rdi+rcx]
    cmp bl, '0'
    jb .done
    cmp bl, '9'
    ja .done
    imul eax, eax, 10
    sub bl, '0'
    add eax, ebx
    inc rcx
    jmp .next
.done:
    ret

; ───────────────────────────────
; Helper: call notify-send
; ───────────────────────────────
notify_alarm:
    mov rax, 59
    lea rdi, [rel cmd_notify]
    lea rsi, [rel arg_title]
    lea rdx, [rel arg_msg]
    syscall
    ret

; ───────────────────────────────
; Helper: get system time (strftime-like)
; returns HH and MM as integers
; ───────────────────────────────
get_time:
    mov rax, 201     ; syscall: time
    xor rdi, rdi
    syscall

    mov rdi, rax
    mov rax, 231     ; localtime
    syscall

    mov rsi, rax
    movzx eax, word [rsi+8]    ; tm_hour
    movzx ebx, word [rsi+10]   ; tm_min
    ret

; ───────────────────────────────
; Add Alarm
; ───────────────────────────────
add_alarm:
    mov rdi, prompt
    call print
    call read_line

    mov rsi, input
    mov rdi, rsi
    call atoi
    mov bl, [alarm_count]
    mov [alarm_hours + rbx], al

    add rsi, 3
    mov rdi, rsi
    call atoi
    mov [alarm_mins + rbx], al

    add byte [alarm_count], 1
    mov rdi, added_msg
    call print
    ret

; ───────────────────────────────
; List Alarms
; ───────────────────────────────
list_alarms:
    mov al, [alarm_count]
    cmp al, 0
    je .none
    mov rdi, list_header
    call print
    ret
.none:
    mov rdi, no_alarms
    call print
    ret

; ───────────────────────────────
; Remove Alarm
; ───────────────────────────────
remove_alarm:
    mov al, [alarm_count]
    cmp al, 0
    je .none
    dec byte [alarm_count]
    mov rdi, removed_msg
    call print
    ret
.none:
    mov rdi, no_alarms
    call print
    ret

; ───────────────────────────────
; Check alarms every minute
; ───────────────────────────────
check_alarms:
.loop:
    call get_time
    mov cl, al     ; hour
    mov ch, bl     ; minute

    mov dl, [alarm_count]
    cmp dl, 0
    je .sleep

    xor rsi, rsi
.next_alarm:
    cmp rsi, rdx
    jge .sleep
    mov al, [alarm_hours + rsi]
    mov bl, [alarm_mins + rsi]
    cmp al, cl
    jne .cont
    cmp bl, ch
    jne .cont
    call notify_alarm
.cont:
    inc rsi
    jmp .next_alarm

.sleep:
    mov rax, 35    ; nanosleep
    mov rdi, 60     ; 60 seconds
    syscall
    jmp .loop

; ───────────────────────────────
; MAIN LOOP
; ───────────────────────────────
; ───────────────────────────────
; MAIN LOOP
; ───────────────────────────────
_start:
menu_loop:
    mov rdi, menu
    call print
    call read_line

    mov al, [input]
    cmp al, '1'
    je .add
    cmp al, '2'
    je .list
    cmp al, '3'
    je .remove
    cmp al, '4'
    je exit_program

    mov rdi, invalid_opt
    call print
    jmp menu_loop

.add:
    call add_alarm
    jmp menu_loop

.list:
    call list_alarms
    jmp menu_loop

.remove:
    call remove_alarm
    jmp menu_loop

exit_program:
    mov rax, 60
    xor rdi, rdi
    syscall
