BASE=ass3_22CS10030_22CS10049
LEX_FILE=$(BASE).l
C_FILE=$(BASE).c
OUT_FILE=$(BASE).out
OUTPUT_FILE=$(BASE).output.txt
TEST_FILE=$(BASE)_test.c

$(OUTPUT_FILE): $(OUT_FILE) $(TEST_FILE)
	./$(OUT_FILE) < $(TEST_FILE) > $(OUTPUT_FILE)

$(OUT_FILE): lex.yy.c $(C_FILE)
	gcc lex.yy.c $(C_FILE) -o $(OUT_FILE) -lfl

lex.yy.c: $(LEX_FILE)
	lex $(LEX_FILE)

clean:
	rm -f lex.yy.c $(OUT_FILE) $(OUTPUT_FILE)