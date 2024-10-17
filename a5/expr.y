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
    
    symbolTable ST;                                     // Global symbol table
    bool* RT;                                           // Global boolean array to check if register is free
    int MEMT;                                           // Global counter for memory offset
    int TEMP;                                           // Global counter for temporaries in memory
    struct symnode* addSymbol(char *);                  // Add symbol to symbol table
    void setId(symbolTable,char*, argtp);               // Set identifier
    int setRegId(int);                                  // Set register for mem offset
    int findId(symbolTable, char *);                    // Find identifier in symbol table
    argtp createArg(int, int);                          // Create argument node
    argtp createExpr(int, argtp, argtp, symbolTable);   // Create expression node 
    void standaloneExpr(argtp);                         // Print standalone expression
    int findFreeReg();                                  // Find first free register
    void genArgPrn(char *, argtp);                      // Generate argument string to print
    void throwError(char*);                             // Print error message and exit parse environment
    void freeSymTable(symbolTable);                     // Free symbol table
    void freeArg(argtp);                                // Free argument

%}

%union {
    int num;
    char* text;
    struct arg_* argtp;
}

%token <num> NUM EXPO '+' '-' '*' '/' '%'
%token <text> ID
%token SET

%start program
%type <num> op
%type <argtp> arg expr exprstmt
%type setstmt

%%

program
            : stmt program
            | stmt
            ;

stmt
            : setstmt                 
            | exprstmt              
            ;

setstmt
            : '(' SET ID NUM ')'        {setId(ST,$3,createArg(NUM_VAL,$4));}
            | '(' SET ID ID ')'         {setId(ST,$3,createArg(REG_IDX,setRegId(findId(ST,$4))));}
            | '(' SET ID expr ')'       {setId(ST,$3,$4);}
            ;

exprstmt    : expr                      {standaloneExpr($1);}
            ;

expr        : '(' op arg arg ')'        {$$ = createExpr($2, $3, $4, ST);}
            ;

op
            : '+'                     
            | '-'     
            | '*'      
            | '/'      
            | '%'   
            | EXPO 
            ;


arg         
            : ID                        {$$ = createArg(MEM_OFFSET, findId(ST, $1));}
            | NUM                       {$$ = createArg(NUM_VAL, $1);}                
            | expr                      {$$ = $1;}
            ;
%%

void yyerror (char * err)
{
    throwError(err);
}