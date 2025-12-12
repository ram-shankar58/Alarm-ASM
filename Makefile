all: alarm-main

src/notify.o: src/notify_module.asm
	nasm -f elf64 -g $< -o $@

src/alarmstore.o: src/alarmstore.asm
	nasm -f elf64 -g $< -o $@

src/alarm.o: src/alarm.asm
	nasm -f elf64 -g $< -o $@

alarm-main: src/alarm.o src/alarmstore.o src/notify.o
	ld src/alarm.o src/alarmstore.o src/notify.o -o alarm-main

run: alarm-main
	./alarm-main

clean:
	rm -f src/*.o alarm-main notify-test notify-module
