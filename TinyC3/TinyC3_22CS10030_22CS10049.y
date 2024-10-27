%{	
	#include "TinyC3_22CS10030_22CS10049_translator.h"
    extern int yylex();
    extern char* yytext;
    extern int yylineno;
    void yyerror (const char *);  
%}

%union {
    char* text;
    char* op;
    int num;
    Expression* expr;
    Array* arr;
    Statement* stmt;
    Symbol* sym;
    SymbolType* symtype;
}

%token <text> FLOATING_CONSTANT INTEGER_CONSTANT CHAR_CONSTANT STRING_LITERAL
%token <sym> IDENTIFIER
%token <op> ASTERISK PLUS MINUS DIV MOD LEFT_SHIFT RIGHT_SHIFT LT GT LE GE EQ NE
%token SIZEOF EXTERN STATIC AUTO REGISTER VOID CHAR SHORT INT LONG FLOAT DOUBLE SIGNED UNSIGNED BOOL_ COMPLEX_ IMAGINARY_ CONST RESTRICT VOLATILE INLINE CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN
%token LSQPAREN RSQPAREN LPAREN RPAREN LBRACE RBRACE
%token DOT ARROW INC DEC AMPERSAND TILDE NOT XOR OR LOGICAL_OR LOGICAL_AND QUESTION COLON SEMICOLON ELLIPSIS ASSIGN MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN XOR_ASSIGN OR_ASSIGN COMMA
%token ENUM STRUCT UNION TYPEDEF HASH
%type <expr> constant expression expression_opt expression_statement primary_expression multiplicative_expression additive_expression shift_expression relational_expression equality_expression and_expression exclusive_or_expression inclusive_or_expression logical_and_expression logical_or_expression conditional_expression assignment_expression
%type <arr> postfix_expression unary_expression cast_expression
%type <stmt> statement compound_statement selection_statement iteration_statement labeled_statement jump_statement block_item block_item_list block_item_list_opt N
%type <num> argument_expression_list argument_expression_list_opt unary_operator M
%type <sym> initializer direct_declarator init_declarator declarator
%type <symtype> pointer
%type <op> relop mulop addop shiftop eqop
%type type_name initializer_list constant_expression assignment_operator declaration declaration_specifiers declaration_specifiers_opt init_declarator_list init_declarator_list_opt storage_class_specifier type_specifier type_qualifier function_specifier specifier_qualifier_list specifier_qualifier_list_opt type_qualifier_list type_qualifier_list_opt parameter_type_list identifier_list parameter_list parameter_declaration designation designation_opt designator_list designator translation_unit external_declaration function_definition declaration_list declaration_list_opt tinyC_start

%nonassoc PSEUDO_ELSE
%nonassoc ELSE

%start tinyC_start

%%

/* Expressions */

primary_expression
        : IDENTIFIER
        { 
            $$ = new Expression($1);
            $$->type = Expression::NONBOOL;
        }
        | constant                      {$$ = $1;}
        | STRING_LITERAL
        {
            $$ = new Expression(gentemp(TYPE_PTR, $1));
            $$->type = Expression::NONBOOL;
        }
        | LPAREN expression RPAREN      {$$ = $2; /* Simple Assignment */}
        ;

constant
        : INTEGER_CONSTANT
        {
            $$ = new Expression(gentemp(TYPE_INT, $1));
            emit("=", $$->symbol->name, $1);
        }
        | FLOATING_CONSTANT
        {
            $$ = new Expression(gentemp(TYPE_FLOAT, $1));
            emit("=", $$->symbol->name, $1);
        }
        | CHAR_CONSTANT
        {
            $$ = new Expression(gentemp(TYPE_CHAR, $1));
            emit("=", $$->symbol->name, $1);
        }
        ;

postfix_expression
        : primary_expression
        {
            $$ = new Array($1->symbol);
            $$->loca = $$->symbol;
            $$->childType = $1->symbol->type;
        }
        | postfix_expression LSQPAREN expression RSQPAREN
        {
            $$ = new Array($1->symbol);
            $$->loca = gentemp(TYPE_INT);
            $$->childType = $1->childType->arrType;
            $$->type = Array::ARRAY;

            if($1->type == Array::ARRAY){
                Symbol *tempSym = gentemp(TYPE_INT);
                int sz = $$->childType->getSize();
                emit("*", tempSym->name, $3->symbol->name, to_string(sz));
                emit("+", $$->loca->name, $1->loca->name, tempSym->name);
            }
            else{
                int sz = $$->childType->getSize();
                emit("*", $$->loca->name, $3->symbol->name, to_string(sz));
            }
        }
        | postfix_expression LPAREN argument_expression_list_opt RPAREN
        {
            $$ = new Array(gentemp($1->symbol->type->type));
            emit("call", $$->symbol->name, $1->symbol->name, to_string($3));
        }
        | postfix_expression INC
        {
            $$ = new Array(gentemp($1->symbol->type->type));
            emit("=", $$->symbol->name, $1->symbol->name);
            emit("+", $1->symbol->name, $1->symbol->name, "1");
        }
        | postfix_expression DEC
        {
            $$ = new Array(gentemp($1->symbol->type->type));
            emit("=", $$->symbol->name, $1->symbol->name);
            emit("-", $1->symbol->name, $1->symbol->name, "1");
        }
        | postfix_expression DOT IDENTIFIER                             { /*Ignore*/ }
        | postfix_expression ARROW IDENTIFIER                           { /*Ignore*/ }
        | LPAREN type_name RPAREN LBRACE initializer_list RBRACE        { /*Ignore*/ }
        | LPAREN type_name RPAREN LBRACE initializer_list COMMA RBRACE  { /*Ignore*/ }
        ;

argument_expression_list
        : assignment_expression
        { 
            $$ = 1;
            emit("param",$1->symbol->name);
        }
        | argument_expression_list COMMA assignment_expression
        {
            $$ = 1 + $1;
            emit("param",$3->symbol->name);
        }
        ;

argument_expression_list_opt:
        argument_expression_list        {$$ = $1; /* Copy no. of arguments */}
        | {/* Empty */}                 {$$ = 0; /* No arguments */}
        ;


unary_expression:
        postfix_expression                      {$$ = $1;}
        | INC unary_expression
        {
            $$ = $2;
            emit("+", $2->symbol->name, $2->symbol->name, "1");
        }
        | DEC unary_expression
        {
            $$ = $2;
            emit("-", $2->symbol->name, $2->symbol->name, "1");
        }
        | unary_operator cast_expression
        {
            switch($1){
                case AMPERSAND:
                    $$ = new Array(gentemp(TYPE_PTR));
                    $$->symbol->type->arrType = $2->symbol->type;
                    emit("= &", $$->symbol->name, $2->symbol->name);
                    break;
                case ASTERISK:
                    $$ = new Array($2->symbol);
                    $$->loca = gentemp($2->loca->type->arrType->type);
                    $$->loca->type->arrType = $2->loca->type->arrType->arrType;
                    $$->type = Array::POINTER;
                    emit("= *", $$->loca->name, $2->loca->name);
                    break;
                case PLUS:
                    $$ = $2;
                    break;
                case MINUS:
                    $$ = new Array(gentemp($2->symbol->type->type));
                    emit("= -", $$->symbol->name, $2->symbol->name);
                    break;
                case TILDE:
                    $$ = new Array(gentemp($2->symbol->type->type));
                    emit("= ~", $$->symbol->name, $2->symbol->name);
                    break;
                case NOT:
                    $$ = new Array(gentemp($2->symbol->type->type));
                    emit("= !", $$->symbol->name, $2->symbol->name);
                    break;
            }
        }
        | SIZEOF unary_expression               { /*Ignore*/ }
        | SIZEOF LPAREN type_name RPAREN        { /*Ignore*/ }
        ;

unary_operator
        : AMPERSAND     {$$ = AMPERSAND;}
        | ASTERISK      {$$ = ASTERISK;}
        | PLUS          {$$ = PLUS;}
        | MINUS         {$$ = MINUS;}
        | TILDE         {$$ = TILDE;}
        | NOT           {$$ = NOT;}
        ;

cast_expression
        : unary_expression                        {$$ = $1;}
        | LPAREN type_name RPAREN cast_expression {$$ = new Array($4->symbol->convertType(parseEnv->currType));}
        ;

multiplicative_expression
        : cast_expression
        {
            if($1->type == Array::ARRAY){
                SymbolType *baseType = $1->symbol->type;
                while(baseType->arrType != NULL) baseType = baseType->arrType;
                $$ = new Expression(gentemp(baseType->type));
                emit("=[]", $$->symbol->name, $1->symbol->name, $1->loca->name);
            }
            else if($1->type == Array::POINTER){
                $$ = new Expression($1->loca);
            }
            else{
                $$ = new Expression($1->symbol);
            }
        }
        | multiplicative_expression mulop cast_expression
        {
            SymbolType *baseType = $1->symbol->type;
            while(baseType->arrType != NULL)
                baseType = baseType->arrType;

            Symbol *temp;

            if($3->type == Array::ARRAY){
                temp = gentemp(baseType->type);
                emit("=[]", temp->name, $3->symbol->name, $3->loca->name);
            } 
            else if($3->type == Array::POINTER){
                temp = $3->loca;
            }
            else{
                temp = $3->symbol;
            }

            if(typeCheck($1->symbol, temp)){
                $$ = new Expression();
                $$->symbol = gentemp($1->symbol->type->type);
                emit($2, $$->symbol->name, $1->symbol->name, temp->name);
            } 
            else{
                yyerror("Type mismatch!");
            }
        }
        ;

mulop
        : ASTERISK 
        | DIV      
        | MOD      
        ;

additive_expression
        : multiplicative_expression                             {$$ = $1; /* Simple Assignment */}
        | additive_expression addop multiplicative_expression
        {   
            if(typeCheck($1->symbol, $3->symbol)) {
                $$ = new Expression(gentemp($1->symbol->type->type));
                emit($2, $$->symbol->name, $1->symbol->name, $3->symbol->name);
            } 
            else {
                yyerror("Type mismatch!");
            }
        }
        ;

addop
        : PLUS 
        | MINUS
        ;

shift_expression
        : additive_expression                                   {$$ = $1; /* Simple Assignment */}
        | shift_expression shiftop additive_expression
        { 
            if($3->symbol->type->type == TYPE_INT) {
                $$ = new Expression(gentemp(TYPE_INT));
                emit($2, $$->symbol->name, $1->symbol->name, $3->symbol->name);
            } 
            else {
                yyerror("<<: Type mismatch!");
            }
        }
        ;

shiftop
        : LEFT_SHIFT 
        | RIGHT_SHIFT
        ;

relational_expression
        : shift_expression                              {$$ = $1; /* Simple Assignment */}
        | relational_expression relop shift_expression
        {   
            if(typeCheck($1->symbol, $3->symbol)) {
                $$ = new Expression();
                $$->type = Expression::BOOL;
                $$->truelist = makelist(nextinstr());
                $$->falselist = makelist(nextinstr() + 1);
                emit($2, "", $1->symbol->name, $3->symbol->name);
                emit("goto", "");
            } 
            else {
                yyerror("Type mismatch!");
            }
        }
        ;

relop
        : LT
        | GT
        | LE
        | GE
        ;

equality_expression
        : relational_expression                         {$$ = $1; /* Simple Assignment */}
        | equality_expression eqop relational_expression
        { 
            if(typeCheck($1->symbol, $3->symbol)) {
                $1->convtoInt();
                $3->convtoInt();

                $$ = new Expression();
                $$->type = Expression::BOOL;
                $$->truelist = makelist(nextinstr());
                $$->falselist = makelist(nextinstr() + 1);

                emit($2, "", $1->symbol->name, $3->symbol->name);
                emit("goto", "");

            } 
            else {
                yyerror("Type mismatch!");
            }
        }
        ;

eqop
        : EQ
        | NE
        ;

and_expression
        : equality_expression                           {$$ = $1; /* Simple Assignment */}
        | and_expression AMPERSAND equality_expression
        { 
            $1->convtoInt();
            $3->convtoInt();

            $$ = new Expression();
            $$->type = Expression::NONBOOL;
            $$->symbol = gentemp(TYPE_INT);

            emit("&", $$->symbol->name, $1->symbol->name, $3->symbol->name);
        }
        ;

exclusive_or_expression
        : and_expression                                {$$ = $1; /* Simple Assignment */}
        | exclusive_or_expression XOR and_expression
        { 
            $1->convtoInt();
            $3->convtoInt();

            $$ = new Expression();
            $$->type = Expression::NONBOOL;
            $$->symbol = gentemp(TYPE_INT);

            emit("^", $$->symbol->name, $1->symbol->name, $3->symbol->name);
        }
        ;

inclusive_or_expression
        : exclusive_or_expression                               {$$ = $1; /* Simple Assignment */}
        | inclusive_or_expression OR exclusive_or_expression
        { 
            $1->convtoInt();
            $3->convtoInt();

            $$ = new Expression();
            $$->type = Expression::NONBOOL;
            $$->symbol = gentemp(TYPE_INT);

            emit("|", $$->symbol->name, $1->symbol->name, $3->symbol->name);
        }
        ;

logical_and_expression
        : inclusive_or_expression                                           {$$ = $1; /* Simple Assignment */}
        | logical_and_expression LOGICAL_AND M inclusive_or_expression
        { 
            $1->convtoBool();
            $4->convtoBool();

            $$ = new Expression();
            $$->type = Expression::BOOL;

            backpatch($1->truelist, $3);
            $$->truelist = $4->truelist;
            $$->falselist = merge($1->falselist, $4->falselist);
        }
        ;

logical_or_expression
        : logical_and_expression                                            {$$ = $1; /* Simple Assignment */}
        | logical_or_expression LOGICAL_OR M logical_and_expression
        {  
            $1->convtoBool();
            $4->convtoBool();

            $$ = new Expression();
            $$->type = Expression::BOOL;

            backpatch($1->falselist, $3);
            $$->truelist = merge($1->truelist, $4->truelist);
            $$->falselist = $4->falselist;
        }
        ;

conditional_expression
        : logical_or_expression                                                             {$$ = $1; /* Simple Assignment */}
        | logical_or_expression N QUESTION M expression N COLON M conditional_expression
        { 
            $$->symbol = gentemp($5->symbol->type->type);
            emit("=", $$->symbol->name, $9->symbol->name);

            list<int> l = makelist(nextinstr());
            emit("goto", "");

            backpatch($6->nextlist, nextinstr());
            emit("=", $$->symbol->name, $5->symbol->name);

            l = merge(l, makelist(nextinstr()));
            emit("goto", "");

            backpatch($2->nextlist, nextinstr());

            $1->convtoBool();

            backpatch($1->truelist, $4);
            backpatch($1->falselist, $8);

            backpatch(l, nextinstr());
        }
        ;

assignment_expression
        : conditional_expression                                        {$$ = $1; /* Simple Assignment */}
        | unary_expression assignment_operator assignment_expression
        {   
            switch($1->type){
                case Array::ARRAY:
                    $3->symbol = $3->symbol->convertType($1->childType->type);
                    emit("[]=", $1->symbol->name, $1->loca->name, $3->symbol->name);
                    break;
                case Array::POINTER:
                    $3->symbol = $3->symbol->convertType($1->loca->type->type);
                    emit("*=", $1->loca->name, $3->symbol->name);
                    break;
                default:
                    $3->symbol = $3->symbol->convertType($1->symbol->type->type);
                    emit("=", $1->symbol->name, $3->symbol->name);
                    break;
            }
            
            $$ = $3;
        }
        ;

assignment_operator
        : ASSIGN        { }
        | MUL_ASSIGN    { /*Ignore*/ }
        | DIV_ASSIGN    { /*Ignore*/ }
        | MOD_ASSIGN    { /*Ignore*/ }
        | ADD_ASSIGN    { /*Ignore*/ }
        | SUB_ASSIGN    { /*Ignore*/ }
        | LEFT_ASSIGN   { /*Ignore*/ }
        | RIGHT_ASSIGN  { /*Ignore*/ }
        | AND_ASSIGN    { /*Ignore*/ }
        | XOR_ASSIGN    { /*Ignore*/ }
        | OR_ASSIGN     { /*Ignore*/ }
        ;

expression
        : assignment_expression                         {$$ = $1;}
        | expression COMMA assignment_expression        { /*Ignore*/ }
        ;

constant_expression
        : conditional_expression     { /*Ignore*/ }
        ;
    
/* Declarations */

declaration
        : declaration_specifiers init_declarator_list_opt SEMICOLON       {  /*Ignore*/ }
        ;

declaration_specifiers
        : storage_class_specifier declaration_specifiers_opt    { /*Ignore*/ }
        | type_specifier declaration_specifiers_opt             { /*Ignore*/ }
        | type_qualifier declaration_specifiers_opt             { /*Ignore*/ }
        | function_specifier declaration_specifiers_opt         { /*Ignore*/ }
        ;

declaration_specifiers_opt
        : declaration_specifiers        { /*Ignore*/ }
        | {/* Empty */}                 { /*Ignore*/ }
        ;

init_declarator_list
        : init_declarator                               { /*Ignore*/ }
        | init_declarator_list COMMA init_declarator    { /*Ignore*/ }
        ;

init_declarator_list_opt
        : init_declarator_list          { /*Ignore*/ }
        | {/* Empty */}                 { /*Ignore*/ }
        ;

init_declarator
        : declarator                            {$$ = $1;}
        | declarator ASSIGN initializer
        {
            if($3->initial_value != "-") $1->initial_value = $3->initial_value;
            emit("=", $1->name, $3->name);
        }
        ;

storage_class_specifier
        : EXTERN        { /*Ignore*/ }
        | STATIC        { /*Ignore*/ }
        | AUTO          { /*Ignore*/ }
        | REGISTER      { /*Ignore*/ }
        ;

type_specifier
        : VOID          { parseEnv->currType = TYPE_VOID; }
        | CHAR          { parseEnv->currType = TYPE_CHAR; }
        | INT           { parseEnv->currType = TYPE_INT; }
        | FLOAT         { parseEnv->currType = TYPE_FLOAT; }
        | LONG          {  /*Ignore*/ }
        | SHORT         {  /*Ignore*/ }
        | DOUBLE        {  /*Ignore*/ }
        | SIGNED        {  /*Ignore*/ }
        | UNSIGNED      {  /*Ignore*/ }
        | BOOL_         {  /*Ignore*/ }
        | COMPLEX_      {  /*Ignore*/ }
        | IMAGINARY_    {  /*Ignore*/ }
        ;

specifier_qualifier_list
        : type_specifier specifier_qualifier_list_opt   { /*Ignore*/ }
        | type_qualifier specifier_qualifier_list_opt   { /*Ignore*/ }
        ;
        
specifier_qualifier_list_opt
        : specifier_qualifier_list      { /*Ignore*/ }
        | {/* Empty */}                 { /*Ignore*/ }
        ;

type_qualifier
        : CONST         { /*Ignore*/ }
        | RESTRICT      { /*Ignore*/ }
        | VOLATILE      { /*Ignore*/ }
        ;

function_specifier
        : INLINE        { /*Ignore*/ }
        ;

declarator
        : pointer direct_declarator
        {
            SymbolType *temp = $1;
            while(temp->arrType != NULL) 
                temp = temp->arrType;

            temp->arrType = $2->type;
            $$ = $2->update($1);
        }
		| direct_declarator             { /*Ignore*/ }
        ;

direct_declarator
        : IDENTIFIER
        {
            $$ = $1->update(new SymbolType(parseEnv->currType));
            parseEnv->currSymbol = $$;
        }
        | LPAREN declarator RPAREN                                          {$$ = $2;}
		| direct_declarator LSQPAREN assignment_expression RSQPAREN
        {             
            SymbolType *temp = $1->type, *prev = NULL;
            while(temp->type == TYPE_ARRAY) { 
                prev = temp;
                temp = temp->arrType;
            }

            if(prev != NULL) { 
                prev->arrType =  new SymbolType(TYPE_ARRAY, temp, atoi($3->symbol->initial_value.c_str()));	
                $$ = $1->update($1->type);
            }
            else { 
                SymbolType* new_type = new SymbolType(TYPE_ARRAY, $1->type, atoi($3->symbol->initial_value.c_str()));
                $$ = $1->update(new_type);
            }
        }
		| direct_declarator LSQPAREN RSQPAREN
        {
            SymbolType *temp = $1->type, *prev = NULL;
            while(temp->type == TYPE_ARRAY) { 
                prev = temp;
                temp = temp->arrType;
            }

            if(prev != NULL) { 
                prev->arrType =  new SymbolType(TYPE_ARRAY, temp, 0);	
                $$ = $1->update($1->type);
            }
            else { 
                SymbolType* new_type = new SymbolType(TYPE_ARRAY, $1->type, 0);
                $$ = $1->update(new_type);
            }
        }
        | direct_declarator LPAREN CT parameter_type_list RPAREN
        { 
            parseEnv->STstack.top()->name = $1->name;

            if($1->type->type != TYPE_VOID) {
                Symbol* s = parseEnv->STstack.top()->lookup("return");
                s->update($1->type);
            }

            $1->nestedTable = parseEnv->STstack.top();
            // parseEnv->STstack.top()->parent = globalST;

            // changeTable(globalST);
            parseEnv->STstack.pop();
            parseEnv->currSymbol = $$;
        }
		| direct_declarator LPAREN CT RPAREN
        { 
            parseEnv->STstack.top()->name = $1->name;

            if($1->type->type != TYPE_VOID) {
                Symbol* s = parseEnv->STstack.top()->lookup("return");
                s->update($1->type);
            }

            $1->nestedTable = parseEnv->STstack.top();
            // parseEnv->STstack.top()->parent = globalST;

            // changeTable(globalST);
            parseEnv->STstack.pop();
            parseEnv->currSymbol = $$;
        }
        | direct_declarator LSQPAREN type_qualifier_list assignment_expression RSQPAREN 	            { /*Ignore*/ }
		| direct_declarator LSQPAREN type_qualifier_list RSQPAREN        	                            { /*Ignore*/ }
        | direct_declarator LSQPAREN STATIC type_qualifier_list assignment_expression RSQPAREN          { /*Ignore*/ }
        | direct_declarator LSQPAREN STATIC assignment_expression RSQPAREN                              { /*Ignore*/ }
        | direct_declarator LSQPAREN type_qualifier_list STATIC assignment_expression RSQPAREN          { /*Ignore*/ }
        | direct_declarator LSQPAREN type_qualifier_list ASTERISK RSQPAREN                              { /*Ignore*/ }
        | direct_declarator LSQPAREN ASTERISK RSQPAREN                                                  { /*Ignore*/ }
        | direct_declarator LPAREN identifier_list RPAREN          	                                    { /*Ignore*/ }
        ;

pointer
        : ASTERISK type_qualifier_list_opt              { $$ = new SymbolType(TYPE_PTR); }
        | ASTERISK type_qualifier_list_opt pointer      { $$ = new SymbolType(TYPE_PTR, $3); }
        ;

type_qualifier_list
        : type_qualifier                        { /*Ignore*/ }
        | type_qualifier_list type_qualifier    { /*Ignore*/ }
        ;

type_qualifier_list_opt
        : type_qualifier_list           { /*Ignore*/ }
        | {/* Empty */}                 { /*Ignore*/ }
        ;

parameter_type_list
        : parameter_list                        { /*Ignore*/ }
        | parameter_list COMMA ELLIPSIS         { /*Ignore*/ }
        ;

parameter_list
        : parameter_declaration                         { /*Ignore*/ }
        | parameter_list COMMA parameter_declaration    { /*Ignore*/ }
        ;

parameter_declaration
        : declaration_specifiers declarator     { /*Ignore*/ }
        | declaration_specifiers                { /*Ignore*/ }
        ;

identifier_list
        : IDENTIFIER                            { /*Ignore*/ }
        | identifier_list COMMA IDENTIFIER      { /*Ignore*/ }
        ;

type_name
        : specifier_qualifier_list              { /*Ignore*/ }
        ;

initializer
        : assignment_expression                 { $$ = $1->symbol; /*Simple Assignment*/}
        | LBRACE initializer_list RBRACE        { /*Ignore*/ }
        | LBRACE initializer_list COMMA RBRACE  { /*Ignore*/ }
        ;

initializer_list
        : designation_opt initializer                           { /*Ignore*/ }
        | initializer_list COMMA designation_opt initializer    { /*Ignore*/ }
        ;

designation
        : designator_list ASSIGN                  { /*Ignore*/ }
        ;

designation_opt
        : designation                   { /*Ignore*/ }
        | {/* Empty */}                 { /*Ignore*/ }
        ;

designator_list
        : designator                            { /*Ignore*/ }
        | designator_list designator            { /*Ignore*/ }
        ;

designator
        : LSQPAREN constant_expression RSQPAREN     { /*Ignore*/ }
        | DOT IDENTIFIER                            { /*Ignore*/ }
        ;

/* Statements */

statement
        : labeled_statement             { /*Ignore*/ }
        | compound_statement            {$$ = $1; /*Simple Assignment*/}
        | expression_statement
        {
            $$ = new Statement();
            $$->nextlist = $1->nextlist;
        }
        | selection_statement           {$$ = $1; /*Simple Assignment*/}
        | iteration_statement           {$$ = $1; /*Simple Assignment*/}
        | jump_statement                {$$ = $1; /*Simple Assignment*/}
        ;

labeled_statement
        : IDENTIFIER COLON statement                    { /*Ignore*/ }
        | CASE constant_expression COLON statement      { /*Ignore*/ }
        | DEFAULT COLON statement                       { /*Ignore*/ }
        ;

compound_statement
        : LBRACE CB CT block_item_list_opt RBRACE
        {
            $$ = $4;
            // changeTable(parseEnv->STstack.top()->parent);
            parseEnv->STstack.pop();
        }
        ;

block_item_list
        : block_item                        {$$ = $1; /*Simple Assignment*/}
        | block_item_list M block_item
        {
            $$ = $3;
            backpatch($1->nextlist, $2);
        }
        ;

block_item_list_opt
        : block_item_list               {$$ = $1; /*Simple Assignment*/}
        | {/* Empty */}                 {$$ = new Statement();}
        ;

block_item
        : declaration       {$$ = new Statement();}
        | statement         {$$ = $1; /*Simple Assignment*/}
        ;

expression_statement
        : expression_opt SEMICOLON      {$$ = $1;}
        ;

expression_opt
        : expression                    {$$ = $1;}
        | {/* Empty */}                 {$$ = new Expression();}

selection_statement
        : IF LPAREN expression RPAREN M statement N  %prec PSEUDO_ELSE
        { 
            $$ = new Statement();

            $3->convtoBool();

            backpatch($3->truelist, $5);

            $$->nextlist = merge($3->falselist, merge($6->nextlist, $7->nextlist));
        }
        | IF LPAREN expression RPAREN M statement N ELSE M statement
        { 
            $$ = new Statement();

            $3->convtoBool();

            backpatch($3->truelist, $5);
            backpatch($3->falselist, $9);

            $$->nextlist = merge($10->nextlist, merge($6->nextlist, $7->nextlist));
        }
        | SWITCH LPAREN expression RPAREN statement                             { /*Ignore*/ }
        ;

iteration_statement
        : WHILE M LPAREN expression RPAREN M statement
        { 
            $$ = new Statement();

            $4->convtoBool();

            backpatch($7->nextlist, $2);
            backpatch($4->truelist, $6);

            $$->nextlist = $4->falselist;

            emit("goto", to_string($2));
        }
        | DO M statement M WHILE LPAREN expression RPAREN SEMICOLON
        { 
            $$ = new Statement();

            $7->convtoBool();

            backpatch($7->truelist, $2);
            backpatch($3->nextlist, $4);

            $$->nextlist = $7->falselist;
        }

        | FOR LPAREN expression_opt SEMICOLON M expression_opt SEMICOLON M expression_opt N RPAREN M statement
        { 
            $$ = new Statement();

            $6->convtoBool();

            backpatch($6->truelist, $12);
            backpatch($10->nextlist, $5);
            backpatch($13->nextlist, $8);

            emit("goto", to_string($8));

            $$->nextlist = $6->falselist;
        }
        | FOR LPAREN declaration expression_opt SEMICOLON expression_opt RPAREN statement        {/*Ignore*/}
        ;

jump_statement
        : GOTO IDENTIFIER SEMICOLON             { /*Ignore*/ }
        | CONTINUE SEMICOLON                    { /*New statement*/}
        | BREAK SEMICOLON                       { /*New statement*/}
        | RETURN expression_opt SEMICOLON
        {   
            $$ = new Statement();
            emit("return",($2->symbol == NULL) ? "" : $2->symbol->name);
        }
        ;

/* External Definitions */

translation_unit
        : external_declaration                  { /*Ignore*/ }
        | translation_unit external_declaration { /*Ignore*/ }
        ;

external_declaration
        : function_definition   { /*Ignore*/ }
        | declaration           { /*Ignore*/ }
        ;

function_definition
        : declaration_specifiers declarator declaration_list_opt CT LBRACE block_item_list_opt RBRACE
        { 
            parseEnv->blockCount = 0;
            $2->type->type = TYPE_FUNC;
            // changeTable(globalST);
            parseEnv->STstack.pop();
        }
        ;

declaration_list
        : declaration                   { /*Ignore*/ }
        | declaration_list declaration  { /*Ignore*/ }
        ;

declaration_list_opt
        : declaration_list              { /*Ignore*/ }
        | {/* Empty */}                 { /*Ignore*/ }
        ;


/* New Non-Terminals */

M   :  { $$ = nextinstr(); }
    ;

N   : 
    {
        $$ = new Statement();
        $$->nextlist = makelist(nextinstr());
        emit("goto", "");
    }
    ;

CT  : 
    {
        if(parseEnv->currSymbol->nestedTable == NULL) {
            // changeTable(new SymbolTable(""));
            SymbolTable *st = new SymbolTable("");
            st->parent = parseEnv->STstack.top();
            parseEnv->STstack.push(st);
        }
        else {
            // changeTable(parseEnv->currSymbol->nestedTable);
            // emit("label", parseEnv->STstack.top()->name);
            parseEnv->currSymbol->nestedTable->parent = parseEnv->STstack.top();
            parseEnv->STstack.push(parseEnv->currSymbol->nestedTable);
            emit("label",parseEnv->STstack.top()->name);
        }
    }
    ;

CB  : 
    {
        string name = parseEnv->STstack.top()->name + "_" + to_string(parseEnv->blockCount++);
        Symbol *s = parseEnv->STstack.top()->lookup(name);
        s->nestedTable = new SymbolTable(name, parseEnv->STstack.top());
        s->type = new SymbolType(TYPE_BLOCK);
        parseEnv->currSymbol = s;
    } 
    ;

/* Dummy Start */

tinyC_start:
        translation_unit        { /*Ignore*/ }
        ;

%%

void yyerror(const char* s) {
    printf("ERROR [Line %d] : %s, unable to parse : %s\n", yylineno, s, yytext);
}