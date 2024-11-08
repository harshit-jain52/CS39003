%{  
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <stdbool.h>
    #include <ctype.h>

    #ifndef RSIZE
    #define RSIZE 5
    #endif

    extern int yylex();
    extern int yylineno;
    void yyerror ( char * );
    
    typedef struct quad_{
        int type, label;
        char *op, *arg1, *arg2, *res;
    } quad;

    typedef struct quadArray_{
        struct quad_* q;
        struct quadArray_* next;
    } quadArray;

    typedef struct sym_{
        char* id;
        struct sym_* next;
        int regno;
        bool stored;
    } sym;

    typedef struct descriptor_{
        struct sym_* symbol;
        struct descriptor_* next;
    } descriptor;

    typedef struct reg_{
        int score;
        struct descriptor_* desc;
    } reg;

    
    void addSym(char*);
    struct sym_* findSym(char*);
    void emit(int, char*, char*, char*, char*);
    void backpatch(int, int);
    void ICGen();
    void identifyLeaders();

    void freeAllRegs();
    void freeReg(int);
    void freeDesc(struct descriptor_*, int);
    void allocateReg(int, struct sym_*);
    void addDesc(int, struct sym_*);

    void ICtoTC();
    void emitTarget(int, char*, char*, char*, char*, int);
    void TCGen();
    void identifyTargetLeaders();

    int tmpno=0;
    int instr=0;
    int targetinstr=0;
    struct sym_* ST = NULL;
    struct quadArray_* QA = NULL;
    struct quadArray_* TQA = NULL;
    bool* leaders = NULL;
    int* leaderMap = NULL;
    bool* targetLeaders = NULL;
    struct reg_* RB = NULL;
    
%}

%union {
    char* text;
    int num;
}

%token '+' '-' '*' '/' '%' EQ NE LT GT LE GE
%token <text> IDEN NUMB
%token SET WHEN LOOP WHILE
%token LDST OP JCOND JUMP

%type list stmt asgn cond loop program
%type <text> atom oper expr reln bool
%type <num> M
%start program

%%

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
    : IDEN  {if(findSym($1)==NULL) yyerror("Error: Undefined variable\n");}
    | NUMB
    | expr
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

M   :   {$$ = instr;}
    ;

%%

void yyerror (char * err)
{
    printf("%s",err);
}