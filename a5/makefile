all:
	bison -d expr.y
	flex -o expr.yy.c expr.l
	gcc -o icgen intcodegen.c

run: all
	./icgen < sample.txt > intcode.c
	gcc -o ic intcode.c
	./ic > output.txt

clean:
	-rm -f *.tab.* *.yy.c intcode.c ic icgen output.txt
