#include "lex.yy.c"
#include "y.tab.c"
#include <setjmp.h>

static jmp_buf parseEnv;

void throwError(char *err)
{
    fprintf(stderr, "***Error at line %d: %s\n", yylineno, err);
    freeTable(ST);
    longjmp(parseEnv, 1);
}

symbol createSymbol(char* name, ll data){
    symbol s = (struct symbol_*)malloc(sizeof(struct symbol_));
    s->name = strdup(name);
    s->val = data;
    return s;
}

symbolTable insertTable(symbolTable T, char* id, ll data){    
    symbolTable mover = T;
    while(mover){
        if(mover->type==ID && !strcmp(mover->entry.id.name, id)){
            mover->entry.id.val = data;
            return T;
        }
        mover = mover->next;
    }

    struct symnode* p = (struct symnode*)malloc(sizeof(struct symnode));
    p->type = ID;
    p->entry.id.name = strdup(id);
    p->entry.id.val = data;
    p->next = T;

    return p;
}

ll findTable(symbolTable T, char* id){
    symbolTable mover = T;
    while(mover){
        if(mover->type==ID && !strcmp(mover->entry.id.name, id)){
            return mover->entry.id.val;
        }
        mover = mover->next;
    }

    char* err = (char *)malloc((25+strlen(id)*sizeof(char)));
    sprintf(err,"Undeclared identifier %s",id);
    throwError(err);
}

symbolTable insertNum(symbolTable T, ll data){
    struct symnode* p = (struct symnode*)malloc(sizeof(struct symnode));
    p->type = NUM;
    p->entry.num = data;
    p->next = T;
    return p;
}

node createInternalNode(int optype, node l, node r){
    struct TreeNode* p = (struct TreeNode*)malloc(sizeof(struct TreeNode));
    p->left = l;
    p->right = r;
    p->type = -1;
    p->entry.op = optype;
    return p;
}

node createLeafId(char* id, symbolTable T){
    symbolTable mover = T;
    while(mover){
        if(mover->type==ID && !strcmp(mover->entry.id.name, id)){
            struct TreeNode* p = (struct TreeNode*)malloc(sizeof(struct TreeNode));
            p->left = NULL;
            p->right = NULL;
            p->type = ID;
            p->entry.id = mover;
            return p;
        }
        mover = mover->next;
    }
    
    char* err = (char *)malloc((25+strlen(id)*sizeof(char)));
    sprintf(err,"Undeclared identifier %s",id);
    throwError(err);
}

node createLeafNum(ll data){
    struct TreeNode* p = (struct TreeNode*)malloc(sizeof(struct TreeNode));
    p->left = NULL;
    p->right = NULL;
    p->type = NUM;
    p->entry.num = data;
    return p;
}

ll evalexpr(node curr){
    if(curr == NULL) return 0;
    if(curr->type == ID) return curr->entry.id->entry.id.val;
    if(curr->type == NUM) return curr->entry.num;

    ll l = evalexpr(curr->left);
    ll r = evalexpr(curr->right);
    switch(curr->entry.op){
        case PLUS:
            return l+r;
        case MINUS:
            return l-r;
        case MUL:
            return l*r;
        case DIV:
            if(r==0) throwError("Division by Zero");
            return l/r;
        case MOD:
            if(r==0) throwError("Division by Zero");
            return l%r;
        case EXPO:
            return binExp(l,r);
    }

    free(curr); // This expression tree is not needed anymore
    return 0;
}

ll binExp(ll a, ll b){
    if(a==0 && b==0) throwError("0 pow 0 is undefined");
    if(b<0) throwError("Negative power not allowed");
    ll ans = 1;
    while(b){
        if(b & 1) ans = ans * a;
        a = a*a;
        b>>=1;
    }
    return ans;
}

void freeTable(symbolTable T){
    if(T==NULL) return;
    if(T->type == ID) free(T->entry.id.name);
    freeTable(T->next);
}

int main(){
    printf("---Tokenization and Parsing Started\n");
    if(setjmp(parseEnv)==0){
        yyparse();
        printf("---Evaluation Complete\n");
    }
    else printf("---Evaluation Failed\n");
    
}