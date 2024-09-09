%{
    extern int yylex();
    extern int yylineno;
    void yyerror ( char * );    
%}

%token IDENTIFIER CONSTANT STRING_LITERAL
%token SIZEOF EXTERN STATIC AUTO REGISTER VOID CHAR SHORT INT LONG FLOAT DOUBLE SIGNED UNSIGNED BOOL_ COMPLEX_ IMAGINARY_ CONST RESTRICT VOLATILE INLINE CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN
%token LSQPAREN RSQPAREN LPAREN RPAREN LBRACE RBRACE
%token DOT ARROW INC DEC AMPERSAND ASTERISK PLUS MINUS TILDE NOT DIV MOD LEFT_SHIFT RIGHT_SHIFT LT GT LE GE EQ NE XOR OR LOGICAL_OR LOGICAL_AND QUESTION COLON SEMICOLON ELLIPSIS ASSIGN MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN XOR_ASSIGN OR_ASSIGN COMMA
%type primary_expression expression postfix_expression argument_expression_list argument_expression_list_opt type_name initializer_list assignment_expression unary_expression cast_expression multiplicative_expression additive_expression shift_expression relational_expression equality_expression and_expression exclusive_or_expression inclusive_or_expression logical_and_expression logical_or_expression conditional_expression constant_expression expression_opt
%type unary_operator assignment_operator
%type declaration declaration_specifiers declaration_specifiers_opt init_declarator_list init_declarator_list_opt storage_class_specifier type_specifier type_qualifier function_specifier init_declarator declarator initializer specifier_qualifier_list specifier_qualifier_list_opt pointer pointer_opt direct_declarator type_qualifier_list type_qualifier_list_opt assignment_expression_opt parameter_type_list identifier_list identifier_list_opt parameter_list parameter_declaration designation designation_opt designator_list designator
%type statement labeled_statement compound_statement expression_statement selection_statement iteration_statement jump_statement block_item block_item_list block_item_list_opt
%type translation_unit external_declaration function_definition declaration_list declaration_list_opt

%nonassoc PSEUDO_ELSE
%nonassoc ELSE

%start translation_unit

%%

/* Expressions */

primary_expression:
        IDENTIFIER
        | CONSTANT
        | STRING_LITERAL
        | LPAREN expression RPAREN
        ;

postfix_expression:
        primary_expression
        | postfix_expression LSQPAREN expression RSQPAREN
        | postfix_expression LPAREN argument_expression_list_opt RPAREN
        | postfix_expression DOT IDENTIFIER
        | postfix_expression ARROW IDENTIFIER
        | postfix_expression INC
        | postfix_expression DEC
        | LPAREN type_name RPAREN LBRACE initializer_list RBRACE
        | LPAREN type_name RPAREN LBRACE initializer_list COMMA RBRACE
        ;

argument_expression_list:
        assignment_expression
        | argument_expression_list COMMA assignment_expression
        ;

unary_expression:
        postfix_expression
        | INC unary_expression
        | DEC unary_expression
        | unary_operator cast_expression
        | SIZEOF unary_expression
        | SIZEOF LPAREN type_name RPAREN
        ;

unary_operator:
        AMPERSAND
        | ASTERISK
        | PLUS
        | MINUS
        | TILDE
        | NOT
        ;

cast_expression:
        unary_expression
        | LPAREN type_name RPAREN cast_expression
        ;

multiplicative_expression:
        cast_expression
        | multiplicative_expression ASTERISK cast_expression
        | multiplicative_expression DIV cast_expression
        | multiplicative_expression MOD cast_expression
        ;

additive_expression:
        multiplicative_expression
        | additive_expression PLUS multiplicative_expression
        | additive_expression MINUS multiplicative_expression
        ;

shift_expression:
        additive_expression
        | shift_expression LEFT_SHIFT additive_expression
        | shift_expression RIGHT_SHIFT additive_expression
        ;

relational_expression:
        shift_expression
        | relational_expression LT shift_expression
        | relational_expression GT shift_expression
        | relational_expression LE shift_expression
        | relational_expression GE shift_expression
        ;

equality_expression:
        relational_expression
        | equality_expression EQ relational_expression
        | equality_expression NE relational_expression
        ;

and_expression:
        equality_expression
        | and_expression AMPERSAND equality_expression
        ;

exclusive_or_expression:
        and_expression
        | exclusive_or_expression XOR and_expression
        ;

inclusive_or_expression:
        exclusive_or_expression
        | inclusive_or_expression OR exclusive_or_expression
        ;

logical_and_expression:
        inclusive_or_expression
        | logical_and_expression LOGICAL_AND inclusive_or_expression
        ;

logical_or_expression:
        logical_and_expression
        | logical_or_expression LOGICAL_OR logical_and_expression
        ;

conditional_expression:
        logical_or_expression
        | logical_or_expression QUESTION expression COLON conditional_expression
        ;

assignment_expression:
        conditional_expression
        | unary_expression assignment_operator assignment_expression
        ;

assignment_operator:
        ASSIGN
        | MUL_ASSIGN
        | DIV_ASSIGN
        | MOD_ASSIGN
        | ADD_ASSIGN
        | SUB_ASSIGN
        | LEFT_ASSIGN
        | RIGHT_ASSIGN
        | AND_ASSIGN
        | XOR_ASSIGN
        | OR_ASSIGN
        ;

expression:
        assignment_expression
        | expression COMMA assignment_expression
        ;

constant_expression:
        conditional_expression
        ;
    
/* Declarations */

declaration:
        declaration_specifiers init_declarator_list_opt SEMICOLON
        ;

declaration_specifiers:
        storage_class_specifier declaration_specifiers_opt
        | type_specifier declaration_specifiers_opt
        | type_qualifier declaration_specifiers_opt
        | function_specifier declaration_specifiers_opt
        ;

init_declarator_list:
        init_declarator
        | init_declarator_list COMMA init_declarator
        ;

init_declarator:
        declarator
        | declarator ASSIGN initializer
        ;

storage_class_specifier:
        EXTERN
        | STATIC
        | AUTO
        | REGISTER
        ;

type_specifier:
        VOID
        | CHAR
        | SHORT
        | INT
        | LONG
        | FLOAT
        | DOUBLE
        | SIGNED
        | UNSIGNED
        | BOOL_
        | COMPLEX_
        | IMAGINARY_
        ;

specifier_qualifier_list:
        type_specifier specifier_qualifier_list_opt
        | type_qualifier specifier_qualifier_list_opt
        ;

type_qualifier:
        CONST
        | RESTRICT
        | VOLATILE
        ;

function_specifier:
        INLINE
        ;

declarator:
        pointer_opt direct_declarator
        ;

direct_declarator:
        IDENTIFIER
        | LPAREN declarator RPAREN
        | direct_declarator LSQPAREN type_qualifier_list_opt assignment_expression_opt RSQPAREN
        | direct_declarator LSQPAREN STATIC type_qualifier_list_opt assignment_expression RSQPAREN
        | direct_declarator LSQPAREN type_qualifier_list STATIC assignment_expression RSQPAREN
        | direct_declarator LSQPAREN type_qualifier_list_opt ASTERISK RSQPAREN
        | direct_declarator LPAREN parameter_type_list RPAREN
        | direct_declarator LPAREN identifier_list_opt RPAREN
        ;

pointer:
        ASTERISK type_qualifier_list_opt
        | ASTERISK type_qualifier_list_opt pointer
        ;

type_qualifier_list:
        type_qualifier
        | type_qualifier_list type_qualifier
        ;

parameter_type_list:
        parameter_list
        | parameter_list COMMA ELLIPSIS
        ;

parameter_list:
        parameter_declaration
        | parameter_list COMMA parameter_declaration
        ;

parameter_declaration:
        declaration_specifiers declarator
        | declaration_specifiers
        ;

identifier_list:
        IDENTIFIER
        | identifier_list COMMA IDENTIFIER
        ;

type_name:
        specifier_qualifier_list
        ;

initializer:
        assignment_expression
        | LBRACE initializer_list RBRACE
        | LBRACE initializer_list COMMA RBRACE
        ;

initializer_list:
        designation_opt initializer
        | initializer_list COMMA designation_opt initializer
        ;

designation:
        designator_list ASSIGN
        ;

designator_list:
        designator
        | designator_list designator
        ;

designator:
        LSQPAREN constant_expression RSQPAREN
        | DOT IDENTIFIER
        ;

/* Statements */

statement:
        labeled_statement
        | compound_statement
        | expression_statement
        | selection_statement
        | iteration_statement
        | jump_statement
        ;

labeled_statement:
        IDENTIFIER COLON statement
        | CASE constant_expression COLON statement
        | DEFAULT COLON statement
        ;

compound_statement:
        LBRACE block_item_list_opt RBRACE
        ;

block_item_list:
        block_item
        | block_item_list block_item
        ;

block_item:
        declaration
        | statement
        ;

expression_statement:
        expression_opt SEMICOLON
        ;

selection_statement:
        IF LPAREN expression RPAREN statement   %prec PSEUDO_ELSE
        | IF LPAREN expression RPAREN statement ELSE statement
        | SWITCH LPAREN expression RPAREN statement
        ;

iteration_statement:
        WHILE LPAREN expression RPAREN statement
        | DO statement WHILE LPAREN expression RPAREN SEMICOLON
        | FOR LPAREN expression_opt SEMICOLON expression_opt SEMICOLON expression_opt RPAREN statement
        | FOR LPAREN declaration expression_opt SEMICOLON expression_opt RPAREN statement
        ;

jump_statement:
        GOTO IDENTIFIER SEMICOLON
        | CONTINUE SEMICOLON
        | BREAK SEMICOLON
        | RETURN expression_opt SEMICOLON
        ;

/* External Definitions */

translation_unit:
        external_declaration
        | translation_unit external_declaration
        ;

external_declaration:
        function_definition
        | declaration
        ;

function_definition:
        declaration_specifiers declarator declaration_list_opt compound_statement
        ;

declaration_list:
        declaration
        | declaration_list declaration
        ;


/* Optionals */

argument_expression_list_opt:
        argument_expression_list
        | {/* Empty */}
        ;

declaration_specifiers_opt:
        declaration_specifiers
        | {/* Empty */}
        ;

init_declarator_list_opt:
        init_declarator_list
        | {/* Empty */}
        ;

specifier_qualifier_list_opt:
        specifier_qualifier_list
        | {/* Empty */}
        ;

pointer_opt:
        pointer
        | {/* Empty */}
        ;

type_qualifier_list_opt:
        type_qualifier_list
        | {/* Empty */}
        ;

expression_opt:
        expression
        | {/* Empty */}
        ;

assignment_expression_opt:
        assignment_expression
        | {/* Empty */}
        ;

identifier_list_opt:
        identifier_list
        | {/* Empty */}
        ;

designation_opt:
        designation
        | {/* Empty */}
        ;

block_item_list_opt:
        block_item_list
        | {/* Empty */}
        ;

declaration_list_opt:
        declaration_list
        | {/* Empty */}
        ;


%%