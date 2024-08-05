#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lex.yy.c"

#define ENVIRONMENT 1
#define COMMAND 2
#define DISPLAYED_MATH 3
#define INLINE_MATH 4
#define newline() printf("\n")

typedef struct _node
{
    char *name;
    int ct;
    struct _node *next;
} node;
typedef node *symbolTable;

symbolTable addToTable(symbolTable T, char *id)
{
    node *p;

    p = T;
    while (p)
    {
        if (!strcmp(p->name, id))
        {
            p->ct++;
            return T;
        }
        p = p->next;
    }
    p = (node *)malloc(sizeof(node));
    p->name = (char *)malloc((strlen(id) + 1) * sizeof(char));
    p->ct = 1;
    strcpy(p->name, id);
    p->next = T;
    return p;
}

void printSymbolTable(symbolTable T)
{
    symbolTable curr = T;
    while (curr)
    {
        printf("\t%s (%d)\n", curr->name, curr->ct);
        curr = curr->next;
    }
}

int main()
{
    int nextok;
    symbolTable Commands = NULL;
    symbolTable Environments = NULL;
    int inline_eq = 0, display_eq = 0;

    while ((nextok = yylex()))
    {
        switch (nextok)
        {
        case COMMAND:
            Commands = addToTable(Commands, yytext);
            break;
        case ENVIRONMENT:
            int x = 6;
            for (int i = 6; i < yyleng; i++)
            {
                if (yytext[i] == '{')
                {
                    x = i + 1;
                    break;
                }
            }
            int len = yyleng - x - 1;
            char *env = (char *)malloc((len + 1) * sizeof(char));
            strncpy(env, yytext + x, len);
            Environments = addToTable(Environments, env);
            break;
        case DISPLAYED_MATH:
            display_eq++;
            break;
        case INLINE_MATH:
            inline_eq++;
            break;
        }
    }

    symbolTable curr = NULL;
    printf("Commands Used: \n"); // Commands except /begin and /end
    printSymbolTable(Commands);

    newline();

    printf("Environments Used: \n");
    curr = Environments;
    printSymbolTable(Environments);

    newline();

    printf("%d math equations found\n", inline_eq / 2);
    printf("%d displayed equations found\n", display_eq / 2);
}