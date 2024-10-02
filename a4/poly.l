%{
    #include "poly.tab.h"
%}

%option noyywrap

BIN         [0-1]
DIG         [2-9]
WS          [ \t]
NEWLINE     [\n]
VAR         "x"
OP          "+"|"-"|"^"

%%

{VAR}       {return yytext[0];}
{OP}        {return yytext[0];}
{BIN}       {return yytext[0];}
{DIG}       {yylval.d = yytext[0]; return DIG;}
{NEWLINE}   {++yylineno;}
{WS}        {/* Ignore */}
.           {/* Ignore */}

%%