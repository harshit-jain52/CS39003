BASE=tinyC2_22CS10030_22CS10049

all:
	yacc -d $(BASE).y
	lex $(BASE).l
	gcc $(BASE).c

clean:
	-rm -f a.out y.tab.h y.tab.c lex.yy.c