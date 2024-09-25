ROLL=_22CS10030_22CS10049
BASE=tinyC2${ROLL}

all:
	yacc -d $(BASE).y
	lex $(BASE).l
	gcc $(BASE).c

run: all input${ROLL}.c
	./a.out < input${ROLL}.c > output${ROLL}.txt

clean:
	-rm -f a.out y.tab.h y.tab.c lex.yy.c