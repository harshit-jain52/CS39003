%{	
	#include <stdio.h>
	#include <stdlib.h>
	#include <stdarg.h>

    extern int yylex();
    extern int yylineno;
    void yyerror ( char * );  

%}

%union {
    char* text;
	struct parse_tree_node* node;
}

%token <text> IDENTIFIER FLOATING_CONSTANT INTEGER_CONSTANT CHAR_CONSTANT STRING_LITERAL
%token SIZEOF EXTERN STATIC AUTO REGISTER VOID CHAR SHORT INT LONG FLOAT DOUBLE SIGNED UNSIGNED BOOL_ COMPLEX_ IMAGINARY_ CONST RESTRICT VOLATILE INLINE CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN
%token LSQPAREN RSQPAREN LPAREN RPAREN LBRACE RBRACE
%token DOT ARROW INC DEC AMPERSAND ASTERISK PLUS MINUS TILDE NOT DIV MOD LEFT_SHIFT RIGHT_SHIFT LT GT LE GE EQ NE XOR OR LOGICAL_OR LOGICAL_AND QUESTION COLON SEMICOLON ELLIPSIS ASSIGN MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN XOR_ASSIGN OR_ASSIGN COMMA
%token ENUM STRUCT UNION TYPEDEF HASH
%type <node> primary_expression expression postfix_expression argument_expression_list argument_expression_list_opt type_name initializer_list assignment_expression unary_expression cast_expression multiplicative_expression additive_expression shift_expression relational_expression equality_expression and_expression exclusive_or_expression inclusive_or_expression logical_and_expression logical_or_expression conditional_expression constant_expression
%type <node> unary_operator assignment_operator
%type <node> declaration declaration_specifiers declaration_specifiers_opt init_declarator_list init_declarator_list_opt storage_class_specifier type_specifier type_qualifier function_specifier init_declarator declarator initializer specifier_qualifier_list specifier_qualifier_list_opt pointer direct_declarator type_qualifier_list type_qualifier_list_opt parameter_type_list identifier_list parameter_list parameter_declaration designation designation_opt designator_list designator
%type <node> statement labeled_statement compound_statement expression_statement selection_statement iteration_statement jump_statement block_item block_item_list block_item_list_opt expression_opt
%type <node> translation_unit external_declaration function_definition declaration_list declaration_list_opt tinyC_start M N
%type <text> constant
%nonassoc PSEUDO_ELSE
%nonassoc ELSE

%start tinyC_start

%%

/* Expressions */

primary_expression:
        IDENTIFIER                      { }
        | constant                      { }
        | STRING_LITERAL                { }
        | LPAREN expression RPAREN      {$$ = $2; /* Simple Assignment */}
        ;

constant:
        INTEGER_CONSTANT                { }
        | FLOATING_CONSTANT             { }
        | CHAR_CONSTANT                 { }
        ;

postfix_expression:
        primary_expression                                              { }
        | postfix_expression LSQPAREN expression RSQPAREN               { /* Array Declaration */ }
        | postfix_expression LPAREN argument_expression_list_opt RPAREN { /* Function Call */ }
        | postfix_expression INC                                        { /* Add 1 */}
        | postfix_expression DEC                                        { /* Subtract 1 */}
        | postfix_expression DOT IDENTIFIER                             { /*Ignore*/ }
        | postfix_expression ARROW IDENTIFIER                           { /*Ignore*/ }
        | LPAREN type_name RPAREN LBRACE initializer_list RBRACE        { /*Ignore*/ }
        | LPAREN type_name RPAREN LBRACE initializer_list COMMA RBRACE  { /*Ignore*/ }
        ;

argument_expression_list:
        assignment_expression                                           { /* 1 argument */}
        | argument_expression_list COMMA assignment_expression          { /* 1+ $1 arguments */}
        ;

argument_expression_list_opt:
        argument_expression_list        {$$ = $1; /* Copy no. of arguments */}
        | {/* Empty */}                 {$$ = 0; /* No arguments */}
        ;


unary_expression:
        postfix_expression                      {$$ = $1;}
        | INC unary_expression                  { /* Assign and +1 */}
        | DEC unary_expression                  { /* Assign and -1 */}
        | unary_operator cast_expression        { /* Do and Assign */}
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
        | LPAREN type_name RPAREN cast_expression {/* New symbol after type change*/}
        ;

multiplicative_expression
        : cast_expression                                       { }
        | multiplicative_expression ASTERISK cast_expression    { }
        | multiplicative_expression DIV cast_expression         { }
        | multiplicative_expression MOD cast_expression         { }
        ;

additive_expression
        : multiplicative_expression                             {$$ = $1; /* Simple Assignment */}
        | additive_expression PLUS multiplicative_expression    { }
        | additive_expression MINUS multiplicative_expression   { }
        ;

shift_expression
        : additive_expression                                   {$$ = $1; /* Simple Assignment */}
        | shift_expression LEFT_SHIFT additive_expression       { }
        | shift_expression RIGHT_SHIFT additive_expression      { }
        ;

relational_expression
        : shift_expression                              {$$ = $1; /* Simple Assignment */}
        | relational_expression LT shift_expression     { }
        | relational_expression GT shift_expression     { }
        | relational_expression LE shift_expression     { }
        | relational_expression GE shift_expression     { }
        ;

equality_expression
        : relational_expression                         {$$ = $1; /* Simple Assignment */}
        | equality_expression EQ relational_expression  { }
        | equality_expression NE relational_expression  { }
        ;

and_expression
        : equality_expression                           {$$ = $1; /* Simple Assignment */}
        | and_expression AMPERSAND equality_expression  { }
        ;

exclusive_or_expression
        : and_expression                                {$$ = $1; /* Simple Assignment */}
        | exclusive_or_expression XOR and_expression    { }
        ;

inclusive_or_expression
        : exclusive_or_expression                               {$$ = $1; /* Simple Assignment */}
        | inclusive_or_expression OR exclusive_or_expression    { }
        ;

logical_and_expression
        : inclusive_or_expression                                           {$$ = $1; /* Simple Assignment */}
        | logical_and_expression LOGICAL_AND M inclusive_or_expression      { }
        ;

logical_or_expression
        : logical_and_expression                                            {$$ = $1; /* Simple Assignment */}
        | logical_or_expression LOGICAL_OR M logical_and_expression         { }
        ;

conditional_expression
        : logical_or_expression                                                             {$$ = $1; /* Simple Assignment */}
        | logical_or_expression N QUESTION M expression N COLON M conditional_expression    { }
        ;

assignment_expression
        : conditional_expression                                        {$$ = $1; /* Simple Assignment */}
        | unary_expression assignment_operator assignment_expression    { }
        ;

assignment_operator
        : ASSIGN        { /*Ignore*/ }
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
        | declarator ASSIGN initializer         { }
        ;

storage_class_specifier
        : EXTERN        { /*Ignore*/ }
        | STATIC        { /*Ignore*/ }
        | AUTO          { /*Ignore*/ }
        | REGISTER      { /*Ignore*/ }
        ;

type_specifier
        : VOID          { }
        | CHAR          { }
        | INT           { }
        | FLOAT         { }
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
        : pointer direct_declarator     { }
		| direct_declarator             { /*Ignore*/ }
        ;

direct_declarator
        : IDENTIFIER                                                        { }
        | LPAREN declarator RPAREN                                          {$$ = $2;}
		| direct_declarator LSQPAREN assignment_expression RSQPAREN     	{ }
		| direct_declarator LSQPAREN RSQPAREN         						{ }
        | direct_declarator LPAREN CT parameter_type_list RPAREN            { }
		| direct_declarator LPAREN CT RPAREN                          	    { }
        | direct_declarator LSQPAREN type_qualifier_list assignment_expression RSQPAREN 	            { /*Ignore*/ }
		| direct_declarator LSQPAREN type_qualifier_list RSQPAREN        	                            { /*Ignore*/ }
        | direct_declarator LSQPAREN STATIC type_qualifier_list_opt assignment_expression RSQPAREN      { /*Ignore*/ }
        | direct_declarator LSQPAREN type_qualifier_list STATIC assignment_expression RSQPAREN          { /*Ignore*/ }
        | direct_declarator LSQPAREN type_qualifier_list_opt ASTERISK RSQPAREN                          { /*Ignore*/ }
        | direct_declarator LPAREN identifier_list RPAREN          	                                    { /*Ignore*/ }
        ;

pointer
        : ASTERISK type_qualifier_list_opt              { }
        | ASTERISK type_qualifier_list_opt pointer      { }
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
        : assignment_expression                 { /*Simple Assignment*/}
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
        | expression_statement          {/*New Statement*/}
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
        : LBRACE CB CT block_item_list_opt RBRACE       { }
        ;

block_item_list
        : block_item                        {$$ = $1; /*Simple Assignment*/}
        | block_item_list M block_item      { }
        ;

block_item_list_opt
        : block_item_list               {$$ = $1; /*Simple Assignment*/}
        | {/* Empty */}                 {/*New statement*/}
        ;

block_item
        : declaration       { /*New statement*/}
        | statement         {$$ = $1; /*Simple Assignment*/}
        ;

expression_statement
        : expression_opt SEMICOLON      {$$ = $1;}
        ;

expression_opt
        : expression                    {$$ = $1;}
        | {/* Empty */}                 { /*New Expression*/ }

selection_statement
        : IF LPAREN expression N RPAREN M statement N  %prec PSEUDO_ELSE        { }
        | IF LPAREN expression N RPAREN M statement N ELSE M statement          { }
        | SWITCH LPAREN expression RPAREN statement                             { /*Ignore*/ }
        ;

iteration_statement
        : WHILE M LPAREN expression RPAREN M statement                                                              { }
        | DO M statement M WHILE LPAREN expression RPAREN SEMICOLON                                                 {}
        | FOR LPAREN expression_opt SEMICOLON M expression_opt SEMICOLON M expression_opt N RPAREN M statement      { }
        | FOR LPAREN declaration expression_opt SEMICOLON expression_opt RPAREN statement                           {/*Ignore*/}
        ;

jump_statement
        : GOTO IDENTIFIER SEMICOLON             { /*Ignore*/ }
        | CONTINUE SEMICOLON                    { /*New statement*/}
        | BREAK SEMICOLON                       { /*New statement*/}
        | RETURN expression_opt SEMICOLON       {/*New statement and emit return*/}
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
        : declaration_specifiers declarator declaration_list_opt CT LBRACE block_item_list_opt RBRACE { }
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

M   : %empty {/* For backpatching */}
    ;

N   : %empty {/*For control flow and backpatching*/}
    ;

CT  : %empty {/* Changing the sym table at functions */}
    ;

CB  : %empty { /*Create nested symbols for nested blocks*/}
    ;

/* Dummy Start */

tinyC_start:
        translation_unit        {print_productions($$, 0); clean_parse_tree($$);}
        ;

%%

void yyerror(const char* s) {
    printf("ERROR [Line %d] : %s, unable to parse : %s\n", yylineno, s, yytext);
}