%{
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

CONSTANT                {INTEGER_CONSTANT}|{FLOATING_CONSTANT}|{CHAR_CONSTANT}

BRACKETS                "["|"]"|"("|")"|"{"|"}"
OPERATOR                "."|"->"|"++"|"--"|"&"|"*"|"+"|"-"|"~"|"!"|"/"|"%"|"<<"|">>"|"<"|">"|"<="|">="|"=="|"!="|"^"|"|"|"&&"|"||"|"?"|":"|";"|"..."|"="|"*="|"/="|"%="|"+="|"-="|"<<="|">>="|"&="|"^="|"|="|","|"#"
PUNCTUATOR              {BRACKETS}|{OPERATOR}

COMMENT_START           "/*"
COMMENT_END             "*/"
COMMENT_BODY            [^*]|[*][^/]
MULTI_LINE_COMMENT      {COMMENT_START}{COMMENT_BODY}*{COMMENT_END}

SINGLE_LINE_COMMENT     \/\/[^\n]*

COMMENT                {MULTI_LINE_COMMENT}|{SINGLE_LINE_COMMENT}

WS                      [ \t]
NEWLINE                 \n

%%

{NEWLINE}               { ++yylineno; }                 
{IMAGINARY_}		    { return IMAGINARY_; }
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
{COMMENT}               { return COMMENT; }
{BOOL_}		            { return BOOL_; }
{COMPLEX_}		        { return COMPLEX_; }

{IDENTIFIER}            { return IDENTIFIER; }  
{CONSTANT}              { return CONSTANT; }
{STRING_LITERAL}        { return STRING_LITERAL; }
{PUNCTUATOR}            { return PUNCTUATOR; }
{WS}                    { /* ignore */ }
.                       { /* ignore */ }


%%