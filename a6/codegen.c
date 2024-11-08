#include "prog.yy.c"
#include "prog.tab.c"

// char* addTemp(){
//     char* tmp = (char*)malloc(10*sizeof(char));
//     sfprintf(fp, tmp,"$%d",++tmpno);
//     addSym(tmp);
//     return tmp;
// }

sym* findSym(char *id){
    sym* mover = ST;
    while(mover!=NULL){
        if(!strcmp(mover->id, id)) return mover;
        mover = mover->next;
    }
    return NULL;
}

void addSym(char* id){
    sym* S = findSym(id);
    if(S!=NULL) return;

    S = (sym*)malloc(sizeof(sym));
    S->id = strdup(id);
    S->regno = -1;
    S->stored = false;

    sym* mover = ST;
    if(mover==NULL){
        ST = S;
    }
    else{
        while(mover->next != NULL) mover = mover->next;
        mover->next=S;
    }
}

void emit(int type, char* op, char* arg1, char* arg2, char* res){
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

void ICGen(){
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

void freeDesc(descriptor* desc, int regno){
    if(desc==NULL) return;
    desc->symbol->regno = -1;
    if(!desc->symbol->stored){
        if(desc->symbol->id[0]!='$'){
            char prnt[20];
            sprintf(prnt, "R%d", regno+1);
            emitTarget(LDST, "ST", desc->symbol->id, prnt, NULL, -1);
        }
        desc->symbol->stored = true;
    }
    freeDesc(desc->next, regno);
    free(desc);
}

void freeReg(int regno){
    RB[regno].score = 0;
    freeDesc(RB[regno].desc, regno);
    RB[regno].desc = NULL;
}

void freeAllRegs(){
    for(int i=0;i<RSIZE;i++){
        freeReg(i);
    }
}

void loadReg(int regno, sym* S){
    /*
    LD R, x
    - Change reg descriptor for reg R so it holds only x
    - Change addr descriptor of x by adding R as an additional location
    */
    freeReg(regno);
    allocateReg(regno, S);
    S->regno = regno;
}

void allocateReg(int regno, sym* S){
    addDesc(regno, S);
    RB[regno].score = 1;
}

int getReg(char* name, bool lhs){
    if(isdigit(name[0]) || name[0]=='-') return -1;

    // 1. check if symbol is already in a register
    sym* S = findSym(name);
    if(S->regno!=-1) return S->regno;
    
    // 2. check if register is free
    for(int i=0;i<RSIZE;i++){
        if(RB[i].desc==NULL){
            loadReg(i, S);
            if(!lhs && name[0]!='$'){
                char prnt[20];
                sprintf(prnt, "R%d", i+1);
                emitTarget(LDST, "LD", prnt, name, NULL, -1);
            }
            return i;
        }
    }

    // 3. check if any register is dead (all the variables and temporaries stored in that register have latest values in memory)
    for(int i=0; i<RSIZE; i++){
        bool dead = true;
        descriptor* mover = RB[i].desc;
        while(mover){
            dead = dead && mover->symbol->stored;
            mover = mover->next;
        }
        if(dead){
            loadReg(i, S);
            if(!lhs && name[0]!='$'){
                char prnt[20];
                sprintf(prnt, "R%d", i+1);
                emitTarget(LDST, "LD", prnt, name, NULL, -1);
            }
            return i;
        }
    }
}

bool checkDesc(descriptor* desc, char* name){
    if(desc==NULL) return false;
    if(!strcmp(desc->symbol->id, name)) return true;
    return checkDesc(desc->next, name);
}

void addDesc(int regno, sym* S){
    descriptor* d = (descriptor*)malloc(sizeof(descriptor));
    d->symbol = S;
    d->next = RB[regno].desc;
    RB[regno].desc = d;
}

void removeDesc(int regno, sym* S){
    descriptor* mover = RB[regno].desc;
    descriptor* prev = NULL;
    while(mover){
        if(mover->symbol==S){
            if(prev==NULL) RB[regno].desc = mover->next;
            else prev->next = mover->next;
            free(mover);
            return;
        }
        prev = mover;
        mover = mover->next;
    }
}

void emitTarget(int type, char* op, char* arg1, char* arg2, char* res, int label){
    targetinstr++;
    quadArray* arr = (quadArray*)malloc(sizeof(quadArray));
    arr->q = (quad*)malloc(sizeof(quad));

    arr->q->type=type;
    arr->q->label=label;
    arr->q->op=(op==NULL)?NULL:strdup(op);
    arr->q->arg1=(arg1==NULL)?NULL:strdup(arg1);
    arr->q->arg2=(arg2==NULL)?NULL:strdup(arg2);
    arr->q->res=(res==NULL)?NULL:strdup(res);
    arr->next = NULL;

    quadArray* mover=TQA;
    if(mover==NULL){
        TQA = arr;
    }
    else{
        while(mover->next != NULL) mover = mover->next;
        mover->next=arr;
    }
}

void ICtoTC(){
    quadArray* mover = QA;
    int ins = 1;
    leaderMap = (int*)malloc((instr+1)*sizeof(int));
    while(mover){
        if(leaders[ins]){
            freeAllRegs();
            leaderMap[ins] = targetinstr+1;
        }
        switch(mover->q->type){
            case EQ:
                // Set operation T = A
                if(mover->q->op==NULL){
                    if(isdigit(mover->q->arg1[0]) || mover->q->arg1[0]=='-'){
                        // A is a constant
                        int regt = getReg(mover->q->res,true);
                        char prnt[20];
                        sprintf(prnt, "R%d", regt+1);
                        emitTarget(LDST, "LDI", prnt, mover->q->arg1, NULL, -1);
                    }    
                    else{
                        // A is a variable or temporary
                        int rega = getReg(mover->q->arg1,false);
                        sym* S = findSym(mover->q->res);
                        if(S->regno!=-1) removeDesc(S->regno, S);
                        S->regno = rega;
                        RB[rega].score++;
                        S->stored = false;
                        addDesc(rega, S);
                    }
                }
                else{
                    // OP T A B
                    int rega = getReg(mover->q->arg1,false);
                    int regb = getReg(mover->q->arg2,false);
                    int regt = getReg(mover->q->res,true);
                    sym* S = findSym(mover->q->res);
                    S->stored = false;
                    
                    char prna[20], prnb[20], prnt[20], prnop[10];
                    if(isdigit(mover->q->arg1[0]) || mover->q->arg1[0]=='-') sprintf(prna, "%s", mover->q->arg1);
                    else sprintf(prna, "R%d", rega+1);
                    if(isdigit(mover->q->arg2[0]) || mover->q->arg2[0]=='-') sprintf(prnb, "%s", mover->q->arg2);
                    else sprintf(prnb, "R%d", regb+1);
                    switch(mover->q->op[0]){
                        case '+': sprintf(prnop, "ADD"); break;
                        case '-': sprintf(prnop, "SUB"); break;
                        case '*': sprintf(prnop, "MUL"); break;
                        case '/': sprintf(prnop, "DIV"); break;
                        case '%': sprintf(prnop, "REM"); break;
                    }
                    sprintf(prnt, "R%d", regt+1);
                    
                    emitTarget(OP, prnop, prna, prnb, prnt, -1);
                }
                break;
            case WHEN:
                // IFFALSE A OP B GOTO L
                int rega = getReg(mover->q->arg1,false);
                int regb = getReg(mover->q->arg2,false);

                char prna[20], prnb[20], prnop[10];
                if(isdigit(mover->q->arg1[0]) || mover->q->arg1[0]=='-') sprintf(prna, "%s", mover->q->arg1);
                else sprintf(prna, "R%d", rega+1);
                if(isdigit(mover->q->arg2[0]) || mover->q->arg2[0]=='-') sprintf(prnb, "%s", mover->q->arg2);
                else sprintf(prnb, "R%d", regb+1);
                switch(mover->q->op[0]){
                    case '!': sprintf(prnop, "JEQ"); break;
                    case '=': sprintf(prnop, "JNE"); break;
                    case '<': switch(mover->q->op[1]){
                        case '=': sprintf(prnop, "JGT"); break;
                        default: sprintf(prnop, "JGE"); break;
                    }
                    case '>': switch(mover->q->op[1]){
                        case '=': sprintf(prnop, "JLT"); break;
                        default: sprintf(prnop, "JLE"); break;
                    }
                }
                freeAllRegs();
                emitTarget(JCOND, prnop, prna, prnb, NULL, mover->q->label);
                break;
            case WHILE:
                // GOTO L
                freeAllRegs();
                emitTarget(JUMP, NULL, NULL, NULL, NULL, mover->q->label);
                break;
        }

        mover = mover->next;
        ins++;
    }

    leaderMap[instr] = targetinstr+1;
}

void identifyTargetLeaders(){
    targetLeaders = (bool*)calloc(targetinstr+1, sizeof(bool));
    for(int i=1;i<=instr;i++){
        if(leaders[i]) targetLeaders[leaderMap[i]]=true;
    }
}

void TCGen(){
    identifyTargetLeaders();
    quadArray* mover = TQA;
    int tins = 0, block=0;

    FILE* fp = fopen("tc.txt","w");
    while(mover){
        tins++;
        if(targetLeaders[tins]) fprintf(fp, "\nBlock %d\n",++block);
        fprintf(fp, "\t%d\t: ",tins);

        switch(mover->q->type){
            case LDST:
                fprintf(fp, "%s %s %s\n", mover->q->op, mover->q->arg1, mover->q->arg2);
                break;
            case OP:
                fprintf(fp, "%s %s %s %s\n", mover->q->op, mover->q->res, mover->q->arg1, mover->q->arg2);
                break;
            case JCOND:
                mover->q->label = leaderMap[mover->q->label];
                fprintf(fp, "%s %s %s %d\n", mover->q->op, mover->q->arg1, mover->q->arg2, mover->q->label);
                break;
            case JUMP:
                mover->q->label = leaderMap[mover->q->label];
                fprintf(fp, "%s %d\n", "JMP", mover->q->label);
                break;
        }
        mover = mover->next;
    }

    fprintf(fp, "\n\t%d\t:\t",targetinstr+1);
}

int main(){
    yyparse();
    ICGen();

    RB = (reg*)malloc(RSIZE*sizeof(reg));

    ICtoTC();
    TCGen();
}