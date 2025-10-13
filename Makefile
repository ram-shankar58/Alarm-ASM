all:
	nasm -f elf64 -g src/main.asm -o src/main.o
	ld src/main.o -o asm-alarm

run: all
	./asm-alarm

clean:
	rm -f src/main.o asm-alarm
