%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

    extern int yylex();
    extern int yylineno;
    void yyerror ( char * );

    typedef long long ll;

    // Structure for symbol (identifier and its value)
    struct symbol_ {
        char* name;
        ll val;
    };
    typedef struct symbol_* symbol;

    // Structure for symbol table (linked list of identifiers and numbers)
    struct symnode
    {   
        int type;
        union{
            struct symbol_ id;
            ll num;
        } entry;
        struct symnode *next;
    };
    typedef struct symnode* symbolTable;

    // Structure for Expression Tree (binary tree of operators and operands)
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

    symbolTable ST = NULL;                              // Global symbol table

    ll binExp(ll,ll);                                   // Binary exponentiation
    ll evalexpr(node);                                  // Evaluate expression    
    symbol createSymbol(char*, ll);                     // Create a symbol (id and its value)
    symbolTable insertTable(symbolTable, char*, ll);    // Insert/Update identifier in the symbol table
    symbolTable insertNum(symbolTable, ll);             // Insert a number in the symbol table
    ll findTable(symbolTable, char*);                   // Find the value of an identifier in the symbol table
    node createInternalNode(int, node, node);           // Create an internal node (operator) in the Expression Tree
    node createLeafId(char*, symbolTable);              // Create a leaf node (identifier) in the Expression Tree
    node createLeafNum(ll);                             // Create a leaf node (number) in the Expression Tree
    void freeTable(symbolTable);                        // Dealloc the symbol table
    void throwError(char*);                             // Print error message and exit parse environment
%}

%union {
    long long num;
    char* text;
    struct TreeNode* tree;
    struct symbol_* sym;
}

%token <num> NUM PLUS MINUS MUL DIV MOD EXPO
%token <text> ID
%token SET

%start program
%type <num> op exprstmt
%type <tree> expr arg
%type <sym> setstmt

%%

program:
            stmt program
            | stmt
            ;

stmt:
            setstmt                 {printf("Variable %s is set to %lld\n", $1->name, $1->val); free($1);}
            | exprstmt              {printf("Standalone expression evaluates to %lld\n", $1);}
            ;

setstmt:
            '(' SET ID NUM ')'      {ST = insertTable(ST, $3, $4); ST = insertNum(ST, $4); $$ = createSymbol($3, $4);}
            | '(' SET ID ID ')'     {ll val = findTable(ST,$4); ST = insertTable(ST, $3, val); $$ = createSymbol($3, val);}
            | '(' SET ID expr ')'   {ll val = evalexpr($4); ST = insertTable(ST, $3, val); $$ = createSymbol($3, val);}
            ;

exprstmt:   expr                    {$$ = evalexpr($1);}
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
    throwError(err);
}