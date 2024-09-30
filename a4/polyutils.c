#include "lex.yy.c"
#include "y.tab.c"
#include <setjmp.h>
typedef long long ll;

int numDerTerms;
static jmp_buf parseEnv;

void throwError(char *err)
{
    fprintf(stderr, "***Error at line %d: %s\n", yylineno, err);
    longjmp(parseEnv, 1);
}

parseTreeNode* createNode(enum nodeType type, int ruleno, int numCh, ...) {
	parseTreeNode* new_node = (parseTreeNode*)malloc(sizeof(parseTreeNode));
	new_node->children = NULL;
    new_node->type = type;
    new_node->ruleno = ruleno;
    new_node->sz=numCh;
	if(!numCh) return new_node;

    new_node->children = (parseTreeNode**)malloc(numCh*sizeof(parseTreeNode*));
	va_list args;
	va_start(args, numCh);

    for(int i=0;i<numCh;i++){
        new_node->children[i] = va_arg(args, parseTreeNode*);
    }
	
	va_end(args);
	return new_node;
}

parseTreeNode* createLeaf(char ch){
	parseTreeNode* new_node = (parseTreeNode*)malloc(sizeof(parseTreeNode));
    new_node->children = NULL;
    new_node->type = TERMINAL;
    new_node->ruleno = ch;
    new_node->sz=0;
    return new_node;
}

void setatt(parseTreeNode* curr){
    switch(curr->type){
        case S_NODE:
            switch(curr->ruleno){
                case 1:
                    curr->children[0]->inh = '+';
                    setatt(curr->children[0]);
                    break;
                case 2:
                    curr->children[1]->inh = '+';
                    setatt(curr->children[1]);
                    break;
                case 3:
                    curr->children[1]->inh = '-';
                    setatt(curr->children[1]);
                    break;
            }
            break;
        case P_NODE:
            curr->children[0]->inh = curr->inh;
            setatt(curr->children[0]);
            switch(curr->ruleno){
                case 2:
                    curr->children[2]->inh = '+';
                    setatt(curr->children[2]);
                    break;
                case 3:
                    curr->children[2]->inh = '-';
                    setatt(curr->children[2]);
                    break;
            }
            break;
        case T_NODE:
            setatt(curr->children[0]);
            if(curr->ruleno==4) setatt(curr->children[1]);
            break;
        case X_NODE:
            setatt(curr->children[0]);
            if(curr->ruleno==2) setatt(curr->children[2]);
            break;
        case N_NODE:
            setatt(curr->children[0]);
            switch(curr->ruleno){
                case 1:
                    curr->val = curr->children[0]->val;
                    break;
                case 2 ... 3:
                    curr->children[1]->inh = curr->children[0]->val;
                    setatt(curr->children[1]);
                    curr->val = curr->children[1]->val;
                    break;
            }
            break;
        case M_NODE:
            setatt(curr->children[0]);
            switch(curr->ruleno){
                case 1 ... 3:
                    curr->val = 10*curr->inh+curr->children[0]->val;
                    break;
                case 4 ... 6:
                    curr->children[1]->inh = 10*curr->inh+curr->children[0]->val;
                    setatt(curr->children[1]);
                    curr->val = curr->children[1]->val;
                    break;
            }
            break;
        case TERMINAL:
            curr->val = curr->ruleno-'0';
            break;
    }
}

void print_spaces(int num){
    for(int i = 0; i < num; i++) printf("  ");
}

void printTree(parseTreeNode* curr, int level){
    print_spaces(level);
    switch(curr->type){
        case S_NODE:
            printf("S []");
            break;
        case P_NODE:
            printf("==> P [inh = %c]", curr->inh);
            break;
        case T_NODE:
            printf("==> T [inh = %c]", curr->inh);
            break;
        case X_NODE:
            printf("==> X []");
            break;
        case N_NODE:
            printf("==> N [val = %d]", curr->val);
            break;
        case M_NODE:
            printf("==> M [inh = %d, val = %d]", curr->inh, curr->val);
            break;
        case TERMINAL:
            if(curr->ruleno<='9' && curr->ruleno>='0') printf("==> %c [val = %d]", curr->ruleno, curr->val);
            else printf("==> %c []", curr->ruleno);
            break;
    }
    printf("\n");
    for(int i=0;i<curr->sz;i++){
        printTree(curr->children[i],level+1);
    }
}

ll binpow(ll a, ll b){
    ll ans = 1;
    while(b){
        if(b&1) ans*=a;
        a*=a;
        b>>=1;
    }
    return ans;
}

ll evalpoly(parseTreeNode* curr, ll x){
    switch(curr->type){
        case S_NODE:
            switch(curr->ruleno){
                case 1:
                    return evalpoly(curr->children[0],x);
                case 2 ... 3:
                    return evalpoly(curr->children[1],x);
            }
        case P_NODE:
            switch(curr->ruleno){
                case 1:
                    return evalpoly(curr->children[0],x);
                case 2 ... 3:
                    return (evalpoly(curr->children[0],x) + evalpoly(curr->children[2],x));
            }
        case T_NODE:
            int mul = ((curr->inh=='-')?-1:1);
            switch(curr->ruleno){
                case 1 ... 2:
                    return mul*curr->children[0]->val;
                case 3:
                    return mul*evalpoly(curr->children[0],x);
                case 4:
                    return mul*curr->children[0]->val*evalpoly(curr->children[1],x);
            }
        case X_NODE:
            switch(curr->ruleno){
                case 1:
                    return x;
                case 2:
                    return binpow(x,curr->children[2]->val);
            }
    }
    return 0;
}

void printderivative(parseTreeNode* curr, int coeff){
    switch(curr->type){
        case S_NODE:
            switch(curr->ruleno){
                case 1:
                    printderivative(curr->children[0],1);
                    break;
                case 2 ... 3:
                    printderivative(curr->children[1],1);
                    break;
            }
            break;
        case P_NODE:
            switch(curr->ruleno){
                case 1:
                    printderivative(curr->children[0],1);
                    break;
                case 2 ... 3:
                    printderivative(curr->children[0],1);
                    printderivative(curr->children[2],1);
                    break;
            }
            break;
        case T_NODE:
            switch(curr->ruleno){
                case 1 ... 2:
                    break;
                case 3:
                    if(numDerTerms!=0 || curr->inh=='-') printf("%c ",curr->inh);
                    printderivative(curr->children[0],1);
                    break;
                case 4:
                    if(numDerTerms!=0 || curr->inh=='-') printf("%c ",curr->inh);
                    printderivative(curr->children[1],curr->children[0]->val);
                    break;
            }
            break;
        case X_NODE:
            numDerTerms++;
            switch(curr->ruleno){
                case 1:
                    printf("%d ",coeff);
                    break;
                case 2:
                    if(curr->children[2]->val==1) printf("%d ",coeff);
                    else printf("%dx^%d ",coeff*curr->children[2]->val,curr->children[2]->val-1);
                    break;
            }
    }
}

void cleanParseTree(parseTreeNode* root){
    if(root==NULL) return;
    for(int i=0; i<root->sz;i++) cleanParseTree(root->children[i]);
    free(root->children);
    free(root);
}

int main(){
    if(setjmp(parseEnv)==0){
        // Create Parse Tree
        yyparse();

        // Set Attributes in Parse Tree
        setatt(root);

        // Print Annotated Parse Tree
        printf("+++ The annoted parse tree is\n");
        printTree(root,0);

        // Evaluate Polynomial for x in [-5,5]
        for(int num=-5;num<=5;num++){
            printf("\n+++ f(%2d) = %15lld",num,evalpoly(root,num));
        }

        // Print derivative of polynomial
        printf("\n\n+++ f'(x) = ");
        numDerTerms = 0;
        printderivative(root,1);
        if(numDerTerms==0) printf("0"); // Derivatiive is zero, nothing is printed in printderivative()

        // Free allocated space
        cleanParseTree(root);
        printf("\n\n--- Parsing and Evaluation Complete\n");

    }
    else{
        printf("--- Parsing Failed\n");
    }
}