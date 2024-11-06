%{
    #include "prog.tab.h"
    extern void yyerror();
%}

%option noyywrap

SET         "set"
WHEN        "when"
LOOP        "loop"
WHILE       "while"

LETTER      [A-Za-z_]
DIGIT       [0-9]
LETDIG      {LETTER}|{DIGIT}
IDEN        {LETTER}{LETDIG}*
NUMB        [+-]?{DIGIT}+

OP          "+"|"-"|"*"|"/"|"%"
EQ          "="
NE          "/="
LT          "<"
GT          ">"
LE          "<="
GE          ">="

PAR         "("|")"

LINE        [\n]
WS          [ \t]

%%

{SET}       {return SET;}
{WHEN}      {return WHEN;}
{LOOP}      {return LOOP;}
{WHILE}     {return WHILE;}
{IDEN}      {yylval.text=strdup(yytext); return IDEN;}
{NUMB}      {yylval.text=strdup(yytext); return NUMB;}
{OP}        {return yytext[0];}
{EQ}        {return EQ;}
{NE}        {return NE;}
{LT}        {return LT;}
{GT}        {return GT;}
{LE}        {return LE;}
{GE}        {return GE;}
{PAR}       {return yytext[0];}
{LINE}      {yylineno++;}
{WS}        {/* Ignore */}
.           {yyerror("Invalid Token");}

%%