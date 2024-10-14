%{
    #include "expr.tab.h"
%}

%option noyywrap

LETTER      [A-Za-z_]
DIGIT       [0-9]
LETDIG      {LETTER}|{DIGIT}
ID          {LETTER}{LETDIG}*
C_OP        "+"|"-"|"*"|"/"|"%"
EXPO        "**"
SET         "set"
NUM         [+-]?{DIGIT}+
LINE        [\n]
WS          [ \t]
PAR         "("|")"

%%

{SET}       {return SET;}
{ID}        {yylval.text=strdup(yytext); return ID;}
{C_OP}      {yylval.num=yytext[0]; return yytext[0];}
{EXPO}      {yylval.num=EXPO; return EXPO;}
{NUM}       {yylval.num=atoi(yytext); return NUM;}
{PAR}       {return yytext[0];}
{LINE}      {yylineno++;}
{WS}        {/* Ignore */}
.           {/* Ignore */}

%%