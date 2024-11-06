#include "prog.yy.c"
#include "prog.tab.c"

// char* addTemp(){
//     char* tmp = (char*)malloc(10*sizeof(char));
//     sprintf(tmp,"$%d",++tmpno);
//     addSym(tmp);
//     return tmp;
// }

// sym* findSym(char *id){
//     symTable* mover = ST;
//     while(mover!=NULL){
//         if(!strcmp(mover->symbol->id, id)) return mover->symbol;
//         mover = mover->next;
//     }
//     return NULL;
// }

// void addSym(char* id){
//     sym* S = findSym(id);
//     if(S!=NULL) return;

//     symTable* T = (symTable*)malloc(sizeof(symTable));
//     T->symbol->id = strdup(id);
//     T->next=ST;
//     ST=T;
// }

void emit(int type, char* op, char* arg1, char* arg2, char* res){
    // printf("\t%d\t:\t",++instr);
    instr++;
    quadArray* arr = (quadArray*)malloc(sizeof(quadArray));
    arr->q = (quad*)malloc(sizeof(quad));

    arr->q->type=type;
    arr->q->label=-1;
    arr->q->op=(op==NULL)?NULL:strdup(op);
    arr->q->arg1=(arg1==NULL)?NULL:strdup(arg1);
    arr->q->arg2=(arg2==NULL)?NULL:strdup(arg2);
    arr->q->res=(res==NULL)?NULL:strdup(res);
    arr->next = NULL;

    quadArray* mover=QA;
    if(mover==NULL){
        QA = arr;
    }
    else{
        while(mover->next != NULL) mover = mover->next;
        mover->next=arr;
    }
}

// int size(){
//     int sz=0;
//     quadArray* mover= QA;
//     while(mover){
//         sz++;
//         mover=mover->next;
//     }
//     return sz;
// }

void backpatch(int where, int label){
    quadArray* mover = QA;
    int ins = 1;
    // printf("\n%d\t%d",where,label);
    // printf("\n%d\n",size());

    while(mover){
        if(ins==where){
            mover->q->label=label;
            return;
        }
        mover=mover->next;
        ins++;
    }
}

void printQuads(){
    quadArray* mover = QA;
    int ins = 0;

    while(mover){
        printf("\t%d\t: ",++ins);
        switch(mover->q->type){
            case EQ:
                if(mover->q->op==NULL) printf("%s = %s\n", mover->q->res, mover->q->arg1);
                else printf("%s = %s %s %s\n", mover->q->res, mover->q->arg1, mover->q->op, mover->q->arg2);
                break;
            case WHEN:
                printf("iffalse (%s %s %s) goto %d\n",mover->q->arg1,mover->q->op,mover->q->arg2,mover->q->label);
                break;
            case WHILE:
                printf("goto %d\n", mover->q->label);
                break;
        }

        mover = mover->next;
    }

    printf("\t%d\t:\t",++instr);
}

int main(){
    yyparse();
    printQuads();
}