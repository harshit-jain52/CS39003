%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
	#include <stdarg.h>

    extern int yylex();
    extern int yylineno;
    void yyerror ( char * );

    typedef enum nodeType{
        S_NODE,
        P_NODE,
        T_NODE,
        X_NODE,
        N_NODE,
        M_NODE,
        TERMINAL
    } NT;

    typedef struct parseTreeNode{
        enum nodeType type;
        int inh, val, ruleno, sz;
        struct parseTreeNode** children;
    } parseTreeNode;

    struct parseTreeNode* root;

    parseTreeNode* createNode(NT, int, int, ...);
    parseTreeNode* createLeaf(char);
    void throwError(char*);
%}

%union{
    struct parseTreeNode* node;
    char d;
}

%token VAR OP BIN NEWLINE
%token <d> DIG
%type <node> S P T X N M POLY_S

%start POLY_S

%%

POLY_S
    : S             {root = $1;}
    ;

S
    : P             {$$ = createNode(S_NODE, 1, 1, $1);}
    | '+' P         {$$ = createNode(S_NODE, 2, 2, createLeaf('+'), $2);}
    | '-' P         {$$ = createNode(S_NODE, 3, 2, createLeaf('-'), $2);}
    ;

P
    : T             {$$ = createNode(P_NODE, 1, 1, $1);}
    | T '+' P       {$$ = createNode(P_NODE, 2, 3, $1, createLeaf('+'), $3);}
    | T '-' P       {$$ = createNode(P_NODE, 3, 3, $1, createLeaf('-'), $3);}
    ;

T
    : '1'           {$$ = createNode(T_NODE, 1, 1, createLeaf('1'));}
    | N             {$$ = createNode(T_NODE, 2, 1, $1);}
    | X             {$$ = createNode(T_NODE, 3, 1, $1);}
    | N X           {$$ = createNode(T_NODE, 4, 2, $1, $2);}
    ;

X
    : 'x'           {$$ = createNode(X_NODE, 1, 1, createLeaf('x'));}
    | 'x' '^' N     {$$ = createNode(X_NODE, 2, 3, createLeaf('x'), createLeaf('^'), $3);}
    ;

N
    : DIG           {$$ = createNode(N_NODE, 1, 1, createLeaf($1));}
    | '1' M         {$$ = createNode(N_NODE, 2, 2, createLeaf('1'), $2);}
    | DIG M         {$$ = createNode(N_NODE, 3, 2, createLeaf($1), $2);}
    ;

M
    : '0'           {$$ = createNode(M_NODE, 1, 1, createLeaf('0'));}
    | '1'           {$$ = createNode(M_NODE, 2, 1, createLeaf('1'));}
    | DIG           {$$ = createNode(M_NODE, 3, 1, createLeaf($1));}
    | '0' M         {$$ = createNode(M_NODE, 4, 2, createLeaf('0'), $2);}
    | '1' M         {$$ = createNode(M_NODE, 5, 2, createLeaf('1'), $2);}
    | DIG M         {$$ = createNode(M_NODE, 6, 2, createLeaf($1), $2);}
    ;

%%

void yyerror (char * err){
    throwError(err);
}