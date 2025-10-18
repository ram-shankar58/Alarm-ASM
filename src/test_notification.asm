; notify_dbus_asm.asm
; Pure NASM + libdbus notification sender for Hyprland (works with mako/dunst)
; Build: nasm -f elf64 notify_dbus_asm.asm -o notify_dbus_asm.o
;        gcc notify_dbus_asm.o -o notify_dbus_asm -ldbus-1

        global  main
        extern  dbus_error_init
        extern  dbus_bus_get
        extern  dbus_message_new_method_call
        extern  dbus_message_iter_init_append
        extern  dbus_message_iter_append_basic
        extern  dbus_message_iter_open_container
        extern  dbus_message_iter_close_container
        extern  dbus_connection_send
        extern  dbus_connection_flush
        extern  dbus_message_unref
        extern  dbus_error_free
        extern  dbus_error_is_set
        extern  printf
        extern  exit

        section .data
app_name        db  "asm-notify",0
app_icon        db  "",0
summary_str     db  "Hello from Assembly",0
body_str        db  "This notification was sent using libdbus from NASM.",0

dest_name       db  "org.freedesktop.Notifications",0
obj_path        db  "/org/freedesktop/Notifications",0
iface_name      db  "org.freedesktop.Notifications",0
method_name     db  "Notify",0

sig_s           db  "s",0
sig_dict_sv     db  "{sv}",0

DBUS_TYPE_STRING     equ 's'
DBUS_TYPE_UINT32     equ 'u'
DBUS_TYPE_ARRAY      equ 'a'
DBUS_TYPE_INT32      equ 'i'

        section .bss
err_buf         resb 64
iter_buf        resb 64
array_iter_buf  resb 64
dict_array_iter resb 64

        section .text

main:
        ; Initialize DBusError
        lea     rdi, [rel err_buf]
        call    dbus_error_init

        ; Connect to session bus
        xor     edi, edi                  ; DBUS_BUS_SESSION = 0
        lea     rsi, [rel err_buf]
        call    dbus_bus_get
        test    rax, rax
        je      .fail_exit
        mov     r12, rax                  ; connection

        ; Create method call
        lea     rdi, [rel dest_name]
        lea     rsi, [rel obj_path]
        lea     rdx, [rel iface_name]
        lea     rcx, [rel method_name]
        call    dbus_message_new_method_call
        test    rax, rax
        je      .fail_exit
        mov     r13, rax                  ; message

        ; Init iterator
        mov     rdi, r13
        lea     rsi, [rel iter_buf]
        call    dbus_message_iter_init_append

        ; Append: app_name
        lea     rdi, [rel iter_buf]
        mov     esi, DBUS_TYPE_STRING
        lea     rdx, [rel app_name]
        call    dbus_message_iter_append_basic

        ; Append: replaces_id = 0 (uint32)
        sub     rsp, 8
        mov     dword [rsp], 0
        lea     rdi, [rel iter_buf]
        mov     esi, DBUS_TYPE_UINT32
        lea     rdx, [rsp]
        call    dbus_message_iter_append_basic
        add     rsp, 8

        ; Append: app_icon
        lea     rdi, [rel iter_buf]
        mov     esi, DBUS_TYPE_STRING
        lea     rdx, [rel app_icon]
        call    dbus_message_iter_append_basic

        ; Append: summary
        lea     rdi, [rel iter_buf]
        mov     esi, DBUS_TYPE_STRING
        lea     rdx, [rel summary_str]
        call    dbus_message_iter_append_basic

        ; Append: body
        lea     rdi, [rel iter_buf]
        mov     esi, DBUS_TYPE_STRING
        lea     rdx, [rel body_str]
        call    dbus_message_iter_append_basic

        ; Append: actions (empty array of strings)
        lea     rdi, [rel iter_buf]
        mov     esi, DBUS_TYPE_ARRAY
        lea     rdx, [rel sig_s]
        lea     rcx, [rel array_iter_buf]
        call    dbus_message_iter_open_container
        lea     rdi, [rel iter_buf]
        lea     rsi, [rel array_iter_buf]
        call    dbus_message_iter_close_container

        ; Append: hints (empty array of dict entries)
        lea     rdi, [rel iter_buf]
        mov     esi, DBUS_TYPE_ARRAY
        lea     rdx, [rel sig_dict_sv]
        lea     rcx, [rel dict_array_iter]
        call    dbus_message_iter_open_container
        lea     rdi, [rel iter_buf]
        lea     rsi, [rel dict_array_iter]
        call    dbus_message_iter_close_container

        ; Append: expire_timeout = -1 (int32)
        sub     rsp, 8
        mov     dword [rsp], -1
        lea     rdi, [rel iter_buf]
        mov     esi, DBUS_TYPE_INT32
        lea     rdx, [rsp]
        call    dbus_message_iter_append_basic
        add     rsp, 8

        ; Send + flush
        mov     rdi, r12
        mov     rsi, r13
        xor     rdx, rdx
        call    dbus_connection_send

        mov     rdi, r12
        call    dbus_connection_flush

        ; Cleanup
        mov     rdi, r13
        call    dbus_message_unref

        xor     edi, edi
        call    exit

.fail_exit:
        lea     rdi, [rel err_msg]
        xor     eax, eax
        call    printf
        mov     edi, 1
        call    exit

        section .rodata
err_msg db "notify_dbus_asm: failed to connect or create message",10,0
