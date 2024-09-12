%{
#define KEYWORD             1
#define IDENTIFIER          2
#define INTEGER_CONSTANT    3
#define FLOATING_CONSTANT   4
#define CHAR_CONSTANT       5
#define STRING_LITERAL      6
#define PUNCTUATOR          7
#define COMMENT             8
#define INVALID             -1

int _yylineno_ = 1;
%}

%option noyywrap

KEYWORD                 "auto"|"break"|"case"|"char"|"const"|"continue"|"default"|"do"|"double"|"else"|"enum"|"extern"|"float"|"for"|"goto"|"if"|"inline"|"int"|"long"|"register"|"restrict"|"return"|"short"|"signed"|"sizeof"|"static"|"struct"|"switch"|"typedef"|"union"|"unsigned"|"void"|"volatile"|"while"|"_Bool"|"_Complex"|"_Imaginary"

IDENTIFIER_NONDIGIT     [_A-Za-z]
DIGIT                   [0-9]
DIGIT_SEQUENCE          {DIGIT}+
ALPHA_NUM               {IDENTIFIER_NONDIGIT}|{DIGIT}
IDENTIFIER              {IDENTIFIER_NONDIGIT}{ALPHA_NUM}*

SIGN                    [+-]

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

{NEWLINE}               { ++_yylineno_; }                 
{COMMENT}               { return COMMENT; }
{KEYWORD}               { return KEYWORD; } 
{IDENTIFIER}            { return IDENTIFIER; }  
{FLOATING_CONSTANT}     { return FLOATING_CONSTANT; }
{INTEGER_CONSTANT}      { return INTEGER_CONSTANT; }
{CHAR_CONSTANT}         { return CHAR_CONSTANT; }
{STRING_LITERAL}        { return STRING_LITERAL; }
{PUNCTUATOR}            { return PUNCTUATOR; }
{WS}                    { /* ignore */ }
.                       { return INVALID; }

%%