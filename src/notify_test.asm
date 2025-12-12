section .data
title_str db "Assembly Alarm", 0
body_str db "Meow meow This is a dynamic check message", 0

section .text
extern notify ; this function is defined in another module 

global _start ; entry point of program

_start:
lea rdi, [rel title_str] ; rdi has address of title_str (1st argument )
lea rsi, [rel body_str]

call notify ; jump to notify function
mov rax, 61 ; rax=syscall 61 is wait4 (wait for child to finish)

mov rdi, -1 ; rdi=-1 wait for any child
xor rsi, rsi ;zero out rsi (NULL pointer for status)
xor rdx, rdx ; zero our rdx (NULL for rusage)

xor r10, r10 ; zero out r10 (NULL for options)

syscall 
mov rax, 60 ; 60=exit
xor rdi, rdi; rdi=0 exit code for success
syscall ;exit progrma