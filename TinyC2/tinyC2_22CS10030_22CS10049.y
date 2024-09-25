%{	
	#include <stdio.h>
	#include <stdlib.h>
	#include <stdarg.h>

    extern int yylex();
    extern int yylineno;
    void yyerror ( char * );  

    typedef struct parse_tree_node {
        char* text;
		struct node_child_list* children;
    } parse_tree_node;  

	typedef struct node_child_list {
		struct parse_tree_node* child;
		struct node_child_list* next;
	} node_child_list;	


	parse_tree_node* create_node(char *, ...);
        node_child_list* add_child_node(parse_tree_node* );
        print_productions(parse_tree_node*, int);
        print_spaces(int);
%}

%union {
        char* text;
	struct parse_tree_node* node;
}

%token <text> IDENTIFIER FLOATING_CONSTANT INTEGER_CONSTANT CHAR_CONSTANT STRING_LITERAL
%token SIZEOF EXTERN STATIC AUTO REGISTER VOID CHAR SHORT INT LONG FLOAT DOUBLE SIGNED UNSIGNED BOOL_ COMPLEX_ IMAGINARY_ CONST RESTRICT VOLATILE INLINE CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN
%token LSQPAREN RSQPAREN LPAREN RPAREN LBRACE RBRACE
%token DOT ARROW INC DEC AMPERSAND ASTERISK PLUS MINUS TILDE NOT DIV MOD LEFT_SHIFT RIGHT_SHIFT LT GT LE GE EQ NE XOR OR LOGICAL_OR LOGICAL_AND QUESTION COLON SEMICOLON ELLIPSIS ASSIGN MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN XOR_ASSIGN OR_ASSIGN COMMA
%type <node> primary_expression expression postfix_expression argument_expression_list argument_expression_list_opt type_name initializer_list assignment_expression unary_expression cast_expression multiplicative_expression additive_expression shift_expression relational_expression equality_expression and_expression exclusive_or_expression inclusive_or_expression logical_and_expression logical_or_expression conditional_expression constant_expression expression_opt
%type <node> unary_operator assignment_operator
%type <node> declaration declaration_specifiers declaration_specifiers_opt init_declarator_list init_declarator_list_opt storage_class_specifier type_specifier type_qualifier function_specifier init_declarator declarator initializer specifier_qualifier_list specifier_qualifier_list_opt pointer pointer_opt direct_declarator type_qualifier_list type_qualifier_list_opt assignment_expression_opt parameter_type_list identifier_list identifier_list_opt parameter_list parameter_declaration designation designation_opt designator_list designator
%type <node> statement labeled_statement compound_statement expression_statement selection_statement iteration_statement jump_statement block_item block_item_list block_item_list_opt
%type <node> translation_unit external_declaration function_definition declaration_list declaration_list_opt
%type <text> constant
%nonassoc PSEUDO_ELSE
%nonassoc ELSE

%start translation_unit

%%

/* Expressions */

primary_expression:
        IDENTIFIER                      {$$ = create_node("primary_expression -> IDENTIFIER", 0);}
        | constant                      {$$ = create_node("primary_expression -> CONSTANT", 0);}
        | STRING_LITERAL                {$$ = create_node("primary_expression -> STRING_LITERAL", 0);}
        | LPAREN expression RPAREN      {$$ = create_node("primary_expression -> ( expression )", 1, $2);}
        ;

postfix_expression:
        primary_expression                                              {$$ = create_node("postfix_expression -> primary_expression", 1, $1);}
        | postfix_expression LSQPAREN expression RSQPAREN               {$$ = create_node("postfix_expression -> postfix_expression [ expression ]", 2, $1, $3);}
        | postfix_expression LPAREN argument_expression_list_opt RPAREN {$$ = create_node("postfix_expression -> postfix_expression ( argument_expression_list_opt )", 2, $1, $3);}
        | postfix_expression DOT IDENTIFIER                             {$$ = create_node("postfix_expression -> postfix_expression . IDENTIFIER", 1, $1);}
        | postfix_expression ARROW IDENTIFIER                           {$$ = create_node("postfix_expression -> postfix_expression -> IDENTIFIER", 1, $1);}
        | postfix_expression INC                                        {$$ = create_node("postfix_expression -> postfix_expression ++", 1, $1);}
        | postfix_expression DEC                                        {$$ = create_node("postfix_expression -> postfix_expression --", 1, $1);}
        | LPAREN type_name RPAREN LBRACE initializer_list RBRACE        {$$ = create_node("postfix_expression -> ( type_name ) { initializer_list }", 2, $2, $5);}
        | LPAREN type_name RPAREN LBRACE initializer_list COMMA RBRACE  {$$ = create_node("postfix_expression -> ( type_name ) { initializer_list , }", 2, $2, $5);}
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
        | SIZEOF unary_expression               {$$ = create_node("unary_expression -> sizeof unary_expression", 1, $2);}
        | SIZEOF LPAREN type_name RPAREN        {$$ = create_node("unary_expression -> sizeof ( type_name )", 1, $3);}
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
        unary_expression            {$$ = create_node("cast_expression -> unary_expression", 1, $1);}
        | LPAREN type_name RPAREN cast_expression {$$ = create_node("cast_expression -> ( type_name ) cast_expression", 2, $2, $4);}
        ;

multiplicative_expression:
        cast_expression         {$$ = create_node("multiplicative_expression -> cast_expression", 1, $1);}
        | multiplicative_expression ASTERISK cast_expression    {$$ = create_node("multiplicative_expression -> multiplicative_expression * cast_expression", 2, $1, $3);}
        | multiplicative_expression DIV cast_expression         {$$ = create_node("multiplicative_expression -> multiplicative_expression / cast_expression", 2, $1, $3);}
        | multiplicative_expression MOD cast_expression         {$$ = create_node("multiplicative_expression -> multiplicative_expression \% cast_expression", 2, $1, $3);}
        ;

additive_expression:
        multiplicative_expression       {$$ = create_node("additive_expression -> multiplicative_expression", 1, $1);}
        | additive_expression PLUS multiplicative_expression    {$$ = create_node("additive_expression -> additive_expression + multiplicative_expression", 2, $1, $3);}
        | additive_expression MINUS multiplicative_expression   {$$ = create_node("additive_expression -> additive_expression - multiplicative_expression", 2, $1, $3);}
        ;

shift_expression:
        additive_expression         {$$ = create_node("shift_expression -> additive_expression", 1, $1);}
        | shift_expression LEFT_SHIFT additive_expression       {$$ = create_node("shift_expression -> shift_expression << additive_expression", 2, $1, $3);}
        | shift_expression RIGHT_SHIFT additive_expression      {$$ = create_node("shift_expression -> shift_expression >> additive_expression", 2, $1, $3);}
        ;

relational_expression:
        shift_expression        {$$ = create_node("relational_expression -> shift_expression", 1, $1);}
        | relational_expression LT shift_expression     {$$ = create_node("relational_expression -> relational_expression < shift_expression", 2, $1, $3);}
        | relational_expression GT shift_expression     {$$ = create_node("relational_expression -> relational_expression > shift_expression", 2, $1, $3);}
        | relational_expression LE shift_expression     {$$ = create_node("relational_expression -> relational_expression <= shift_expression", 2, $1, $3);}
        | relational_expression GE shift_expression     {$$ = create_node("relational_expression -> relational_expression >= shift_expression", 2, $1, $3);}
        ;

equality_expression:
        relational_expression    {$$ = create_node("equality_expression -> relational_expression", 1, $1);}
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
        ASSIGN          {$$ = create_node("assignment_operator -> =", 0);}
        | MUL_ASSIGN    {$$ = create_node("assignment_operator -> *=", 0);}
        | DIV_ASSIGN    {$$ = create_node("assignment_operator -> /=", 0);}
        | MOD_ASSIGN    {$$ = create_node("assignment_operator -> %=", 0);}
        | ADD_ASSIGN    {$$ = create_node("assignment_operator -> +=", 0);}
        | SUB_ASSIGN    {$$ = create_node("assignment_operator -> -=", 0);}
        | LEFT_ASSIGN   {$$ = create_node("assignment_operator -> <<=", 0);}
        | RIGHT_ASSIGN  {$$ = create_node("assignment_operator -> >>=", 0);}
        | AND_ASSIGN    {$$ = create_node("assignment_operator -> &=", 0);}
        | XOR_ASSIGN    {$$ = create_node("assignment_operator -> ^=", 0);}
        | OR_ASSIGN     {$$ = create_node("assignment_operator -> |=", 0);}
        ;

expression:
        assignment_expression        {$$ = create_node("expression -> assignment_expression", 1, $1);}
        | expression COMMA assignment_expression        {$$ = create_node("expression -> expression , assignment_expression", 2, $1, $3);}
        ;

constant_expression:
        conditional_expression     {$$ = create_node("constant_expression -> conditional_expression", 1, $1);}
        ;
    
/* Declarations */

declaration:
        declaration_specifiers init_declarator_list_opt SEMICOLON       {$$ = create_node("declaration -> declaration_specifiers init_declarator_list_opt ;", 2, $1, $2);}
        ;

declaration_specifiers:
        storage_class_specifier declaration_specifiers_opt      {$$ = create_node("declaration_specifiers -> storage_class_specifier declaration_specifiers_opt", 2, $1, $2);}
        | type_specifier declaration_specifiers_opt             {$$ = create_node("declaration_specifiers -> type_specifier declaration_specifiers_opt", 2, $1, $2);}
        | type_qualifier declaration_specifiers_opt             {$$ = create_node("declaration_specifiers -> type_qualifier declaration_specifiers_opt", 2, $1, $2);}
        | function_specifier declaration_specifiers_opt         {$$ = create_node("declaration_specifiers -> function_specifier declaration_specifiers_opt", 2, $1, $2);}
        ;

init_declarator_list:
        init_declarator         {$$ = create_node("init_declarator_list -> init_declarator", 1, $1);}
        | init_declarator_list COMMA init_declarator    {$$ = create_node("init_declarator_list -> init_declarator_list , init_declarator", 2, $1, $3);}
        ;

init_declarator:
        declarator              {$$ = create_node("init_declarator -> declarator", 1, $1);}
        | declarator ASSIGN initializer         {$$ = create_node("init_declarator -> declarator = initializer", 2, $1, $3);}
        ;

storage_class_specifier:
        EXTERN          {$$ = create_node("storage_class_specifier -> extern", 0);}
        | STATIC        {$$ = create_node("storage_class_specifier -> static", 0);}
        | AUTO          {$$ = create_node("storage_class_specifier -> auto", 0);}
        | REGISTER      {$$ = create_node("storage_class_specifier -> register", 0);}
        ;

type_specifier:
        VOID            {$$ = create_node("type_specifier -> void", 0);}
        | CHAR          {$$ = create_node("type_specifier -> char", 0);}
        | SHORT         {$$ = create_node("type_specifier -> short", 0);}
        | INT           {$$ = create_node("type_specifier -> int", 0);}
        | LONG          {$$ = create_node("type_specifier -> long", 0);}
        | FLOAT         {$$ = create_node("type_specifier -> float", 0);}
        | DOUBLE        {$$ = create_node("type_specifier -> double", 0);}
        | SIGNED        {$$ = create_node("type_specifier -> signed", 0);}
        | UNSIGNED      {$$ = create_node("type_specifier -> unsigned", 0);}
        | BOOL_         {$$ = create_node("type_specifier -> _Bool", 0);}
        | COMPLEX_      {$$ = create_node("type_specifier -> _Complex", 0);}
        | IMAGINARY_    {$$ = create_node("type_specifier -> _Imaginary", 0);}
        ;

specifier_qualifier_list:
        type_specifier specifier_qualifier_list_opt     {$$ = create_node("specifier_qualifier_list -> type_specifier specifier_qualifier_list_opt", 2, $1, $2);}
        | type_qualifier specifier_qualifier_list_opt   {$$ = create_node("specifier_qualifier_list -> type_qualifier specifier_qualifier_list_opt", 2, $1, $2);}
        ;

type_qualifier:
        CONST           {$$ = create_node("type_qualifier -> const", 0);}
        | RESTRICT      {$$ = create_node("type_qualifier -> restrict", 0);}
        | VOLATILE      {$$ = create_node("type_qualifier -> volatile", 0);}
        ;

function_specifier:
        INLINE          {$$ = create_node("function_specifier -> inline", 0);}
        ;

declarator:
        pointer_opt direct_declarator     {$$ = create_node("declarator -> pointer_opt direct_declarator", 2, $1, $2);}
        ;

direct_declarator:
        IDENTIFIER                      {$$ = create_node("direct_declarator -> IDENTIFIER", 0);}
        | LPAREN declarator RPAREN      {$$ = create_node("direct_declarator -> ( declarator )", 1, $2);}
        | direct_declarator LSQPAREN type_qualifier_list_opt assignment_expression_opt RSQPAREN         {$$ = create_node("direct_declarator -> direct_declarator [ type_qualifier_list_opt assignment_expression_opt ]", 3, $1, $3, $4);}
        | direct_declarator LSQPAREN STATIC type_qualifier_list_opt assignment_expression RSQPAREN      {$$ = create_node("direct_declarator -> direct_declarator [ static type_qualifier_list_opt assignment_expression ]", 3, $1, $4, $5);}
        | direct_declarator LSQPAREN type_qualifier_list STATIC assignment_expression RSQPAREN          {$$ = create_node("direct_declarator -> direct_declarator [ type_qualifier_list static assignment_expression ]", 3, $1, $3, $5);}
        | direct_declarator LSQPAREN type_qualifier_list_opt ASTERISK RSQPAREN                          {$$ = create_node("direct_declarator -> direct_declarator [ type_qualifier_list_opt * ]", 2, $1, $3);}
        | direct_declarator LPAREN parameter_type_list RPAREN                                           {$$ = create_node("direct_declarator -> direct_declarator ( parameter_type_list )", 2, $1, $3);}
        | direct_declarator LPAREN identifier_list_opt RPAREN                                           {$$ = create_node("direct_declarator -> direct_declarator ( identifier_list_opt )", 2, $1, $3);}
        ;

pointer:
        ASTERISK type_qualifier_list_opt                {$$ = create_node("pointer -> * type_qualifier_list_opt", 2, $2);}
        | ASTERISK type_qualifier_list_opt pointer      {$$ = create_node("pointer -> * type_qualifier_list_opt pointer", 3, $2, $3);}
        ;

type_qualifier_list:
        type_qualifier  {$$ = create_node("type_qualifier_list -> type_qualifier", 1, $1);}
        | type_qualifier_list type_qualifier    {$$ = create_node("type_qualifier_list -> type_qualifier_list type_qualifier", 2, $1, $2);}
        ;

parameter_type_list:
        parameter_list      {$$ = create_node("parameter_type_list -> parameter_list", 1, $1);}
        | parameter_list COMMA ELLIPSIS         {$$ = create_node("parameter_type_list -> parameter_list , ...", 2, $1);}
        ;

parameter_list:
        parameter_declaration    {$$ = create_node("parameter_list -> parameter_declaration", 1, $1);}
        | parameter_list COMMA parameter_declaration    {$$ = create_node("parameter_list -> parameter_list , parameter_declaration", 2, $1, $3);}
        ;

parameter_declaration:
        declaration_specifiers declarator       {$$ = create_node("parameter_declaration -> declaration_specifiers declarator", 2, $1, $2);}
        | declaration_specifiers        {$$ = create_node("parameter_declaration -> declaration_specifiers", 1, $1);}
        ;

identifier_list:
        IDENTIFIER      {$$ = create_node("identifier_list -> IDENTIFIER", 0);}
        | identifier_list COMMA IDENTIFIER      {$$ = create_node("identifier_list -> identifier_list , IDENTIFIER", 2, $1, $3);}
        ;

type_name:
        specifier_qualifier_list        {$$ = create_node("type_name -> specifier_qualifier_list", 1, $1);}
        ;

initializer:
        assignment_expression                   {$$ = create_node("initializer -> assignment_expression", 1, $1);}
        | LBRACE initializer_list RBRACE        {$$ = create_node("initializer -> { initializer_list }", 1, $2);}
        | LBRACE initializer_list COMMA RBRACE  {$$ = create_node("initializer -> { initializer_list , }", 2, $2);}
        ;

initializer_list:
        designation_opt initializer     {$$ = create_node("initializer_list -> designation_opt initializer", 2, $1, $2);}
        | initializer_list COMMA designation_opt initializer    {$$ = create_node("initializer_list -> initializer_list , designation_opt initializer", 3, $1, $3, $4);}
        ;

designation:
        designator_list ASSIGN                  {$$ = create_node("designation -> designator_list = ", 1, $1);}
        ;

designator_list:
        designator                              {$$ = create_node("designator_list -> designator", 1, $1);}
        | designator_list designator            {$$ = create_node("designator_list -> designator_list designator", 2, $1, $2);}
        ;

designator:
        LSQPAREN constant_expression RSQPAREN   {$$ = create_node("designator -> [ constant_expression ]", 1, $2);}
        | DOT IDENTIFIER                        {$$ = create_node("designator -> . IDENTIFIER", 0);}
        ;

/* Statements */

statement:
        labeled_statement               {$$ = create_node("statement -> labeled_statement", 1, $1);}
        | compound_statement            {$$ = create_node("statement -> compound_statement", 1, $1);}
        | expression_statement          {$$ = create_node("statement -> expression_statement", 1, $1);}
        | selection_statement           {$$ = create_node("statement -> selection_statement", 1, $1);}
        | iteration_statement           {$$ = create_node("statement -> iteration_statement", 1, $1);}
        | jump_statement                {$$ = create_node("statement -> jump_statement", 1, $1);}
        ;

labeled_statement:
        IDENTIFIER COLON statement      {$$ = create_node("labeled_statement -> IDENTIFIER : statement", 1, $3);}
        | CASE constant_expression COLON statement      {$$ = create_node("labeled_statement -> case constant_expression : statement", 2, $2, $4);}
        | DEFAULT COLON statement       {$$ = create_node("labeled_statement -> default : statement", 1, $3);}
        ;

compound_statement:
        LBRACE block_item_list_opt RBRACE       {$$ = create_node("compound_statement -> { block_item_list_opt }", 1, $2);}
        ;

block_item_list:
        block_item      {$$ = create_node("block_item_list -> block_item", 1, $1);}
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
        | IF LPAREN expression RPAREN statement ELSE statement  {$$ = create_node("selection_statement -> if ( expression ) statement else statement", 3, $3, $5, $7);}
        | SWITCH LPAREN expression RPAREN statement     {$$ = create_node("selection_statement -> switch ( expression ) statement", 2, $3, $5);}
        ;

iteration_statement:
        WHILE LPAREN expression RPAREN statement        {$$ = create_node("iteration_statement -> while ( expression ) statement", 2, $3, $5);}
        | DO statement WHILE LPAREN expression RPAREN SEMICOLON {$$ = create_node("iteration_statement -> do statement while ( expression ) ;", 2, $2, $5);}
        | FOR LPAREN expression_opt SEMICOLON expression_opt SEMICOLON expression_opt RPAREN statement  {$$ = create_node("iteration_statement -> for ( expression_opt ; expression_opt ; expression_opt ) statement", 4, $3, $5, $7, $9);}
        | FOR LPAREN declaration expression_opt SEMICOLON expression_opt RPAREN statement       {$$ = create_node("iteration_statement -> for ( declaration expression_opt ; expression_opt ) statement", 4, $3, $4, $6, $8);}
        ;

jump_statement:
        GOTO IDENTIFIER SEMICOLON               {$$ = create_node("jump_statement -> goto IDENTIFIER ;", 0);}
        | CONTINUE SEMICOLON                    {$$ = create_node("jump_statement -> continue ;", 0);}
        | BREAK SEMICOLON                       {$$ = create_node("jump_statement -> break ;", 0);}
        | RETURN expression_opt SEMICOLON       {$$ = create_node("jump_statement -> return expression_opt ;", 1, $2);}
        ;

/* External Definitions */

translation_unit:
        external_declaration    {$$ = create_node("translation_unit -> external_declaration", 1, $1); print_productions($$, 0);}
        | translation_unit external_declaration {$$ = create_node("translation_unit -> translation_unit external_declaration", 2, $1, $2);}
        ;

external_declaration:
        function_definition     {$$ = create_node("external_declaration -> function_definition", 1, $1);}
        | declaration           {$$ = create_node("external_declaration -> declaration", 1, $1);}
        ;

function_definition:
        declaration_specifiers declarator declaration_list_opt compound_statement {$$ = create_node("function_definition -> declaration_specifiers declarator declaration_list_opt compound_statement", 4, $1, $2, $3, $4);}
        ;

declaration_list:
        declaration             {$$ = create_node("declaration_list -> declaration", 1, $1);}
        | declaration_list declaration  {$$ = create_node("declaration_list -> declaration_list declaration", 2, $1, $2);}
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
        specifier_qualifier_list        {$$ = create_node("specifier_qualifier_list_opt -> specifier_qualifier_list", 1, $1);}
        | {/* Empty */}                 {$$ = create_node("specifier_qualifier_list_opt -> EPSILON", 0);}
        ;

pointer_opt:
        pointer                         {$$ = create_node("pointer_opt -> pointer", 1, $1);}
        | {/* Empty */}                 {$$ = create_node("pointer_opt -> EPSILON", 0);}
        ;

type_qualifier_list_opt:
        type_qualifier_list             {$$ = create_node("type_qualifier_list_opt -> type_qualifier_list", 1, $1);}
        | {/* Empty */}                 {$$ = create_node("type_qualifier_list_opt -> EPSILON", 0);}
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
        designation                     {$$ = create_node("designation_opt -> designation", 1, $1);}
        | {/* Empty */}                 {$$ = create_node("designation_opt -> EPSILON", 0);}
        ;

block_item_list_opt:
        block_item_list                 {$$ = create_node("block_item_list_opt -> block_item_list", 1, $1);}
        | {/* Empty */}                 {$$ = create_node("block_item_list_opt -> EPSILON", 0);}
        ;

declaration_list_opt:
        declaration_list                {$$ = create_node("declaration_list_opt -> declaration_list", 1, $1);}
        | {/* Empty */}                 {$$ = create_node("declaration_list_opt -> EPSILON", 0);}
        ;

/* Constants */

constant:
        INTEGER_CONSTANT
        | FLOATING_CONSTANT
        | CHAR_CONSTANT
        ;
%%

parse_tree_node* create_node(char* production_text, int num_children, ...) {
	parse_tree_node* new_node = (parse_tree_node*)malloc(sizeof(parse_tree_node));
	new_node->text = strdup(production_text);
	new_node->children = NULL;

	if(!num_children) return new_node;

	va_list args;
	va_start(args, num_children);
	new_node->children = add_child_node(va_arg(args, parse_tree_node*));
	node_child_list* mover = new_node->children;
	int ct = 1;
        while(ct < num_children){
		mover->next = add_child_node(va_arg(args, parse_tree_node*));
		mover = mover->next;
		ct++;
	}
        va_end(args);
        return new_node;
}

node_child_list* add_child_node(parse_tree_node* data){
	node_child_list* temp = (node_child_list*)malloc(sizeof(node_child_list));
	temp->child = data;
	temp->next = NULL;
	return temp;
}

print_productions(parse_tree_node* root, int level){
        if(root == NULL) return;
        print_spaces(level);
        printf("%s\n", root->text);
        node_child_list* mover = root->children;
        while(mover != NULL){
                print_productions(mover->child, level+1);
                mover = mover->next;
        }
}

print_spaces(int num){
        for(int i = 0; i < num; i++) printf("  ");
}