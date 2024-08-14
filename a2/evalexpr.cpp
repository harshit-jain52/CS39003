#include <iostream>
#include <stack>
#include "lex.yy.c" // defined: ID, NUM, OP, LB, RB, INVALID
#define EXPR 6
#define ARG 7

using namespace std;
typedef long long ll;

struct node
{
    char *name;
    node *next;
};

typedef node *symbolTable;

node *makeNode(char *id)
{
    node *p = (node *)malloc(sizeof(node));
    p->name = (char *)malloc((strlen(id) + 1) * sizeof(char));
    strcpy(p->name, id);

    return p;
}

node *findInTable(symbolTable head, char *id)
{
    node *mover = head;

    while (mover)
    {
        if (!strcmp(mover->name, id))
            return mover;
        mover = mover->next;
    }
    return NULL;
}

symbolTable addToTable(symbolTable &head, char *id)
{
    node *tmp = findInTable(head, id);
    if (tmp)
        return tmp;

    if (head == NULL)
    {
        head = makeNode(id);
        return head;
    }

    node *mover = head;
    while (mover->next)
        mover = mover->next;

    mover->next = makeNode(id);
    return mover->next;
}

struct TreeNode
{
    TreeNode *left;
    TreeNode *right;
    TreeNode *par;
    int type;
    union
    {
        char op;
        symbolTable id;
        symbolTable num;
    } entry;

    TreeNode()
    {
        left = right = par = NULL;
        type = 0;
    }
};

string operator*(const string &s, int n)
{
    string res = "";
    for (int i = 0; i < n; i++)
        res += s;
    return res;
}

int numTabs = -1;
string arrow = "--->";

void printParseTree(TreeNode *curr)
{
    if (curr == NULL)
        return;

    if (curr->par)
        cout << (string) "\t" * numTabs + arrow;

    if (curr->type == OP)
    {
        printf("OP(%c)\n", curr->entry.op);
        numTabs++;
        printParseTree(curr->left);
        printParseTree(curr->right);
        numTabs--;
    }
    else if (curr->type == ID)
    {
        printf("ID(%s)\n", curr->entry.id->name);
    }
    else if (curr->type == NUM)
    {
        printf("NUM(%s)\n", curr->entry.num->name);
    }
}

void cleanTree(TreeNode *curr)
{
    if (curr == NULL)
        return;

    cleanTree(curr->left);
    cleanTree(curr->right);

    delete curr;
}

void cleanTable(symbolTable &head)
{
    node *mover = head;
    while (mover)
    {
        node *tmp = mover;
        mover = mover->next;
        free(tmp->name);
        free(tmp);
    }
    head = NULL;
}

void printSymbolTable(symbolTable X)
{
    node *mover = X;
    while (mover)
    {
        cout << mover->name << endl;
        mover = mover->next;
    }
}

void throwError(string err, TreeNode *curr, symbolTable T = NULL, symbolTable C = NULL)
{
    cout << "*** Error: " << err << endl;
    while (curr && curr->par) // Go to the root of the parse tree
        curr = curr->par;

    cleanTree(curr); // Free the memory allocated for the parse tree
    cleanTable(T);   // Free the memory allocated for the symbol table T
    cleanTable(C);   // Free the memory allocated for the symbol table C
    exit(1);
}

ll evaluateExpr(TreeNode *curr)
{
    if (curr->type == OP)
    {
        ll l = evaluateExpr(curr->left);
        ll r = evaluateExpr(curr->right);

        char op = curr->entry.op;
        if (op == '+')
            return l + r;
        if (op == '-')
            return l - r;
        if (op == '*')
            return l * r;
        if (op == '/')
        {
            if (r == 0)
                throwError("Division by Zero", curr);
            return l / r;
        }
        if (op == '%')
        {
            if (r == 0)
                throwError("Division by Zero", curr);
            return l % r;
        }
    }
    else if (curr->type == ID)
        return stoll(curr->entry.id->name);
    else if (curr->type == NUM)
        return stoll(curr->entry.num->name);
    return 0;
}

int main()
{
    int nextTok;
    stack<int> inputStack;

    /*
    Production Rules:-
    1. EXPR -> ( OP ARG ARG )
    2. OP -> +
    3. OP -> -
    4. OP -> *
    5. OP -> /
    6. OP -> %
    7. ARG -> id
    8. ARG -> num
    9. ARG -> EXPR

    Parsing Table:-
            (   )   +   -   *   /   %   id  num
    EXPR    1
    OP              2   3   4   5   6
    ARG     9                            7   8
    */

    inputStack.push(EXPR);
    symbolTable T = NULL, C = NULL; // T for ID, C for NUM

    TreeNode *curr = NULL;
    while (!inputStack.empty() && (nextTok = yylex()))
    {
        if (nextTok == OP && inputStack.top() == OP) // OP -> + | - | * | / | %
        {
            TreeNode *tmp = new TreeNode;

            tmp->type = OP;
            tmp->entry.op = yytext[0];

            if (curr == NULL) // First operator
            {
                tmp->par = NULL;
                curr = tmp;
            }
            else
            {
                tmp->par = curr;
                if (curr->left == NULL)
                    curr->left = tmp;
                else if (curr->right == NULL)
                    curr->right = tmp;
                curr = tmp;
            }
            inputStack.pop();
        }
        else if (nextTok == RB && inputStack.top() == RB) // EXPR -> ( OP ARG ARG )
        {
            if (curr->par)
                curr = curr->par; // On end of expression, go to the parent node in parse tree
            inputStack.pop();
        }
        else if (nextTok == LB && (inputStack.top() == EXPR || inputStack.top() == ARG)) // ARG -> EXPR -> ( OP ARG ARG )
        {
            inputStack.pop();
            inputStack.push(RB);
            inputStack.push(ARG);
            inputStack.push(ARG);
            inputStack.push(OP);
        }
        else if (nextTok == NUM && inputStack.top() == ARG) // ARG -> NUM
        {
            TreeNode *tmp = new TreeNode;
            tmp->type = NUM;
            tmp->entry.num = addToTable(C, yytext);
            tmp->par = curr;

            if (curr->left == NULL)
                curr->left = tmp;
            else if (curr->right == NULL)
                curr->right = tmp;
            inputStack.pop();
        }
        else if (nextTok == ID && inputStack.top() == ARG) // ARG -> ID
        {
            TreeNode *tmp = new TreeNode;

            tmp->type = ID;
            tmp->entry.id = addToTable(T, yytext);
            tmp->par = curr;

            if (curr->left == NULL)
                curr->left = tmp;
            else if (curr->right == NULL)
                curr->right = tmp;
            inputStack.pop();
        }
        else if (inputStack.top() == RB)
        {
            throwError("Right parenthesis expected in place of " + (string)yytext, curr, T, C);
        }
        else if (inputStack.top() == EXPR)
        {
            throwError("Left parenthesis expected in place of " + (string)yytext, curr, T, C);
        }
        else if (inputStack.top() == ARG)
        {
            throwError("ID/NUM/LP expected in place of " + (string)yytext, curr, T, C);
        }
        else if (inputStack.top() == OP)
        {
            if (nextTok == INVALID)
                throwError("Invalid operator " + (string)yytext + " found", curr, T, C);
            throwError("Operator expected in place of " + (string)yytext, curr, T, C);
        }
    }

    if (!inputStack.empty())
    {
        throwError("Expression not complete", curr, T, C);
    }

    cout << "Parsing is successful\n";
    printParseTree(curr);

    // printSymbolTable(T);
    // printSymbolTable(C);

    if (T)
        cout << "Reading variable values from the input\n";

    node *mover = T;
    while ((nextTok = yylex()) && mover)
    {
        if (nextTok == NUM)
        {
            // Replace the name of the variable with the value
            printf("%s = ", mover->name);
            free(mover->name);
            mover->name = (char *)malloc((strlen(yytext) + 1) * sizeof(char));
            strcpy(mover->name, yytext);
            cout << mover->name << endl;
            mover = mover->next;
        }
        else
        {
            throwError("Invalid Argument: " + (string)yytext, curr, T, C);
        }
    }

    if (mover)
        throwError("Less arguments provided than expected", curr, T, C);

    // printParseTree(curr);
    ll val = evaluateExpr(curr);
    cout << "The expression evaluates to " << val << endl;

    cleanTree(curr); // Free the memory allocated for the parse tree
    cleanTable(T);   // Free the memory allocated for the symbol table T
    cleanTable(C);   // Free the memory allocated for the symbol table C
}
