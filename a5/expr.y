%{  
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <stdbool.h>

    #define RSIZE 12
    #define MEMSIZE 65536

    extern int yylex();
    extern int yylineno;
    void yyerror ( char * );

    typedef long long ll;

    // Structure for symbol (identifier and its value)
    struct symbol_ {
        char* name;
        int offset;
    };
    typedef struct symbol_* symbol;

    // Structure for symbol table (linked list of identifiers and numbers)
    struct symnode
    {   
        struct symbol_ id;
        struct symnode *next;
    };
    typedef struct symnode* symbolTable;

    struct arg_{
        enum {
            NUM_VAL, REG_IDX, MEM_OFFSET
        } type;
        int val;
    };

    typedef struct arg_* argtp;
    
    symbolTable ST = NULL;                              // Global symbol table
    bool* RT = NULL;
    int MEMT = 0;
    struct symnode* addSymbol(char *);
    symbolTable setIdNum(symbolTable,char*, int);
    symbolTable setIdId(symbolTable,char*, char*);
    symbolTable setIdExpr(symbolTable,char*, argtp);
    int setRegId(symbolTable, char*);
    int findId(symbolTable, char *);
    argtp createArg(int, int);
    argtp createExpr(int, argtp, argtp);
    void standaloneExpr(argtp);
    int findFreeReg();
    void genArgPrn(char *, argtp);
    void throwError(char*);                             // Print error message and exit parse environment

%}

%union {
    int num;
    char* text;
    struct arg_* argtp;
}

%token <num> NUM EXPO
%token <text> ID
%token SET

%start program
%type <num> op
%type <argtp> arg expr exprstmt
%type setstmt

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
            '(' SET ID NUM ')'          {ST = setIdNum(ST,$3,$4);}
            | '(' SET ID ID ')'         {ST = setIdId(ST,$3,$4);}
            | '(' SET ID expr ')'       {ST = setIdExpr(ST,$3,$4);}
            ;

exprstmt:   expr                    {standaloneExpr($1);}
            ;

expr:       '(' op arg arg ')'      {$$ = createExpr($2, $3, $4);}
            ;

op:
            '+'                     
            | '-'     
            | '*'      
            | '/'      
            | '%'   
            | EXPO 
            ;


arg:        ID                      {$$ = createArg(MEM_OFFSET, findId(ST, $1));}
            | NUM                   {$$ = createArg(NUM_VAL, $1);}                
            | expr                  {$$ = $1;}
            ;
%%

void yyerror (char * err)
{
    throwError(err);
}