;The alarm menu
section .data
    menu_str db "Alarm Menu: ", 10, "1) Add", 10,"2) List",10,"3) Remove last",10,"4) Exit",10,0
    prompt_add db "Enter time HH MM (eg: 07 30): ", 0
    added_str db "Added.", 10, 0
    full_str db "List Full", 10, 0
    empty_str db "List Empty.", 10, 0
    removed_str db "Removed.", 10, 0
    bad_input db "Bad Input.", 10, 0
    list_header db "Alarms:", 10, 0

section .bss
    input_buf resb 64 ;input buffer

section .text
    global _start
    extern add_alarm
    extern remove_last_alarm
    extern list_alarms
    extern alarm_count

write_cstr:
;write_cstr(rdi=ptr) - writes null terminated string to stdout
    push rdi ; save ptr
    mov rax, 0 ;len =0
.len_loop:
    cmp byte [rdi+rax], 0 
    je .got_len 
    inc rax
    jmp .len_loop
.got_len:
    mov rdx, rax ; rdxx=len
    pop rsi ;rsi=ptr
    mov rax, 1 ;sys_write
    mov rdi, 1 ; fd=stdout
    syscall
    ret

read_line:
    ;read_line()-> rax=bytes read, buffer at input_buffer, null terminated
    mov rax, 0 ; sys_read
    mov rdi, 0; fd=stdin
    lea rsi, [rel input_buf] 
    mov rdx, 63 ; max bytes
    syscall
    cmp rax, 0
    jle .done ;EOF error
    mov byte [input_buf+rax-1], 0 ; replace '\n\ with 0
.done:
    ret

parse_hh_mm:
;parse_hh_mm(rdi=ptr) -> rax=hh (0-23) or -1, rbx=mm (0-59)
    mov rsi, rdi              ; rsi=input ptr

    ; skip leading spaces
.skip1:
    cmp byte [rsi], ' '
    jne .h1
    inc rsi
    jmp .skip1

.h1:
    mov al, [rsi]             ; first hour digit
    sub al, '0'
    jc .bad                   ; not a digit
    cmp al, 9
    ja .bad
    mov bl, al                ; bl = first digit
    inc rsi                   ; advance

    ; optional second hour digit
    mov dl, [rsi]
    cmp dl, '0'
    jb .one_h_digit
    cmp dl, '9'
    ja .one_h_digit
    sub dl, '0'
    movzx ebx, bl             ; widen first digit
    imul ebx, ebx, 10         ; tens * 10
    add bl, dl                ; bl = tens*10 + ones
    inc rsi                   ; consumed second digit
    jmp .after_hour

.one_h_digit:
    ; hour stays in bl

.after_hour:
    ; skip spaces before minute
.skip2:
    cmp byte [rsi], ' '
    jne .m1
    inc rsi
    jmp .skip2

.m1:
    mov al, [rsi]             ; first minute digit
    sub al, '0'
    jc .bad
    cmp al, 9
    ja .bad
    mov bh, al                ; bh = first digit
    inc rsi

    ; optional second minute digit
    mov dl, [rsi]
    cmp dl, '0'
    jb .one_m_digit
    cmp dl, '9'
    ja .one_m_digit
    sub dl, '0'
    movzx eax, bh             ; widen first digit
    imul eax, eax, 10         ; tens * 10
    movzx ecx, dl             ; ecx = ones
    add eax, ecx              ; eax = minute value
    mov bh, al                ; bh = minute (low byte)
    inc rsi                   ; consumed second digit
    jmp .after_min

.one_m_digit:
    ; minute stays in bh

.after_min:
    cmp bl, 23                ; hour <= 23 ?
    ja .bad
    cmp bh, 59                ; minute <= 59 ?
    ja .bad
    xor rax, rax              ; rax = 0
    mov al, bl                ; rax = hour
    ret
.bad:
    mov rax, -1
    ret

_start:
    xor rax, rax
    mov [rel alarm_count], rax ;init count=0 at startup
.menu:
    lea rdi, [rel menu_str] ;print menu
    call write_cstr
    call read_line ;get choice
    cmp rax, 0
    jle .exit ;EOF leads to exit
    cmp byte [input_buf], '1'
    je .do_add
    cmp byte [input_buf], '2'
    je .do_list
    cmp byte [input_buf], '3'
    je .do_remove
    cmp byte [input_buf], '4'
    je .exit
    lea rdi, [rel bad_input]
    call write_cstr
    jmp .menu

.do_add:
    lea rdi, [rel prompt_add] ;prompt
    call write_cstr
    call read_line ;read HH MM
    cmp rax, 0
    jle .menu
    lea rdi, [rel input_buf]
    call parse_hh_mm
    cmp rax, -1
    je .bad_add
    mov rdi, rax           ; rdi=hour (low byte used)
    movzx ecx, bh          ; ecx=minute (zero-extend from bh)
    mov rsi, rcx           ; rsi=minute
    call add_alarm
    cmp rax, -1
    je .full_list
    lea rdi, [rel added_str]
    call write_cstr
    jmp .menu
.bad_add:
    lea rdi, [rel bad_input]
    call write_cstr
    jmp .menu
.full_list:
    lea rdi, [rel full_str]
    call write_cstr
    jmp .menu

.do_list:
    lea rdi, [rel list_header]
    call write_cstr
    call list_alarms
    jmp .menu

.do_remove:
    call remove_last_alarm
    cmp rax, -1
    je .empty_list
    lea rdi, [rel removed_str]
    call write_cstr
    jmp .menu
.empty_list:
    lea rdi, [rel empty_str]
    call write_cstr
    jmp .menu

.exit:
    mov rax, 60 ;sys_exit
    xor rdi, rdi ; status 0
    syscall

