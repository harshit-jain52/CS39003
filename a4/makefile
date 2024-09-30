all:
	yacc -d poly.y
	lex poly.l
	gcc polyutils.c

run: all
	./a.out < sample.txt > output.txt

clean:
	rm -f lex.yy.c y.tab.* *.out output.txt

