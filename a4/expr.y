%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    extern int yylex();
    extern int yylineno;
    void yyerror ( char * );
    typedef long long ll;

    struct symnode
    {   
        int type;
        union{
            struct{
                char* name;
                ll val;
            } id;
            ll num;
        } entry;
        struct symnode *next;
    };
    typedef struct symnode* symbolTable;

    struct TreeNode
    {
        struct TreeNode *left;
        struct TreeNode *right;
        int type;
        union
        {
            int op;
            ll num;
            symbolTable id;
        } entry;
    };
    typedef struct TreeNode* node;

    symbolTable ST = NULL;
    ll binExp(ll,ll);
    ll evalexpr(node);
    symbolTable insertTable(symbolTable, char*, ll);
    symbolTable updateTable(symbolTable, char*, char*);
    symbolTable insertNum(symbolTable, ll);
    node createInternalNode(int, node, node);
    node createLeafId(char*, symbolTable);
    node createLeafNum(ll);
    void freeTable(symbolTable T);
%}

%union {
    long long num;
    char* text;
    struct TreeNode* tree;
}
%token <num> NUM PLUS MINUS MUL DIV MOD EXPO
%token <text> ID
%token SET

%start program
%type <num> op
%type <tree> expr arg

%%

program:
            stmt program
            | stmt
            ;

stmt:
            setstmt
            | exprstmt
            ;

setstmt:
            '(' SET ID NUM ')'      {ST = insertTable(ST, $3, $4); ST = insertNum(ST, $4);}
            | '(' SET ID ID ')'     {ST = updateTable(ST, $3, $4);}
            | '(' SET ID expr ')'   {ST = insertTable(ST, $3, evalexpr($4));}
            ;

exprstmt:   expr                    {printf("Standalone expression evaluates to %lld\n", evalexpr($1));}
            ;

expr:       '(' op arg arg ')'      {$$ = createInternalNode($2, $3, $4);}
            ;

op:
            PLUS        
            | MINUS     
            | MUL      
            | DIV      
            | MOD   
            | EXPO 
            ;


arg:        ID                      {$$ = createLeafId($1, ST);}
            | NUM                   {$$ = createLeafNum($1); ST = insertNum(ST, $1);}
            | expr
            ;
%%

void yyerror (char * err)
{
    fprintf(stderr, "***Error at line %d: %s\n", yylineno, err);
    freeTable(ST);
    exit(1);
}