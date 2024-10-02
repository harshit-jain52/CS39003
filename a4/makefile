all:
	bison -d poly.y
	flex -o poly.yy.c poly.l
	gcc -o poly.out polyutils.c

run: all
	./poly.out < sample.txt > output.txt

clean:
	rm -f *.yy.c *.tab.* *.out output.txt

