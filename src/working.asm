; Clockman - Simple Working Assembly Alarm
; No background processes for now, just basic menu system

section .data
    menu_txt     db "=== CLOCKMAN ===", 10
                 db "1. Add alarm", 10
                 db "2. List alarms", 10  
                 db "3. Exit", 10
                 db "Choice: ", 0

    prompt_txt   db "Enter time (HHMM): ", 0
    added_txt    db "Alarm added!", 10, 0
    list_txt     db "Alarms:", 10, 0
    empty_txt    db "No alarms.", 10, 0
    invalid_txt  db "Invalid choice!", 10, 0
    newline_txt  db 10, 0

section .bss
    choice       resb 2
    time_input   resb 6
    alarms       resb 200    ; 50 alarms max, 4 chars each
    alarm_count  resb 1

section .text
global _start

; Print string function
print_str:
    push rax
    push rcx
    push rdx
    push rsi
    
    mov rsi, rdi            ; string to print
    mov rcx, 0              ; counter
    
.count_chars:
    cmp byte [rsi + rcx], 0
    je .do_print
    inc rcx
    jmp .count_chars
    
.do_print:
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rdx, rcx            ; length
    syscall
    
    pop rsi
    pop rdx
    pop rcx
    pop rax
    ret

; Read single character
read_char:
    push rax
    push rcx
    push rdx
    push rsi
    
    mov rax, 0              ; sys_read  
    mov rdi, 0              ; stdin
    mov rsi, choice         ; buffer
    mov rdx, 2              ; read 1 char + newline
    syscall
    
    pop rsi
    pop rdx  
    pop rcx
    pop rax
    ret

; Read time input (4 chars)
read_time:
    push rax
    push rcx
    push rdx
    push rsi
    
    mov rax, 0              ; sys_read
    mov rdi, 0              ; stdin  
    mov rsi, time_input     ; buffer
    mov rdx, 6              ; read up to 5 chars + newline
    syscall
    
    pop rsi
    pop rdx
    pop rcx
    pop rax
    ret

add_alarm:
    ; Print prompt
    mov rdi, prompt_txt
    call print_str
    
    ; Read time
    call read_time
    
    ; Store the alarm
    movzx rax, byte [alarm_count]   ; load count
    mov rcx, 4                      ; 4 chars per alarm
    mul rcx                         ; rax = offset
    
    ; Copy 4 characters from time_input to alarms
    mov cl, [time_input]
    mov [alarms + rax], cl
    mov cl, [time_input + 1]  
    mov [alarms + rax + 1], cl
    mov cl, [time_input + 2]
    mov [alarms + rax + 2], cl
    mov cl, [time_input + 3]
    mov [alarms + rax + 3], cl
    
    ; Increment count
    inc byte [alarm_count]
    
    ; Print confirmation
    mov rdi, added_txt
    call print_str
    
    ret

list_alarms:
    ; Check if we have any alarms
    movzx rax, byte [alarm_count]
    cmp rax, 0
    je .no_alarms
    
    ; Print header
    mov rdi, list_txt
    call print_str
    
    ; Print each alarm
    mov rbx, 0                      ; counter
    
.print_loop:
    cmp rbx, rax                    ; compare with count
    jge .done
    
    ; Calculate offset
    mov rcx, rbx
    mov rdx, 4
    imul rcx, rdx                   ; rcx = offset
    
    ; Copy alarm to time_input for printing
    mov dl, [alarms + rcx]
    mov [time_input], dl
    mov dl, [alarms + rcx + 1]
    mov [time_input + 1], dl  
    mov dl, [alarms + rcx + 2]
    mov [time_input + 2], dl
    mov dl, [alarms + rcx + 3]
    mov [time_input + 3], dl
    mov byte [time_input + 4], 0    ; null terminate
    
    ; Print the alarm time
    mov rdi, time_input
    call print_str
    
    ; Print newline  
    mov rdi, newline_txt
    call print_str
    
    inc rbx
    jmp .print_loop
    
.done:
    ret
    
.no_alarms:
    mov rdi, empty_txt
    call print_str
    ret

_start:
    ; Initialize alarm count
    mov byte [alarm_count], 0

.main_loop:
    ; Print menu
    mov rdi, menu_txt
    call print_str
    
    ; Read choice
    call read_char
    
    ; Check choice
    mov al, [choice]
    cmp al, '1'
    je .add_alarm_choice
    cmp al, '2'  
    je .list_alarms_choice
    cmp al, '3'
    je .exit_choice
    
    ; Invalid choice
    mov rdi, invalid_txt
    call print_str
    jmp .main_loop

.add_alarm_choice:
    call add_alarm
    jmp .main_loop
    
.list_alarms_choice:
    call list_alarms
    jmp .main_loop
    
.exit_choice:
    ; Exit program
    mov rax, 60                     ; sys_exit
    mov rdi, 0                      ; exit code
    syscall