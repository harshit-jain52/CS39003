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

    extern int yylex();
    extern int yylineno;
    void yyerror ( char * );

    void emit(int, char*, char*, char*, char*);
    void backpatch(int, int);
    void printQuads();
    void identifyLeaders();
    
    int tmpno=0;
    int instr=0;
    struct quadArray_* QA = NULL;
    bool* leaders = NULL;
    
%}

%union {
    char* text;
    int num;
}

%token '+' '-' '*' '/' '%' EQ NE LT GT LE GE
%token <text> IDEN NUMB
%token SET WHEN LOOP WHILE

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