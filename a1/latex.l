%{
#include <stdio.h>
#define ENVIRONMENT 1
#define COMMAND 2
#define DISPLAYED_MATH 3
#define INLINE_MATH 4
%}

%option noyywrap

LETTERS [A-Za-z]+
SPECIAL [^A-Za-z]
WS [ \t\n]
ENVIRONMENT \\begin{WS}*\{{LETTERS}\}
ENVEND \\end{WS}*\{{LETTERS}\}
COMMAND \~|\\{LETTERS}|\\{SPECIAL}
DISPLAYED_MATH \$\$|\\\[|\\\]
INLINE_MATH \$
COMMENT \%.*\n

%%
{COMMENT}
{INLINE_MATH} return INLINE_MATH;
{DISPLAYED_MATH} return DISPLAYED_MATH;
{ENVIRONMENT} return ENVIRONMENT;
{ENVEND} {}
{COMMAND} return COMMAND;
{WS} {}
. {}
%%