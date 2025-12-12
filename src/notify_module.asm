;This does dynamic notification rendering, built specifically for Wayland.
;API
;notify(rdi=title_ptr, rsi=body_ptr)
;Sends Desktop notification using /usr/bin/notify-send
;Inherits envp from caller (Wayland/DBus)

;Build: nasm -f elf64 notify.asm -o notify.o 

section .data
notify_path db "/usr/bin/notify-send", 0 ;Nul terminated string with absolute path. db emits bytes, and the 0 is the terminator that execve expects
;END With 0 for termination. db isn't instruction its define bytes  - store the string as raw bytes

section .bss
argv_runtime resq 4 ;resq - reserve quadwords i.e. allocate 4 slots(1 slot=8B)
;So each slot holds a 64 bit pointer - we get argv[0], [1], [2] and argv[3]=NULL

section .text
global notify ;global exports this functions for other files to call

notify:
;function entry: rdi = title string pointer, rsi= body string pointer
mov rax, 57 ;rax is syscall number, while 57 forks (child process creation)

syscall ;Returns with parent gets child PID in RAX, child gets 0 in RAX

test rax, rax ;check if rax is 0
jnz .parent

;Since control didnt jump, the below is full CHILD PROCESS ONLY
lea rdx, [rel notify_path] 
; lea - load effective address  - get memory address of notify path. rel = relativ eto current isntruction (position independency). This address stored in rdx

mov [argv_runtime+0*8], rdx ;  Storing notify_path address in argv[0]
mov [argv_runtime+1*8], rdi ; store rdi(title pointer) in argv[1]
mov [argv_runtime+2*8], rsi;
mov qword [argv_runtime+3*8], 0 ; qword is 8 byte value. We set NULL terminator for argv array, by setting argv[3] to 0

mov rbx, rsp ; rbx=stack pointer.  At start of process, stack top contains argument count. Then it contains argv pointers, NULL and envp pointers ([argc][argv pointers][NULL][envp pointers])
mov rax, [rbx] ; rax is argument count, stored at stack top.

lea rbx, [rbx+8] ;now points to argv[0]

.find_argv_end:

mov rcx, [rbx]
add rbx, 8
test rcx, rcx ; check if rcx is 0
jnz .find_argv_end

;end reached
mov rdx, rbx
;Now rbx points past NULL, i.e. to envp[0]
;rdx stores envp address

mov rax, 59 ;rax=syscall 59 = execve (i.e. replace this process with another program)

lea rdi, [rel notify_path] ;rdi=path to exectute (first arg to execve)

lea rsi, [rel argv_runtime] ; rsi has argv array poitner (2nd arg to execve)

;rdx has the third arg to execve (i.e. envp)

syscall 
;execute execve. this process is notify-send. If failure, returns with error in rax

mov rax, 60 ; rax is syscall, 60 is exit (reached if execve failed)

mov rdi, 1 ;(rdi now has exit code 1 error)
syscall ; exit child process

.parent:
ret ;return to caller



