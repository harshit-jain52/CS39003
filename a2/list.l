%{
#define ID 1
#define NUM 2
#define OP 3
#define LB 4
#define RB 5
#define INVALID -1
%}

%option noyywrap

LETTER [A-Za-z_]
DIGIT [0-9]
LETDIG {LETTER}|{DIGIT}
ID {LETTER}{LETDIG}*
OP "+"|"-"|"*"|"/"|"%"
NUM [-]?{DIGIT}+
LB "("
RB ")"
WS [ \t\n]


%%
{LB} return LB;
{RB} return RB;
{ID} return ID;
{NUM} return NUM;
{OP} return OP;
{WS} {}
. return INVALID;
%%