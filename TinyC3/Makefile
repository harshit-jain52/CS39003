BASE=TinyC3_22CS10030_22CS10049

a.out: lex.yy.o y.tab.o $(BASE)_translator.o
	g++ lex.yy.o y.tab.o $(BASE)_translator.o

lex.yy.c: $(BASE).l y.tab.h $(BASE)_translator.h
	flex -o lex.yy.c $(BASE).l

y.tab.c y.tab.h: $(BASE).y
	bison -dty $(BASE).y  	

$(BASE)_translator.o: $(BASE)_translator.h $(BASE)_translator.cxx
	g++ -c $(BASE)_translator.h
	g++ -c $(BASE)_translator.cxx

lex.yy.o: lex.yy.c
	g++ -c lex.yy.c

y.tab.o: y.tab.c
	g++ -c y.tab.c

test: a.out
	mkdir -p test_out
	for i in 1 2 3 4 5; do \
		./a.out < test_in/$(BASE)_test$$i.c > test_out/$(BASE)_quads$$i.out; \
	done
	for i in 1 2; do \
		./a.out < test_in/$(BASE)_err$$i.c > test_out/$(BASE)_errquads$$i.out; \
	done

clean:
	-rm -rf a.out *.yy.* *.o *.tab.* *.h.gch test_out/