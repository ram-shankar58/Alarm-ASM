;This has the in-memory alarm list
;Exports: add_alarm(HH, MM), remove_last_alarm(), list_alarms()

section .data
    MAX_ALARMS equ 16
    LINE_LEN equ 6  ;'HH:MM\n' is the length is 6

section .bss
    global alarm_count
    alarms_hh resb MAX_ALARMS ;hours array in bytes
    alarms_mm resb MAX_ALARMS ; minutes array in bytes
    alarm_count resq 1 ; 64 bit count
    line_buf resb LINE_LEN ; temporary buffer to print one line at a time

section .text
    global add_alarm
    global remove_last_alarm
    global list_alarms

add_alarm:
    ;add_alarm(rdi=hh, rsi=mm) -> RAX=0 implies OK, RAX=-1 implies full
    
    mov rcx, [alarm_count] ;rcx=count
    cmp rcx, MAX_ALARMS
    jae .full

    ;NOT full
    mov rbx, rcx ; rbx has index
    mov [alarms_hh+rbx], dil ; store hour
    mov[alarms_mm+rbx], sil ; minute
    inc rcx ;count++
    mov [alarm_count], rcx ; save count
    xor rax, rax ;rax=0 success
    ret

.full:
    mov rax, -1
    ret

remove_last_alarm:
    ;remove_last_alarm() -> rax=0 OK, RAX=-1 empty
    mov rcx, [alarm_count] ; rcx=count
    test rcx, rcx
    jz .empty

    dec rcx
    mov[alarm_count], rcx ;save count
    xor rax, rax
    ret

.empty:
    mov rax, -1
    ret

list_alarms:
    ;list_alarms() -> rax=number listed, that is prints HH:MM\n for each alarm
    mov rcx, [alarm_count] ; rcx=count
    cmp rcx, MAX_ALARMS
    jbe .count_ok
    xor rcx, rcx ;CLAMP TO 0 IF CORRUPTED
    mov [alarm_count], rcx
.count_ok:
    xor rbx, rbx ;index =0 (use callee-saved reg to avoid syscall clobber)
    mov r9, rcx ;keep count stable; we will use cl elsewhere
    mov r8, rcx ;save count for returning

.next:
    cmp rbx, r9
    jae .done
    mov al, [alarms_hh+rbx] ; al has the hour (keep rbx intact)
    mov dl, [alarms_mm+rbx] ; dl has the minute (keep rbx intact)

    mov r10b, 10 ;divisor in r10b so we don't clobber count
    ; hour
    xor ah, ah ;clear the high byte
    div r10b ; al=hour/10, ah=hour%10
    add al, '0' ; '0'+tens digit 
    mov [line_buf], al ;write tens digit
    mov al, ah
    add al, '0' ; '0'+ones digit
    mov [line_buf+1], al ; write ones digit
    mov byte [line_buf+2], ':'
    
    mov al, dl ;al=minute
    xor ah, ah
    div r10b ;al=al/10, ah=al%10
    add al, '0' ; '0'+tens digit 
    mov [line_buf+3], al ;
    mov al, ah ;ones
    add al, '0';
    mov [line_buf+4], al 
    mov byte [line_buf+5], 10 ;'\n'

    mov rax, 1 ;sys_write
    mov rdi, 1 ;fd=stdout 
    lea rsi, [rel line_buf] 
    mov rdx, LINE_LEN
    syscall
    inc rbx ;index++
    jmp .next

.done:
    mov rax, r8 ;return count
    ret
    


