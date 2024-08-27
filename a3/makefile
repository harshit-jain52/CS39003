CC=gcc
BASE=ass3_22CS10030_22CS10049
LEX_FILE=$(BASE).l
C_FILE=$(BASE).c
OUT_FILE=$(BASE).out
OUTPUT_FILE=$(BASE).output.txt
TEST_FILE=$(BASE)_test.c

run:
	@lex $(LEX_FILE)
	@$(CC) lex.yy.c $(C_FILE) -o $(OUT_FILE)
	./$(OUT_FILE) < $(TEST_FILE) > $(OUTPUT_FILE)

clean:
	rm -f lex.yy.c $(OUT_FILE) $(OUTPUT_FILE)