; Background alarm scheduler per alarm
; Exports: schedule_alarm(hh, mm) - forks a child that sleeps until that HH:MM local time and notifies once

section .data
    alarmtitle db "Alarm!", 0
    alarmbody db "YOUR ALARM TIME HAS COME!", 0
    TZ_OFFSET equ 19800 ; Indian Standard Time (IST) - 5.5*3600=19800 seconds

section .text
    global schedule_alarm
    extern notify

schedule_alarm:
    ; schedule_alarm(rdi=hh, rsi=mm) -> forks a child that sleeps until hh:mm local and notifies
    ; save parameters before fork (they survive fork but will be clobbered by syscalls)
    mov r14, rdi ; r14 = target hour
    mov r15, rsi ; r15 = target minute
    
    mov rax, 57 ;sys_fork
    syscall
    test rax, rax
    jnz .parent

    ; child computes sleep seconds until target hh:mm (today or tomorrow)
    ; Get current time (Unix timestamp)
    mov rax, 201 ;sys_time
    xor rdi, rdi
    syscall ; rax = epoch seconds UTC
    mov rbx, TZ_OFFSET
    add rax, rbx ; rax = local epoch seconds

    ; Compute seconds since midnight now
    mov rbx, 86400
    xor rdx, rdx
    div rbx ; rdx = seconds_today
    mov rcx, rdx ; rcx = seconds_today

    ; target seconds = hh*3600 + mm*60 (use saved r14/r15)
    mov rax, r14       ; r14 = saved hh
    mov rbx, 3600
    mul rbx            ; rdx:rax = hh*3600
    mov r8, rax        ; r8 = hh*3600
    mov rax, r15       ; r15 = saved mm
    mov rbx, 60
    mul rbx            ; rdx:rax = mm*60
    add r8, rax        ; r8 = target seconds today

    ; if target already passed, add 86400 to schedule for next day
    cmp r8, rcx
    ja .same_day
    add r8, 86400
.same_day:
    ; sleep_seconds = target - seconds_today
    sub r8, rcx

    ; build timespec for nanosleep: tv_sec = sleep_seconds, tv_nsec = 0
    mov [sleep_spec], r8       ; tv_sec = sleep_seconds
    mov qword [sleep_spec+8], 0 ; tv_nsec = 0

    ; sleep until alarm
    mov rax, 35        ; sys_nanosleep
    lea rdi, [rel sleep_spec]
    xor rsi, rsi
    syscall

    ; fire notification
    lea rdi, [rel alarmtitle]
    lea rsi, [rel alarmbody]
    call notify

    ; exit child
    mov rax, 60
    xor rdi, rdi
    syscall

.parent:
    ret

section .data
    sleep_spec:
        dq 0 ; tv_sec placeholder
        dq 0 ; tv_nsec placeholder

