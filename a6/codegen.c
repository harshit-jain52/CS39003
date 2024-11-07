#include "prog.yy.c"
#include "prog.tab.c"

// char* addTemp(){
//     char* tmp = (char*)malloc(10*sizeof(char));
//     sfprintf(fp, tmp,"$%d",++tmpno);
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
    // fprintf(fp, "\t%d\t:\t",++instr);
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
    // fprintf(fp, "\n%d\t%d",where,label);
    // fprintf(fp, "\n%d\n",size());

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
    identifyLeaders();
    quadArray* mover = QA;
    int ins = 0, block=0;

    FILE* fp = fopen("ic.txt","w");
    while(mover){
        ins++;
        if(leaders[ins]) fprintf(fp, "\nBlock %d\n",++block);
        fprintf(fp, "\t%d\t: ",ins);
        switch(mover->q->type){
            case EQ:
                if(mover->q->op==NULL) fprintf(fp, "%s = %s\n", mover->q->res, mover->q->arg1);
                else fprintf(fp, "%s = %s %s %s\n", mover->q->res, mover->q->arg1, mover->q->op, mover->q->arg2);
                break;
            case WHEN:
                fprintf(fp, "iffalse (%s %s %s) goto %d\n",mover->q->arg1,mover->q->op,mover->q->arg2,mover->q->label);
                break;
            case WHILE:
                fprintf(fp, "goto %d\n", mover->q->label);
                break;
        }

        mover = mover->next;
    }

    fprintf(fp, "\n\t%d\t:\t",instr);
}

void identifyLeaders(){
    quadArray* mover = QA;
    leaders = (bool*)calloc(instr+1, sizeof(bool));

    leaders[1] = true;
    int ins = 1;

    while(mover){
        switch(mover->q->type){
            case WHEN:
            case WHILE:
                leaders[ins+1]=true;
                leaders[mover->q->label]=true;
                break;
        }
        mover = mover->next;
        ins++;
    }
}

int main(){
    yyparse();
    printQuads();
}