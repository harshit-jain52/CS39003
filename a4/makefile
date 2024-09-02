all:
	yacc -d expr.y
	lex expr.l
	gcc expr.c

clean:
	-rm -f a.out y.tab.h y.tab.c lex.yy.c