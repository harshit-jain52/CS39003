#include "expr.yy.c"
#include "expr.tab.c"
#include <setjmp.h>

static jmp_buf parseEnv;

void throwError(char *err)
{
    fprintf(stderr, "***Error at line %d: %s\n", yylineno, err);
    longjmp(parseEnv, 1);
}

symbolTable setIdNum(symbolTable T, char* id, int num){
    symbolTable mover = T;
    while(mover){
        if(!strcmp(mover->id.name,id)){
            printf("\tMEM[%d] = %d;\n", mover->id.offset,num);
            printf("\tmprn(MEM,%d);\n",mover->id.offset);
            return T;
        }
        mover = mover->next;
    }

    struct symnode* p = addSymbol(id);
    printf("\tMEM[%d] = %d;\n", p->id.offset,num);
    printf("\tmprn(MEM,%d);\n",p->id.offset);

    p->next=T;

    return p;
}

symbolTable setIdId(symbolTable T, char* id1, char* id2){
    symbolTable mover = T;
    int reg = setRegId(T, id2);
    RT[reg]=false;
    while(mover){
        if(!strcmp(mover->id.name,id1)){
            printf("\tMEM[%d] = R[%d];\n", mover->id.offset,reg);
            printf("\tmprn(MEM,%d);\n",mover->id.offset);
            return T;
        }
        mover = mover->next;
    }

    struct symnode* p = addSymbol(id1);
    printf("\tMEM[%d] = R[%d];\n", p->id.offset,reg);
    printf("\tmprn(MEM,%d);\n",p->id.offset);

    p->next=T;

    return p;
}

symbolTable setIdExpr(symbolTable T, char* id, argtp arg){
    symbolTable mover = T;
    char prn[10];
    genArgPrn(prn,arg);

    while(mover){
        if(!strcmp(mover->id.name,id)){
            printf("\tMEM[%d] = %s;\n", mover->id.offset,prn);
            printf("\tmprn(MEM,%d);\n",mover->id.offset);
            freeArg(arg);
            return T;
        }
        mover = mover->next;
    }

    struct symnode* p = addSymbol(id);
    printf("\tMEM[%d] = %s;\n", p->id.offset,prn);
    printf("\tmprn(MEM,%d);\n",p->id.offset);
    freeArg(arg);

    p->next=T;

    return p;
}

int setRegId(symbolTable T, char* id){
    int offset = findId(T,id);

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
            break;
        }
        mover = mover->next;
    }

    return MEMT++;
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

argtp createExpr(int op, argtp arg1, argtp arg2){
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
        a = createArg(MEM_OFFSET,MEMT++);
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
            if(RT[0]==false){
                printf("\tR[0] = MEM[%d];\n",arg->val);
                sprintf(prn,"R[0]");
                arg->val=0;
                RT[0]=true;
            }
            else{
                printf("\tR[1] = MEM[%d];\n",arg->val);
                sprintf(prn,"R[1]");
                arg->val=1;
                RT[1]=true;
            }
            break;
    }
}

void standaloneExpr(argtp expr){
    printf("\teprn(R,%d);\n",expr->val);
    RT[expr->val] = false;
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

int main(){
    RT = (bool *)calloc(RSIZE,sizeof(bool));

    printf("#include <stdio.h>\n#include <stdlib.h>\n#include \"aux.c\"\n\n");
    printf("int main()\n{\n");
    printf("\tint R[%d];\n",RSIZE);
    printf("\tint MEM[%d];\n\n",MEMSIZE);

    if(setjmp(parseEnv)==0){
        yyparse();
    }
    else printf("\n\t//---Intermediate Code Generation Failed\n");
    printf("\n\texit(0);\n}\n");
    freeSymTable(ST);
}