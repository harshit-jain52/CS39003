#include "expr.yy.c"
#include "expr.tab.c"
#include <setjmp.h>

static jmp_buf parseEnv;

void throwError(char *err)
{
    fprintf(stderr, "***Error at line %d: %s\n", yylineno, err);
    longjmp(parseEnv, 1);
}

void setId(symbolTable T, char* id, argtp arg){
    char prn[10];
    genArgPrn(prn,arg);
    int offset = findId(T,id);
    
    printf("\tMEM[%d] = %s;\n", offset,prn);
    printf("\tmprn(MEM,%d);\n",offset);
    freeArg(arg);
}

int setRegId(int offset){
    if(RT[0]==false){
        printf("\tR[0] = MEM[%d];\n",offset);
        RT[0]=true;
        return 0;
    }

    printf("\tR[1] = MEM[%d];\n",offset);
    RT[1]=true;
    return 1;
}

struct symnode* addSymbol(char *id){
    struct symnode* p = (struct symnode*)malloc(sizeof(struct symnode));
    p->id.name=strdup(id);
    p->id.offset=MEMT++;
    p->next=NULL;
    return p;
}

int findId(symbolTable T, char* id){
    symbolTable mover = T;
    while(mover){
        if(!strcmp(mover->id.name,id)){
            return mover->id.offset;
        }
        mover = mover->next;
    }

    struct symnode* p = addSymbol(id);
    p->next=T->next;
    T->next=p;
    return p->id.offset;
}

argtp createArg(int type, int val){
    struct arg_* a = (struct arg_*)malloc(sizeof(struct arg_));
    a->type = type;
    a->val = val;
    return a;
}

argtp newArg(){
    int reg = findFreeReg();
    RT[reg] = true;
    return createArg(REG_IDX,reg);
}

int findFreeReg(){
    for(int i=2; i<RSIZE; i++) if(RT[i]==false) return i;
    return 0;
}

argtp createExpr(int op, argtp arg1, argtp arg2, symbolTable T){
    char prn0[10], prn1[10], prn2[10];
    genArgPrn(prn1, arg1);
    genArgPrn(prn2, arg2);
    freeArg(arg1);
    freeArg(arg2);
    argtp a = newArg();
    genArgPrn(prn0,a);

    if(op==EXPO) printf("\t%s = pwr(%s,%s);\n",prn0,prn1,prn2);
    else printf("\t%s = %s %c %s;\n",prn0,prn1,op,prn2);

    if(a->type==REG_IDX && a->val==0){
        printf("\tMEM[%d] = R[0];\n",MEMT);
        RT[0] = false;
        char temp[10];
        sprintf(temp,"$%d",TEMP++);
        a->val = findId(T,temp);
        a->type = MEM_OFFSET;
    }
    return a;
}

void genArgPrn(char *prn, argtp arg){
    switch(arg->type){
        case NUM_VAL:
            sprintf(prn,"%d",arg->val);
            break;
        case REG_IDX:
            sprintf(prn,"R[%d]",arg->val);
            break;
        case MEM_OFFSET:
            arg->type = REG_IDX;
            arg->val = setRegId(arg->val);
            sprintf(prn,"R[%d]",arg->val);
            break;
    }
}

void standaloneExpr(argtp expr){
    printf("\teprn(R,%d);\n",expr->val);
    freeArg(expr);
}

void freeSymTable(symbolTable T){
    if(T==NULL) return;
    freeSymTable(T->next);
    free(T->id.name);
    free(T);
}

void freeArg(argtp arg){
    if(arg->type==REG_IDX) RT[arg->val] = false;
    free(arg);
}

// void printSymTable(symbolTable T){
//     if(T==NULL) return;
//     printf("%s %d\n",T->id.name,T->id.offset);
//     printSymTable(T->next);
// }

int main(){
    RT = (bool *)calloc(RSIZE,sizeof(bool));
    MEMT = -1; TEMP = 1;
    ST = addSymbol("$0");

    printf("#include <stdio.h>\n#include <stdlib.h>\n#include \"aux.c\"\n\n");
    printf("int main()\n{\n");
    printf("\tint R[%d];\n",RSIZE);
    printf("\tint MEM[%d];\n\n",MEMSIZE);

    if(setjmp(parseEnv)==0){
        yyparse();
    }
    else printf("\n\terrprn();\n");
    printf("\n\texit(0);\n}\n");
    freeSymTable(ST);
}