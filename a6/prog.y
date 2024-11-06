%{  
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <stdbool.h>

    typedef struct quad_{
        int type, label;
        char *op, *arg1, *arg2, *res;
    } quad;

    typedef struct quadArray_{
        struct quad_* q;
        struct quadArray_* next;
    } quadArray;

    typedef struct boolExp_{
        char *arg1, *arg2, *op;
    } boolExp;

    extern int yylex();
    extern int yylineno;
    void yyerror ( char * );
    void printInstrNum();
    void emit(int, char*, char*, char*, char*);
    void backpatch(int, int);


    int tmpno=0;
    int instr=0;
    struct quadArray_* QA = NULL;
    
%}

%union {
    char* text;
    struct boolExp_* boole;
    int num;
}

%token '+' '-' '*' '/' '%' EQ NE LT GT LE GE
%token <text> IDEN NUMB
%token SET WHEN LOOP WHILE

%type list stmt asgn cond loop
%type <text> atom oper expr reln
%type <boole> bool
%type <num> M
%start list

%%
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
    : '(' SET IDEN atom ')'         {emit(EQ,NULL,$4,NULL,$3);}
    ;

cond
    : '(' WHEN bool {emit(WHEN,$3->op,$3->arg1,$3->arg2,NULL);} M list ')' {backpatch($5,instr+1);}
    ;

loop
    : '(' LOOP WHILE bool {emit(WHEN,$4->op,$4->arg1,$4->arg2,NULL);} M list ')'
    {
        emit(WHILE,NULL,NULL,NULL,NULL);
        backpatch($6,instr+1);
        backpatch(instr,$6);
    }
    ;

expr
    : '(' oper atom atom ')'
    {
        $$ = (char*)malloc(10*sizeof(char));
        sprintf($$,"$%d",++tmpno);
        emit(EQ, $2, $3, $4, $$);
    }
    ;

bool
    : '(' reln atom atom ')'
    {
        $$ = (struct boolExp_*)malloc(sizeof(struct boolExp_));
        $$->op = strdup($2);
        $$->arg1 = strdup($3);
        $$->arg2 = strdup($4);
    }
    ;

atom
    : IDEN
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

M   : {$$ = instr;}
    ;

%%

void yyerror (char * err)
{
    printf("%s",err);
}