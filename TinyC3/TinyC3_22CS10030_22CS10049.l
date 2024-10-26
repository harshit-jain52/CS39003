%{
    #include "TinyC3_22CS10030_22CS10049_translator.h"
    #include "y.tab.h"
%}

%option noyywrap

AUTO		            "auto"
BREAK		            "break"
CASE		            "case"
CHAR		            "char"
CONST		            "const"
CONTINUE		        "continue"
DEFAULT		            "default"
DO		                "do"
DOUBLE		            "double"
ELSE		            "else"
ENUM		            "enum"
EXTERN		            "extern"
FLOAT		            "float"
FOR		                "for"
GOTO		            "goto"
IF		                "if"
INLINE		            "inline"
INT		                "int"
LONG		            "long"
REGISTER		        "register"
RESTRICT		        "restrict"
RETURN		            "return"
SHORT		            "short"
SIGNED		            "signed"
SIZEOF		            "sizeof"
STATIC		            "static"
STRUCT		            "struct"
SWITCH		            "switch"
TYPEDEF		            "typedef"
UNION		            "union"
UNSIGNED		        "unsigned"
VOID		            "void"
VOLATILE		        "volatile"
WHILE		            "while"
BOOL_		            "_Bool"
COMPLEX_		        "_Complex"
IMAGINARY_		        "_Imaginary"

LSQPAREN                "["
RSQPAREN                "]"
LPAREN                  "("
RPAREN                  ")"
LBRACE                  "{"
RBRACE                  "}"
DOT                     "."
ARROW                   "->"
INC                     "++"
DEC                     "--"
AMPERSAND               "&"
ASTERISK                "*"
PLUS                    "+"
MINUS                   "-"
TILDE                   "~"
NOT                     "!"
DIV                     "/"
MOD                     "%"
LEFT_SHIFT               "<<"
RIGHT_SHIFT              ">>"
LT                      "<"
GT                      ">"
LE                      "<="
GE                      ">="
EQ                      "=="
NE                      "!="
XOR                     "^"
OR                      "|"
LOGICAL_AND             "&&"
LOGICAL_OR              "||"
QUESTION                "?"
COLON                   ":"
SEMICOLON               ";"
ELLIPSIS                "..."
ASSIGN                  "="
MUL_ASSIGN              "*="
DIV_ASSIGN              "/="
MOD_ASSIGN              "%="
ADD_ASSIGN              "+="
SUB_ASSIGN              "-="
LEFT_ASSIGN             "<<="
RIGHT_ASSIGN            ">>="
AND_ASSIGN              "&="
XOR_ASSIGN              "^="
OR_ASSIGN               "|="
COMMA                   ","
HASH                    "#"

IDENTIFIER_NONDIGIT     [_A-Za-z]
DIGIT                   [0-9]
DIGIT_SEQUENCE          {DIGIT}+
ALPHA_NUM               {IDENTIFIER_NONDIGIT}|{DIGIT}
IDENTIFIER              {IDENTIFIER_NONDIGIT}{ALPHA_NUM}*

SIGN                    [-+]

INTEGER_CONSTANT        {DIGIT_SEQUENCE}
FRACTIONAL_CONSTANT     {DIGIT_SEQUENCE}\.|{DIGIT_SEQUENCE}?\.{DIGIT_SEQUENCE}
EXPONENT_PART           [eE]{SIGN}?{DIGIT_SEQUENCE}
FLOATING_CONSTANT       {FRACTIONAL_CONSTANT}{EXPONENT_PART}?|{DIGIT_SEQUENCE}{EXPONENT_PART}

ESCAPE_SEQ              \\['"?\\abfnrtv]
C_CHAR                  [^'\\\n]|{ESCAPE_SEQ}
CHAR_CONSTANT           \'{C_CHAR}\'

S_CHAR                  [^"\\\n]|{ESCAPE_SEQ}
S_CHAR_SEQ              {S_CHAR}+
STRING_LITERAL          \"{S_CHAR_SEQ}?\"

COMMENT_START           "/*"
COMMENT_END             "*/"
COMMENT_BODY            [^*]|[*][^/]
MULTI_LINE_COMMENT      {COMMENT_START}{COMMENT_BODY}*{COMMENT_END}

SINGLE_LINE_COMMENT     \/\/[^\n]*

COMMENT                {MULTI_LINE_COMMENT}|{SINGLE_LINE_COMMENT}

WS                      [ \t]
NEWLINE                 \n

%%

{COMMENT}               { /* ignore */ }
{NEWLINE}               { ++yylineno; }                 

{AUTO}		            { return AUTO; }
{BREAK}		            { return BREAK; }
{CASE}		            { return CASE; }
{CHAR}		            { return CHAR; }
{CONST}		            { return CONST; }
{CONTINUE}		        { return CONTINUE; }
{DEFAULT}		        { return DEFAULT; }
{DO}		            { return DO; }
{DOUBLE}		        { return DOUBLE; }
{ELSE}		            { return ELSE; }
{ENUM}		            { return ENUM; }
{EXTERN}		        { return EXTERN; }
{FLOAT}		            { return FLOAT; }
{FOR}		            { return FOR; }
{GOTO}		            { return GOTO; }
{IF}		            { return IF; }
{INLINE}		        { return INLINE; }
{INT}		            { return INT; }
{LONG}		            { return LONG; }
{REGISTER}		        { return REGISTER; }
{RESTRICT}		        { return RESTRICT; }
{RETURN}		        { return RETURN; }
{SHORT}		            { return SHORT; }
{SIGNED}		        { return SIGNED; }
{SIZEOF}		        { return SIZEOF; }
{STATIC}		        { return STATIC; }
{STRUCT}		        { return STRUCT; }
{SWITCH}		        { return SWITCH; }
{TYPEDEF}		        { return TYPEDEF; }
{UNION}		            { return UNION; }
{UNSIGNED}		        { return UNSIGNED; }
{VOID}		            { return VOID; }
{VOLATILE}		        { return VOLATILE; }
{WHILE}		            { return WHILE; }
{BOOL_}		            { return BOOL_; }
{COMPLEX_}		        { return COMPLEX_; }
{IMAGINARY_}		    { return IMAGINARY_; }

{IDENTIFIER}            { yylval.sym = currentST->lookup(yytext); return IDENTIFIER; }  
{FLOATING_CONSTANT}     { yylval.text = strdup(yytext); return FLOATING_CONSTANT; }
{INTEGER_CONSTANT}      { yylval.text = strdup(yytext); return INTEGER_CONSTANT; }
{CHAR_CONSTANT}         { yylval.text = strdup(yytext); return CHAR_CONSTANT; }
{STRING_LITERAL}        { yylval.text = strdup(yytext); return STRING_LITERAL; }

{LSQPAREN}              { return LSQPAREN; }
{RSQPAREN}              { return RSQPAREN; }
{LPAREN}                { return LPAREN; }
{RPAREN}                { return RPAREN; }
{LBRACE}                { return LBRACE; }
{RBRACE}                { return RBRACE; }
{DOT}                   { return DOT; }
{ARROW}                 { return ARROW; }
{INC}                   { return INC; }
{DEC}                   { return DEC; }
{AMPERSAND}             { return AMPERSAND; }
{ASTERISK}              { yylval.op = strdup(yytext); return ASTERISK; }
{PLUS}                  { yylval.op = strdup(yytext); return PLUS; }
{MINUS}                 { yylval.op = strdup(yytext); return MINUS; }
{TILDE}                 { return TILDE; }
{NOT}                   { return NOT; }
{DIV}                   { yylval.op = strdup(yytext); return DIV; }
{MOD}                   { yylval.op = strdup(yytext); return MOD; }
{LEFT_SHIFT}            { yylval.op = strdup(yytext); return LEFT_SHIFT; }
{RIGHT_SHIFT}           { yylval.op = strdup(yytext); return RIGHT_SHIFT; }
{LT}                    { yylval.op = strdup(yytext); return LT; }
{GT}                    { yylval.op = strdup(yytext); return GT; }
{LE}                    { yylval.op = strdup(yytext); return LE; }
{GE}                    { yylval.op = strdup(yytext); return GE; }
{EQ}                    { yylval.op = strdup(yytext); return EQ; }
{NE}                    { yylval.op = strdup(yytext); return NE; }
{XOR}                   { return XOR; }
{OR}                    { return OR; }
{LOGICAL_AND}           { return LOGICAL_AND; }
{LOGICAL_OR}            { return LOGICAL_OR; }
{QUESTION}              { return QUESTION; }
{COLON}                 { return COLON; }
{SEMICOLON}             { return SEMICOLON; }
{ELLIPSIS}              { return ELLIPSIS; }
{ASSIGN}                { return ASSIGN; }
{MUL_ASSIGN}            { return MUL_ASSIGN; }
{DIV_ASSIGN}            { return DIV_ASSIGN; }
{MOD_ASSIGN}            { return MOD_ASSIGN; }
{ADD_ASSIGN}            { return ADD_ASSIGN; }
{SUB_ASSIGN}            { return SUB_ASSIGN; }
{LEFT_ASSIGN}           { return LEFT_ASSIGN; }
{RIGHT_ASSIGN}          { return RIGHT_ASSIGN; }
{AND_ASSIGN}            { return AND_ASSIGN; }
{XOR_ASSIGN}            { return XOR_ASSIGN; }
{OR_ASSIGN}             { return OR_ASSIGN; }
{COMMA}                 { return COMMA; }
{HASH}                  { return HASH; }

{WS}                    { /* ignore */ }
.                       { /* ignore */ }


%%