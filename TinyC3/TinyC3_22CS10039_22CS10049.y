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
%type <node> primary_expression expression postfix_expression argument_expression_list argument_expression_list_opt type_name initializer_list assignment_expression unary_expression cast_expression multiplicative_expression additive_expression shift_expression relational_expression equality_expression and_expression exclusive_or_expression inclusive_or_expression logical_and_expression logical_or_expression conditional_expression constant_expression expression_opt
%type <node> unary_operator assignment_operator
%type <node> declaration declaration_specifiers declaration_specifiers_opt init_declarator_list init_declarator_list_opt storage_class_specifier type_specifier type_qualifier function_specifier init_declarator declarator initializer specifier_qualifier_list specifier_qualifier_list_opt pointer pointer_opt direct_declarator type_qualifier_list type_qualifier_list_opt assignment_expression_opt parameter_type_list identifier_list identifier_list_opt parameter_list parameter_declaration designation designation_opt designator_list designator
%type <node> statement labeled_statement compound_statement expression_statement selection_statement iteration_statement jump_statement block_item block_item_list block_item_list_opt
%type <node> translation_unit external_declaration function_definition declaration_list declaration_list_opt tinyC_start
%type <text> constant
%nonassoc PSEUDO_ELSE
%nonassoc ELSE

%start tinyC_start

%%

/* Expressions */

primary_expression:
        IDENTIFIER                      {char* msg = (char*)malloc((25+strlen($1))*sizeof(char)); sprintf(msg,"primary_expression -> %s",$1); $$ = create_node(msg, 0);}
        | constant                      {char* msg = (char*)malloc((25+strlen($1))*sizeof(char)); sprintf(msg,"primary_expression -> %s",$1); $$ = create_node(msg, 0);}
        | STRING_LITERAL                {char* msg = (char*)malloc((25+strlen($1))*sizeof(char)); sprintf(msg,"primary_expression -> %s",$1); $$ = create_node(msg, 0);}
        | LPAREN expression RPAREN      {$$ = create_node("primary_expression -> ( expression )", 1, $2);}
        ;

postfix_expression:
        primary_expression                                              {$$ = create_node("postfix_expression -> primary_expression", 1, $1);}
        | postfix_expression LSQPAREN expression RSQPAREN               {$$ = create_node("postfix_expression -> postfix_expression [ expression ]", 2, $1, $3);}
        | postfix_expression LPAREN argument_expression_list_opt RPAREN {$$ = create_node("postfix_expression -> postfix_expression ( argument_expression_list_opt )", 2, $1, $3);}
        | postfix_expression INC                                        {$$ = create_node("postfix_expression -> postfix_expression ++", 1, $1);}
        | postfix_expression DEC                                        {$$ = create_node("postfix_expression -> postfix_expression --", 1, $1);}
        | postfix_expression DOT IDENTIFIER                             {  /*Ignore*/ }
        | postfix_expression ARROW IDENTIFIER                           {  /*Ignore*/ }
        | LPAREN type_name RPAREN LBRACE initializer_list RBRACE        {  /*Ignore*/ }
        | LPAREN type_name RPAREN LBRACE initializer_list COMMA RBRACE  {  /*Ignore*/ }
        ;

argument_expression_list:
        assignment_expression                                           {$$ = create_node("argument_expression_list -> assignment_expression", 1, $1);}
        | argument_expression_list COMMA assignment_expression          {$$ = create_node("argument_expression_list -> argument_expression_list , assignment_expression", 2, $1, $3);}
        ;

unary_expression:
        postfix_expression                      {$$ = create_node("unary_expression -> postfix_expression", 1, $1);}
        | INC unary_expression                  {$$ = create_node("unary_expression -> ++ unary_expression", 1, $2);}
        | DEC unary_expression                  {$$ = create_node("unary_expression -> -- unary_expression", 1, $2);}
        | unary_operator cast_expression        {$$ = create_node("unary_expression -> unary_operator cast_expression", 2, $1, $2);}
        | SIZEOF unary_expression               {  /*Ignore*/ }
        | SIZEOF LPAREN type_name RPAREN        {  /*Ignore*/ }
        ;

unary_operator:
        AMPERSAND       {$$ = create_node("unary_operator -> &", 0);}
        | ASTERISK      {$$ = create_node("unary_operator -> *", 0);}
        | PLUS          {$$ = create_node("unary_operator -> +", 0);}
        | MINUS         {$$ = create_node("unary_operator -> -", 0);}
        | TILDE         {$$ = create_node("unary_operator -> ~", 0);}
        | NOT           {$$ = create_node("unary_operator -> !", 0);}
        ;

cast_expression:
        unary_expression                          {$$ = create_node("cast_expression -> unary_expression", 1, $1);}
        | LPAREN type_name RPAREN cast_expression {$$ = create_node("cast_expression -> ( type_name ) cast_expression", 2, $2, $4);}
        ;

multiplicative_expression:
        cast_expression                                         {$$ = create_node("multiplicative_expression -> cast_expression", 1, $1);}
        | multiplicative_expression ASTERISK cast_expression    {$$ = create_node("multiplicative_expression -> multiplicative_expression * cast_expression", 2, $1, $3);}
        | multiplicative_expression DIV cast_expression         {$$ = create_node("multiplicative_expression -> multiplicative_expression / cast_expression", 2, $1, $3);}
        | multiplicative_expression MOD cast_expression         {$$ = create_node("multiplicative_expression -> multiplicative_expression \% cast_expression", 2, $1, $3);}
        ;

additive_expression:
        multiplicative_expression                               {$$ = create_node("additive_expression -> multiplicative_expression", 1, $1);}
        | additive_expression PLUS multiplicative_expression    {$$ = create_node("additive_expression -> additive_expression + multiplicative_expression", 2, $1, $3);}
        | additive_expression MINUS multiplicative_expression   {$$ = create_node("additive_expression -> additive_expression - multiplicative_expression", 2, $1, $3);}
        ;

shift_expression:
        additive_expression                                     {$$ = create_node("shift_expression -> additive_expression", 1, $1);}
        | shift_expression LEFT_SHIFT additive_expression       {$$ = create_node("shift_expression -> shift_expression << additive_expression", 2, $1, $3);}
        | shift_expression RIGHT_SHIFT additive_expression      {$$ = create_node("shift_expression -> shift_expression >> additive_expression", 2, $1, $3);}
        ;

relational_expression:
        shift_expression                                {$$ = create_node("relational_expression -> shift_expression", 1, $1);}
        | relational_expression LT shift_expression     {$$ = create_node("relational_expression -> relational_expression < shift_expression", 2, $1, $3);}
        | relational_expression GT shift_expression     {$$ = create_node("relational_expression -> relational_expression > shift_expression", 2, $1, $3);}
        | relational_expression LE shift_expression     {$$ = create_node("relational_expression -> relational_expression <= shift_expression", 2, $1, $3);}
        | relational_expression GE shift_expression     {$$ = create_node("relational_expression -> relational_expression >= shift_expression", 2, $1, $3);}
        ;

equality_expression:
        relational_expression                           {$$ = create_node("equality_expression -> relational_expression", 1, $1);}
        | equality_expression EQ relational_expression  {$$ = create_node("equality_expression -> equality_expression == relational_expression", 2, $1, $3);}
        | equality_expression NE relational_expression  {$$ = create_node("equality_expression -> equality_expression != relational_expression", 2, $1, $3);}
        ;

and_expression:
        equality_expression     {$$ = create_node("and_expression -> equality_expression", 1, $1);}
        | and_expression AMPERSAND equality_expression  {$$ = create_node("and_expression -> and_expression & equality_expression", 2, $1, $3);}
        ;

exclusive_or_expression:
        and_expression          {$$ = create_node("exclusive_or_expression -> and_expression", 1, $1);}
        | exclusive_or_expression XOR and_expression    {$$ = create_node("exclusive_or_expression -> exclusive_or_expression ^ and_expression", 2, $1, $3);}
        ;

inclusive_or_expression:
        exclusive_or_expression    {$$ = create_node("inclusive_or_expression -> exclusive_or_expression", 1, $1);}
        | inclusive_or_expression OR exclusive_or_expression    {$$ = create_node("inclusive_or_expression -> inclusive_or_expression | exclusive_or_expression", 2, $1, $3);}
        ;

logical_and_expression:
        inclusive_or_expression    {$$ = create_node("logical_and_expression -> inclusive_or_expression", 1, $1);}
        | logical_and_expression LOGICAL_AND inclusive_or_expression    {$$ = create_node("logical_and_expression -> logical_and_expression && inclusive_or_expression", 2, $1, $3);}
        ;

logical_or_expression:
        logical_and_expression    {$$ = create_node("logical_or_expression -> logical_and_expression", 1, $1);}
        | logical_or_expression LOGICAL_OR logical_and_expression       {$$ = create_node("logical_or_expression -> logical_or_expression || logical_and_expression", 2, $1, $3);}
        ;

conditional_expression:
        logical_or_expression    {$$ = create_node("conditional_expression -> logical_or_expression", 1, $1);}
        | logical_or_expression QUESTION expression COLON conditional_expression        {$$ = create_node("conditional_expression -> logical_or_expression ? expression : conditional_expression", 3, $1, $3, $5);}
        ;

assignment_expression:
        conditional_expression  {$$ = create_node("assignment_expression -> conditional_expression", 1, $1);}
        | unary_expression assignment_operator assignment_expression    {$$ = create_node("assignment_expression -> unary_expression assignment_operator assignment_expression", 3, $1, $2, $3);}
        ;

assignment_operator:
        ASSIGN          { /* Doubt */ }
        | MUL_ASSIGN    {  /*Ignore*/ }
        | DIV_ASSIGN    {  /*Ignore*/ }
        | MOD_ASSIGN    {  /*Ignore*/ }
        | ADD_ASSIGN    {  /*Ignore*/ }
        | SUB_ASSIGN    {  /*Ignore*/ }
        | LEFT_ASSIGN   {  /*Ignore*/ }
        | RIGHT_ASSIGN  {  /*Ignore*/ }
        | AND_ASSIGN    {  /*Ignore*/ }
        | XOR_ASSIGN    {  /*Ignore*/ }
        | OR_ASSIGN     {  /*Ignore*/ }
        ;

expression:
        assignment_expression                           {$$ = create_node("expression -> assignment_expression", 1, $1);}
        | expression COMMA assignment_expression        {  /*Ignore*/ }
        ;

constant_expression:
        conditional_expression     {  /*Ignore*/ }
        ;
    
/* Declarations */

declaration:
        declaration_specifiers init_declarator_list_opt SEMICOLON       {  /*Ignore*/ }
        ;

declaration_specifiers:
        storage_class_specifier declaration_specifiers_opt      {  /*Ignore*/ }
        | type_specifier declaration_specifiers_opt             {  /*Ignore*/ }
        | type_qualifier declaration_specifiers_opt             {  /*Ignore*/ }
        | function_specifier declaration_specifiers_opt         {  /*Ignore*/ }
        ;

init_declarator_list:
        init_declarator                                 {  /*Ignore*/ }
        | init_declarator_list COMMA init_declarator    {  /*Ignore*/ }
        ;

init_declarator:
        declarator                              {$$ = create_node("init_declarator -> declarator", 1, $1);}
        | declarator ASSIGN initializer         {$$ = create_node("init_declarator -> declarator = initializer", 2, $1, $3);}
        ;

storage_class_specifier:
        EXTERN          {  /*Ignore*/ }
        | STATIC        {  /*Ignore*/ }
        | AUTO          {  /*Ignore*/ }
        | REGISTER      {  /*Ignore*/ }
        ;

type_specifier:
        VOID            {$$ = create_node("type_specifier -> void", 0);}
        | CHAR          {$$ = create_node("type_specifier -> char", 0);} 
        | INT           {$$ = create_node("type_specifier -> int", 0);}
        | FLOAT         {$$ = create_node("type_specifier -> float", 0);}
        | LONG          {  /*Ignore*/ }
        | SHORT         {  /*Ignore*/ }
        | DOUBLE        {  /*Ignore*/ }
        | SIGNED        {  /*Ignore*/ }
        | UNSIGNED      {  /*Ignore*/ }
        | BOOL_         {  /*Ignore*/ }
        | COMPLEX_      {  /*Ignore*/ }
        | IMAGINARY_    {  /*Ignore*/ }
        ;

specifier_qualifier_list:
        type_specifier specifier_qualifier_list_opt     {  /*Ignore*/ }
        | type_qualifier specifier_qualifier_list_opt   {  /*Ignore*/ }
        ;

type_qualifier:
        CONST           {  /*Ignore*/ }
        | RESTRICT      {  /*Ignore*/ }
        | VOLATILE      {  /*Ignore*/ }
        ;

function_specifier:
        INLINE          {  /*Ignore*/ }
        ;

declarator:
        pointer direct_declarator     {$$ = create_node("declarator -> pointer_opt direct_declarator", 2, $1, $2);}
		| direct_declarator           {  /*Ignore*/ }
        ;

direct_declarator:
        IDENTIFIER                      {char* msg = (char*)malloc((25+strlen($1))*sizeof(char)); sprintf(msg,"direct_declarator -> %s",$1); $$ = create_node(msg, 0);}
        | LPAREN declarator RPAREN      {$$ = create_node("direct_declarator -> ( declarator )", 1, $2);}
        | direct_declarator LSQPAREN type_qualifier_list assignment_expression RSQPAREN 	{  /*Ignore*/ }
		| direct_declarator LSQPAREN assignment_expression RSQPAREN     	{ $$ = $1; /* to be done*/ }
		| direct_declarator LSQPAREN RSQPAREN         						{ $$ = $1; /* to be done*/ }
		| direct_declarator LSQPAREN type_qualifier_list RSQPAREN        	{  /*Ignore*/ }
        | direct_declarator LSQPAREN STATIC type_qualifier_list_opt assignment_expression RSQPAREN      {  /*Ignore*/ }
        | direct_declarator LSQPAREN type_qualifier_list STATIC assignment_expression RSQPAREN          {  /*Ignore*/ }
        | direct_declarator LSQPAREN type_qualifier_list_opt ASTERISK RSQPAREN                          {  /*Ignore*/ }
        | direct_declarator LPAREN parameter_type_list RPAREN       {$$ = create_node("direct_declarator -> direct_declarator ( parameter_type_list )", 2, $1, $3);}
        | direct_declarator LPAREN identifier_list RPAREN          	{  /*Ignore*/ }
		| direct_declarator LPAREN RPAREN                          	{$$ = create_node("direct_declarator -> direct_declarator ( identifier_list_opt )", 2, $1, $3);}
        ;

pointer:
        ASTERISK type_qualifier_list_opt                {$$ = create_node("pointer -> * type_qualifier_list_opt", 1, $2);}
        | ASTERISK type_qualifier_list_opt pointer      {$$ = create_node("pointer -> * type_qualifier_list_opt pointer", 2, $2, $3);}
        ;

type_qualifier_list:
        type_qualifier                          {  /*Ignore*/ }
        | type_qualifier_list type_qualifier    {  /*Ignore*/ }
        ;

parameter_type_list:
        parameter_list                          {  /*Ignore*/ }
        | parameter_list COMMA ELLIPSIS         {  /*Ignore*/ }
        ;

parameter_list:
        parameter_declaration                           {  /*Ignore*/ }
        | parameter_list COMMA parameter_declaration    {  /*Ignore*/ }
        ;

parameter_declaration:
        declaration_specifiers declarator       {  /*Ignore*/ }
        | declaration_specifiers                {  /*Ignore*/ }
        ;

identifier_list:
        IDENTIFIER                              {  /*Ignore*/ }
        | identifier_list COMMA IDENTIFIER      {  /*Ignore*/ }
        ;

type_name:
        specifier_qualifier_list                {  /*Ignore*/ }
        ;

initializer:
        assignment_expression                   {$$ = create_node("initializer -> assignment_expression", 1, $1);}
        | LBRACE initializer_list RBRACE        {  /*Ignore*/ }
        | LBRACE initializer_list COMMA RBRACE  {  /*Ignore*/ }
        ;

initializer_list:
        designation_opt initializer                             {  /*Ignore*/ }
        | initializer_list COMMA designation_opt initializer    {  /*Ignore*/ }
        ;

designation:
        designator_list ASSIGN                  {  /*Ignore*/ }
        ;

designator_list:
        designator                              {  /*Ignore*/ }
        | designator_list designator            {  /*Ignore*/ }
        ;

designator:
        LSQPAREN constant_expression RSQPAREN   {  /*Ignore*/ }
        | DOT IDENTIFIER                        {  /*Ignore*/ }
        ;

/* Statements */

statement:
        labeled_statement               {  /*Ignore*/ }
        | compound_statement            {$$ = create_node("statement -> compound_statement", 1, $1);}
        | expression_statement          {$$ = create_node("statement -> expression_statement", 1, $1);}
        | selection_statement           {$$ = create_node("statement -> selection_statement", 1, $1);}
        | iteration_statement           {$$ = create_node("statement -> iteration_statement", 1, $1);}
        | jump_statement                {$$ = create_node("statement -> jump_statement", 1, $1);}
        ;

labeled_statement:
        IDENTIFIER COLON statement                      {  /*Ignore*/ }
        | CASE constant_expression COLON statement      {  /*Ignore*/ }
        | DEFAULT COLON statement                       {  /*Ignore*/ }
        ;

compound_statement:
        LBRACE block_item_list_opt RBRACE       {$$ = create_node("compound_statement -> { block_item_list_opt }", 1, $2);}
        ;

block_item_list:
        block_item                      {$$ = create_node("block_item_list -> block_item", 1, $1);}
        | block_item_list block_item    {$$ = create_node("block_item_list -> block_item_list block_item", 2, $1, $2);}
        ;

block_item:
        declaration     {$$ = create_node("block_item -> declaration", 1, $1);}
        | statement     {$$ = create_node("block_item -> statement", 1, $1);}
        ;

expression_statement:
        expression_opt SEMICOLON        {$$ = create_node("expression_statement -> expression_opt ;", 1, $1);}
        ;

selection_statement:
        IF LPAREN expression RPAREN statement   %prec PSEUDO_ELSE       {$$ = create_node("selection_statement -> if ( expression ) statement", 2, $3, $5);}
        | IF LPAREN expression RPAREN statement ELSE statement          {$$ = create_node("selection_statement -> if ( expression ) statement else statement", 3, $3, $5, $7);}
        | SWITCH LPAREN expression RPAREN statement                     {  /*Ignore*/ }
        ;

iteration_statement:
        WHILE LPAREN expression RPAREN statement                        {$$ = create_node("iteration_statement -> while ( expression ) statement", 2, $3, $5);}
        | DO statement WHILE LPAREN expression RPAREN SEMICOLON         {$$ = create_node("iteration_statement -> do statement while ( expression ) ;", 2, $2, $5);}
        | FOR LPAREN expression_opt SEMICOLON expression_opt SEMICOLON expression_opt RPAREN statement  {$$ = create_node("iteration_statement -> for ( expression_opt ; expression_opt ; expression_opt ) statement", 4, $3, $5, $7, $9);}
        | FOR LPAREN declaration expression_opt SEMICOLON expression_opt RPAREN statement               {$$ = create_node("iteration_statement -> for ( declaration expression_opt ; expression_opt ) statement", 4, $3, $4, $6, $8);}
        ;

jump_statement:
        GOTO IDENTIFIER SEMICOLON               {  /*Ignore*/ }
        | CONTINUE SEMICOLON                    {$$ = create_node("jump_statement -> continue ;", 0);}
        | BREAK SEMICOLON                       {$$ = create_node("jump_statement -> break ;", 0);}
        | RETURN expression_opt SEMICOLON       {$$ = create_node("jump_statement -> return expression_opt ;", 1, $2);}
        ;

/* External Definitions */

translation_unit:
        external_declaration                    {  /*Ignore*/ }
        | translation_unit external_declaration {  /*Ignore*/ }
        ;

external_declaration:
        function_definition     {  /*Ignore*/ }
        | declaration           {  /*Ignore*/ }
        ;

function_definition:
        declaration_specifiers declarator declaration_list_opt compound_statement {$$ = create_node("function_definition -> declaration_specifiers declarator declaration_list_opt compound_statement", 4, $1, $2, $3, $4);}
        ;

declaration_list:
        declaration                     {  /*Ignore*/ }
        | declaration_list declaration  {  /*Ignore*/ }
        ;


/* Optionals */

argument_expression_list_opt:
        argument_expression_list        {$$ = create_node("argument_expression_list_opt -> argument_expression_list", 1, $1);}
        | {/* Empty */}                 {$$ = create_node("argument_expression_list_opt -> EPSILON", 0);}
        ;

declaration_specifiers_opt:
        declaration_specifiers          {$$ = create_node("declaration_specifiers_opt -> declaration_specifiers", 1, $1);}
        | {/* Empty */}                 {$$ = create_node("declaration_specifiers_opt -> EPSILON", 0);}
        ;

init_declarator_list_opt:
        init_declarator_list            {$$ = create_node("init_declarator_list_opt -> init_declarator_list", 1, $1);}
        | {/* Empty */}                 {$$ = create_node("init_declarator_list_opt -> EPSILON", 0);}
        ;

specifier_qualifier_list_opt:
        specifier_qualifier_list        {  /*Ignore*/ }
        | {/* Empty */}                 {  /*Ignore*/ }
        ;

pointer_opt:
        pointer                         {$$ = create_node("pointer_opt -> pointer", 1, $1);}
        | {/* Empty */}                 {$$ = create_node("pointer_opt -> EPSILON", 0);}
        ;

type_qualifier_list_opt:
        type_qualifier_list             {  /*Ignore*/ }
        | {/* Empty */}                 {  /*Ignore*/ }
        ;

expression_opt:
        expression                      {$$ = create_node("expression_opt -> expression", 1, $1);}
        | {/* Empty */}                 {$$ = create_node("expression_opt -> EPSILON", 0);}
        ;

assignment_expression_opt:
        assignment_expression           {$$ = create_node("assignment_expression_opt -> assignment_expression", 1, $1);}
        | {/* Empty */}                 {$$ = create_node("assignment_expression_opt -> EPSILON", 0);}
        ;

identifier_list_opt:
        identifier_list                 {$$ = create_node("identifier_list_opt -> identifier_list", 1, $1);}
        | {/* Empty */}                 {$$ = create_node("identifier_list_opt -> EPSILON", 0);}
        ;

designation_opt:
        designation                     {  /*Ignore*/ }
        | {/* Empty */}                 {  /*Ignore*/ }
        ;

block_item_list_opt:
        block_item_list                 {$$ = create_node("block_item_list_opt -> block_item_list", 1, $1);}
        | {/* Empty */}                 {$$ = create_node("block_item_list_opt -> EPSILON", 0);}
        ;

declaration_list_opt:
        declaration_list                {  /*Ignore*/ }
        | {/* Empty */}                 {  /*Ignore*/ }
        ;

/* Constants */

constant:
        INTEGER_CONSTANT
        | FLOATING_CONSTANT
        | CHAR_CONSTANT
        ;

/* Dummy Start */

tinyC_start:
        translation_unit        {print_productions($$, 0); clean_parse_tree($$);}
        ;

%%

void yyerror (char * err){
    throw_error(err);
}