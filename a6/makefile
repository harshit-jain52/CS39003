all:
	bison -d prog.y
	flex -o prog.yy.c prog.l
	gcc -o icgen codegen.c

run: all
	./icgen < sample.txt

clean:
	-rm -f *.tab.* *.yy.c icgen ic.txt tc.txt symtable.txt