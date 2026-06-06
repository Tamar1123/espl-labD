all: multi task0

multi: multi.o
	gcc -m32 -no-pie multi.o -o multi

multi.o: multi.s
	nasm -f elf32 multi.s -o multi.o

task0: task0.o
	gcc -m32 -no-pie task0.o -o task0

task0.o: task0.s
	nasm -f elf32 task0.s -o task0.o

.PHONY: all clean

clean:
	rm -f *.o multi task0