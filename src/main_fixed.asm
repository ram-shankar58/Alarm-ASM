; ───────────────────────────────
; Clockman Alarm — Fixed Version
; Author: Ram Shankar (Clockman Edition)
; Description: Simple working alarm system in pure assembly
; ───────────────────────────────

section .data
menu:          db 10,"=== CLOCKMAN ALARM ===",10,"1) Add Alarm",10,"2) List Alarms",10,"3) Exit",10,"Choice: ",0
prompt:        db "Enter time (HHMM): ",0
added_msg:     db "Alarm added!",10,0
no_alarms:     db "No alarms set.",10,0
list_header:   db "Current alarms:",10,0
time_now_msg:  db "Current time: ",0
alarm_msg:     db "ALARM! Time reached!",10,0
invalid_msg:   db "Invalid choice!",10,0
newline:       db 10,0
colon:         db ":",0

section .bss
input:         resb 10
alarms:        resb 400     ; 100 alarms * 4 bytes each (HHMM)
alarm_count:   resb 1
current_time:  resb 5       ; HHMM format

section .text
global _start

; ───────────────────────────────
; Print string (rdi = string address)
; ───────────────────────────────
print:
    push rdi
    push rcx
    xor rcx, rcx
.count:
    cmp byte [rdi + rcx], 0
    je .print_it
    inc rcx
    jmp .count
.print_it:
    mov rax, 1        ; sys_write
    mov rdi, 1        ; stdout
    pop rcx
    pop rsi           ; string address
    mov rdx, rcx      ; length
    syscall
    ret

; ───────────────────────────────
; Read input
; ───────────────────────────────
read_input:
    mov rax, 0        ; sys_read
    mov rdi, 0        ; stdin
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
    ret

; ───────────────────────────────
; Convert 4-digit string to number (HHMM -> number)
; ───────────────────────────────
str_to_time:
    mov rsi, input
    xor rax, rax
    
    ; First digit (H)
    mov cl, [rsi]
    sub cl, '0'
    imul rax, rax, 10
    add rax, rcx
    
    ; Second digit (H)  
    mov cl, [rsi + 1]
    sub cl, '0'
    imul rax, rax, 10
    add rax, rcx
    
    ; Third digit (M)
    mov cl, [rsi + 2]
    sub cl, '0'
    imul rax, rax, 10
    add rax, rcx
    
    ; Fourth digit (M)
    mov cl, [rsi + 3]
    sub cl, '0'
    imul rax, rax, 10
    add rax, rcx
    
    ret

; ───────────────────────────────
; Get current time (returns HHMM format in rax)
; ───────────────────────────────
get_current_time:
    mov rax, 201      ; sys_time
    xor rdi, rdi
    syscall
    
    ; Convert timestamp to HHMM
    mov rbx, 86400    ; seconds per day
    xor rdx, rdx
    div rbx           ; rdx = seconds since midnight
    
    mov rax, rdx
    mov rbx, 3600     ; seconds per hour
    xor rdx, rdx
    div rbx           ; rax = hours, rdx = remaining seconds
    
    mov rcx, rax      ; save hours
    mov rax, rdx
    mov rbx, 60       ; seconds per minute  
    xor rdx, rdx
    div rbx           ; rax = minutes
    
    ; Format as HHMM
    imul rcx, rcx, 100
    add rax, rcx      ; rax = HHMM
    ret

; ───────────────────────────────
; Print number as HHMM format
; ───────────────────────────────
print_time:
    push rax
    
    ; Extract hours (first two digits)
    mov rbx, 100
    xor rdx, rdx
    div rbx           ; rax = hours, rdx = minutes
    
    push rdx          ; save minutes
    
    ; Print hours
    mov rbx, 10
    xor rdx, rdx
    div rbx           ; rax = first digit, rdx = second digit
    
    add rax, '0'
    mov [current_time], al
    add rdx, '0' 
    mov [current_time + 1], dl
    
    pop rdx           ; restore minutes
    mov rax, rdx
    
    ; Print minutes
    mov rbx, 10
    xor rdx, rdx
    div rbx           ; rax = first digit, rdx = second digit
    
    add rax, '0'
    mov [current_time + 2], al
    add rdx, '0'
    mov [current_time + 3], dl
    mov byte [current_time + 4], 0
    
    lea rdi, [current_time]
    call print
    
    pop rax
    ret

; ───────────────────────────────
; Add alarm
; ───────────────────────────────
add_alarm:
    lea rdi, [prompt]
    call print
    call read_input
    
    call str_to_time
    
    ; Store alarm
    movzx rbx, byte [alarm_count]
    mov [alarms + rbx * 4], eax
    inc byte [alarm_count]
    
    lea rdi, [added_msg]
    call print
    ret

; ───────────────────────────────
; List alarms
; ───────────────────────────────
list_alarms:
    movzx rcx, byte [alarm_count]
    cmp rcx, 0
    je .no_alarms
    
    lea rdi, [list_header]
    call print
    
    xor rbx, rbx
.print_loop:
    cmp rbx, rcx
    jge .done
    
    mov eax, [alarms + rbx * 4]
    call print_time
    lea rdi, [newline]
    call print
    
    inc rbx
    jmp .print_loop
    
.done:
    ret
    
.no_alarms:
    lea rdi, [no_alarms]
    call print
    ret

; ───────────────────────────────
; Check alarms (background process)
; ───────────────────────────────
check_alarms:
.loop:
    call get_current_time
    mov r8, rax       ; current time
    
    movzx rcx, byte [alarm_count]
    cmp rcx, 0
    je .sleep
    
    xor rbx, rbx
.check_loop:
    cmp rbx, rcx
    jge .sleep
    
    mov eax, [alarms + rbx * 4]
    cmp eax, r8d
    je .alarm_triggered
    
    inc rbx
    jmp .check_loop
    
.alarm_triggered:
    ; Fork and run notify-send
    mov rax, 57       ; sys_fork
    syscall
    test rax, rax
    jnz .continue     ; parent continues
    
    ; Child process - exec notify-send
    mov rax, 59       ; sys_execve
    lea rdi, [notify_cmd]
    lea rsi, [notify_args]
    xor rdx, rdx
    syscall
    
    ; If exec fails, exit
    mov rax, 60
    mov rdi, 1
    syscall
    
.continue:
    inc rbx
    jmp .check_loop

.sleep:
    ; Sleep for 60 seconds
    mov rax, 35       ; sys_nanosleep
    lea rdi, [sleep_time]
    xor rsi, rsi
    syscall
    jmp .loop

; ───────────────────────────────
; MAIN
; ───────────────────────────────
_start:
    ; Fork background alarm checker
    mov rax, 57       ; sys_fork
    syscall
    test rax, rax
    jz check_alarms   ; child becomes alarm checker
    
    ; Parent - main menu loop
.menu_loop:
    lea rdi, [menu]
    call print
    call read_input
    
    mov al, [input]
    cmp al, '1'
    je .add
    cmp al, '2' 
    je .list
    cmp al, '3'
    je .exit
    
    lea rdi, [invalid_msg]
    call print
    jmp .menu_loop
    
.add:
    call add_alarm
    jmp .menu_loop
    
.list:
    call list_alarms
    jmp .menu_loop
    
.exit:
    mov rax, 60       ; sys_exit
    xor rdi, rdi
    syscall

section .data
notify_cmd:    db "/usr/bin/notify-send",0
notify_title:  db "⏰ CLOCKMAN ALARM",0
notify_text:   db "Alarm time reached!",0
notify_args:   dq notify_cmd, notify_title, notify_text, 0

sleep_time:    dq 60, 0      ; 60 seconds, 0 nanoseconds