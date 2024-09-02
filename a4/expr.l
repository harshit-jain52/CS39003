%{
    #include <stdlib.h>
    #include <string.h>
    #include "y.tab.h"
%}

%option noyywrap

LETTER      [A-Za-z_]
DIGIT       [0-9]
LETDIG      {LETTER}|{DIGIT}
ID          {LETTER}{LETDIG}*
PLUS        "+"
MINUS       "-"
MUL         "*"
DIV         "/"
MOD         "%"
EXPO        "**"
SET         "set"
NUM         [-]?{DIGIT}+
LINE        [\n]
WS          [ \t]
PAR         "("|")"

%%

{SET}       {return SET;}
{ID}        {yylval.text=(char*)malloc((yyleng+1)*sizeof(char));
            strcpy(yylval.text,yytext);           
            return ID;}
{PLUS}      {yylval.num=PLUS; return PLUS;}
{MINUS}     {yylval.num=MINUS; return MINUS;}
{MUL}       {yylval.num=MUL; return MUL;}
{DIV}       {yylval.num=DIV; return DIV;}
{MOD}       {yylval.num=MOD; return MOD;}
{EXPO}      {yylval.num=EXPO; return EXPO;}
{NUM}       {yylval.num=atoi(yytext); return NUM;}
{PAR}       {return yytext[0];}
{LINE}      {yylineno++;}
{WS}        {/* Ignore */}
.           {/* Ignore */}

%%