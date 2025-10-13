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
arg_msg:       db "Time to wake up!",0

; argv array for execve
notify_argv:   dq cmd_notify, arg_title, arg_msg, 0

; timespec for nanosleep (60 seconds)
sleep_spec:    dq 60, 0    ; 60 seconds, 0 nanoseconds
colon_space:   db ": ",0
temp_char:     times 10 db 0

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
    
    ; Remove newline character
    mov rcx, 0
.find_newline:
    cmp byte [input + rcx], 10  ; newline
    je .remove_newline
    cmp byte [input + rcx], 0
    je .done
    inc rcx
    jmp .find_newline
.remove_newline:
    mov byte [input + rcx], 0   ; replace newline with null
.done:
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
; Helper: print number (rdi = number)
; ───────────────────────────────
print_number:
    cmp rdi, 10
    jb .single_digit
    
    ; Two digit number
    mov rax, rdi
    mov rbx, 10
    xor rdx, rdx
    div rbx
    
    add rax, '0'
    mov [temp_char], al
    add rdx, '0'  
    mov [temp_char+1], dl
    mov byte [temp_char+2], 0
    lea rdi, [temp_char]
    call print
    ret
    
.single_digit:
    add rdi, '0'
    mov [temp_char], dil
    mov byte [temp_char+1], 0
    lea rdi, [temp_char]
    call print
    ret

; ───────────────────────────────
; Helper: call notify-send
; ───────────────────────────────
notify_alarm:
    ; Fork first
    mov rax, 57      ; sys_fork
    syscall
    test rax, rax
    jz .child        ; if child process
    ret              ; parent process returns

.child:
    ; Setup arguments for execve
    ; argv[0] = "/usr/bin/notify-send"
    ; argv[1] = "⏰ Clockman Alarm!"  
    ; argv[2] = "Time to wake up!"
    ; argv[3] = NULL
    
    mov rax, 59      ; sys_execve
    lea rdi, [rel cmd_notify]     ; program path
    lea rsi, [rel notify_argv]    ; argv array
    xor rdx, rdx                  ; envp = NULL
    syscall
    
    ; If execve fails, exit child
    mov rax, 60      ; sys_exit
    mov rdi, 1       ; exit code 1
    syscall

; ───────────────────────────────
; Helper: get system time 
; returns HH in eax and MM in ebx
; ───────────────────────────────
get_time:
    mov rax, 201     ; syscall: time
    xor rdi, rdi
    syscall
    
    ; rax now contains seconds since epoch
    ; Convert to local time (assuming UTC+0 for simplicity)
    ; To get hours/minutes: (seconds % 86400) / 3600 = hours
    ; ((seconds % 86400) % 3600) / 60 = minutes
    
    mov rbx, 86400   ; seconds in a day
    xor rdx, rdx
    div rbx          ; rdx = seconds since midnight
    
    mov rax, rdx     ; seconds since midnight
    mov rbx, 3600    ; seconds in an hour
    xor rdx, rdx
    div rbx          ; rax = hours, rdx = remaining seconds
    
    mov rcx, rax     ; save hours in rcx
    mov rax, rdx     ; remaining seconds
    mov rbx, 60      ; seconds in a minute
    xor rdx, rdx
    div rbx          ; rax = minutes, rdx = seconds
    
    mov ebx, eax     ; minutes in ebx
    mov eax, ecx     ; hours in eax
    ret

; ───────────────────────────────
; Add Alarm
; ───────────────────────────────
add_alarm:
    mov rdi, prompt
    call print
    call read_line

    ; Parse hours
    mov rsi, input
    mov rdi, rsi
    call atoi
    mov cl, al        ; save hours in cl
    
    ; Skip to next number (find space, then skip spaces)
    mov rsi, input
.find_space:
    cmp byte [rsi], ' '
    je .skip_spaces
    cmp byte [rsi], 0
    je .error
    inc rsi
    jmp .find_space
    
.skip_spaces:
    cmp byte [rsi], ' '
    jne .parse_mins
    inc rsi
    jmp .skip_spaces
    
.parse_mins:
    mov rdi, rsi
    call atoi
    mov ch, al        ; save minutes in ch
    
    ; Store alarm
    movzx rbx, byte [alarm_count]
    mov [alarm_hours + rbx], cl
    mov [alarm_mins + rbx], ch
    inc byte [alarm_count]
    
    mov rdi, added_msg
    call print
    ret
    
.error:
    mov rdi, invalid_opt
    call print
    ret

; ───────────────────────────────
; List Alarms
; ───────────────────────────────
list_alarms:
    movzx rax, byte [alarm_count]
    cmp al, 0
    je .none
    
    mov rdi, list_header
    call print
    
    xor rcx, rcx              ; counter
.print_loop:
    cmp rcx, rax
    jge .done
    
    ; Print alarm number
    mov rdi, rcx
    add rdi, '1'              ; convert to ASCII
    mov [temp_char], dil
    mov byte [temp_char+1], ':'
    mov byte [temp_char+2], ' '
    mov byte [temp_char+3], 0
    lea rdi, [temp_char]
    call print
    
    ; Print hours (simplified - just show as number)
    movzx rdi, byte [alarm_hours + rcx]
    call print_number
    
    mov rdi, colon_space
    call print
    
    ; Print minutes
    movzx rdi, byte [alarm_mins + rcx]
    call print_number
    
    mov rdi, newline
    call print
    
    inc rcx
    jmp .print_loop
    
.done:
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
    lea rdi, [rel sleep_spec]
    xor rsi, rsi   ; remaining time (NULL)
    syscall
    jmp .loop

; ───────────────────────────────
; MAIN LOOP
; ───────────────────────────────
_start:
    ; Start background alarm checker
    mov rax, 57      ; sys_fork
    syscall
    test rax, rax
    jz start_daemon  ; child becomes daemon
    
    ; Parent continues with menu
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

start_daemon:
    ; Background process - just check alarms
    call check_alarms

exit_program:
    mov rax, 60
    xor rdi, rdi
    syscall
