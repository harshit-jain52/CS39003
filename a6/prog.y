%{  
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <stdbool.h>
    #include <ctype.h>

    #define INTSIZE 4   // Size of signed integer
    
    extern int yylex();
    extern int yylineno;
    void yyerror ( char * );
    
    // Quadruple
    typedef struct quad_{
        int type, label;
        char *op, *arg1, *arg2, *res;
    } quad;

    // Quad Array
    typedef struct quadArray_{
        struct quad_* q;
        struct quadArray_* next;
    } quadArray;

    // Symbol for Symbol Table
    typedef struct sym_{
        char* id;
        struct sym_* next;
        int offset;
        int regno;
        bool stored;
        bool live;
    } sym;

    // Descriptor for Register Descriptor
    typedef struct descriptor_{
        struct sym_* symbol;
        struct descriptor_* next;
    } descriptor;

    // Register
    typedef struct reg_{
        int score;
        struct descriptor_* desc;
    } reg;

    void throwError(char *);                        // Error handling
    bool isConst(char *);                           // Check if a string is a constant
    
    void addSym(char*);                             // Add a symbol to the symbol table
    struct sym_* findSym(char*);                    // Find a symbol in the symbol table

    void emit(int, char*, char*, char*, char*);     // Emit a quadruple
    void backpatch(int, int);                       // Backpatch a label in quadruple
    void identifyLeaders();                         // Identify leaders of basic blocks in intermediate code
    void ICGen();                                   // Generate Intermediate Code

    void freeAllRegs();                             // Free all registers
    void freeReg(int);                              // Free a register
    void freeDesc(struct descriptor_*, int);        // Free a register descriptor
    void allocateReg(int, struct sym_*);            // Allocate a register for a symbol
    void addDesc(int, struct sym_*);                // Add a symbol to a register descriptor
    void ICtoTC();                                  // Intermediate Code to Target Code

    void emitTarget(int, char*, char*, char*, char*, int);  // Emit a target quadruple
    void identifyTargetLeaders();                   // Identify leaders of target code
    void TCGen();                                   // Generate Target Code

    int tmpno=0;                    // Temporary variable number
    int instr=0;                    // Instruction number in intermediate code
    int targetinstr=0;              // Instruction number in target code
    struct sym_* ST = NULL;         // Symbol Table
    struct quadArray_* QA = NULL;   // Intermediate Quadruple Array
    struct quadArray_* TQA = NULL;  // Target Quadruple Array
    bool* leaders = NULL;           // Leaders of basic blocks in intermediate code
    int* insMap = NULL;             // Map of intermediate code instructions to target code instructions
    bool* targetLeaders = NULL;     // Leaders of basic blocks in target code
    struct reg_* RB = NULL;         // Register Bank
    int RSIZE = 5;                  // No. of registers available, default 5
%}

%union {
    char* text;
    int num;
}

%token '+' '-' '*' '/' '%' EQ NE LT GT LE GE
%token <text> IDEN NUMB
%token SET WHEN LOOP WHILE
%token LDST OP JCOND JUMP   // Not used for parsing, used for target code generation

%type list stmt asgn cond loop program
%type <text> atom oper expr reln bool
%type <num> M
%start program

%%

// Dummy Start
program
    : list  {instr++;}
    ;

list
    : stmt
    | stmt list
    ;

stmt
    : asgn
    | cond
    | loop
    ;

asgn
    : '(' SET IDEN atom ')'
    {   
        addSym($3);
        emit(EQ,NULL,$4,NULL,$3);
    }
    ;

cond
    : '(' WHEN bool M list ')'
    {
        backpatch($4,instr+1);
    }
    ;

loop
    : '(' LOOP WHILE bool M list ')'
    {
        emit(WHILE,NULL,NULL,NULL,NULL);
        backpatch($5,instr+1);
        backpatch(instr,$5);
    }
    ;

expr
    : '(' oper atom atom ')'
    {
        $$ = (char*)malloc(10*sizeof(char));
        sprintf($$,"$%d",++tmpno);
        addSym($$);
        emit(EQ, $2, $3, $4, $$);
    }
    ;

bool
    : '(' reln atom atom ')'
    {
        emit(WHEN,$2,$3,$4,NULL);
    }
    ;

atom
    : IDEN
    {
        if(findSym($1)==NULL) yyerror("Undefined variable");
        $$ = $1;
    }
    | NUMB  {$$ = $1;}
    | expr  {$$ = $1;}
    ;

oper
    : '+'   {$$ = strdup("+");}
    | '-'   {$$ = strdup("-");}
    | '*'   {$$ = strdup("*");}
    | '/'   {$$ = strdup("/");}
    | '%'   {$$ = strdup("%");}
    ;

reln
    : EQ    {$$ = strdup("==");}
    | NE    {$$ = strdup("!=");}
    | LT    {$$ = strdup("<");}
    | GT    {$$ = strdup(">");}
    | LE    {$$ = strdup("<=");}
    | GE    {$$ = strdup(">=");}
    ;

// Marker non-terminal for backpatching
M   :   {$$ = instr;}
    ;

%%

void yyerror (char * err)
{
    throwError(err);
}