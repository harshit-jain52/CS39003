#include "prog.yy.c"
#include "prog.tab.c"
#include <setjmp.h>
#include <limits.h>

static jmp_buf parseEnv;

/* Utility Functions*/

// Error handling
void throwError(char *err)
{
    fprintf(stderr, "*** Error at line %d: %s\n", yylineno, err);
    longjmp(parseEnv, 1);
}

// Check if an argument is a number
bool isConst(char *str){
    return (isdigit(str[0]) || str[0]=='-' || str[0]=='+');
}

/* Symbol Table */

// Find a symbol in the symbol table
sym* findSym(char *id){
    sym* mover = ST;
    while(mover!=NULL){
        if(!strcmp(mover->id, id)) return mover;
        mover = mover->next;
    }
    return NULL;
}

// Add a symbol to the symbol table
void addSym(char* id){
    sym* S = findSym(id);
    if(S!=NULL) return;
    int off = 0;

    S = (sym*)malloc(sizeof(sym));
    S->id = strdup(id);
    S->regno = -1;
    S->stored = true;
    S->live = true;
    S->next = NULL;

    sym* mover = ST;
    if(mover==NULL){
        S->offset = 0;
        ST = S;
    }
    else{
        while(mover->next != NULL) {
            mover = mover->next;
            off += INTSIZE;
        }
        S->offset = off+INTSIZE;
        mover->next=S;
    }
}

void printSymTable(){
    FILE* fp = fopen("symtable.txt","w");
    sym* mover = ST;
    fprintf(fp, "%-35s %s\n", "Symbol", "Offset");
    fprintf(fp, "-------------------------------------------\n");
    while (mover) {
        fprintf(fp, "%-35s %d\n", mover->id, mover->offset);
        mover = mover->next;
    }
}

/* Intermediate Code Generation*/

// Emit a quadruple
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

// Backpatch a quadruple
void backpatch(int where, int label){
    quadArray* mover = QA;
    int ins = 1;

    while(mover){
        if(ins==where){
            mover->q->label=label;
            return;
        }
        mover=mover->next;
        ins++;
    }
}

// Identify leaders in intermediate code
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

// Print the intermediate code
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

/* Target Code Generation */

// Free register descriptor
void freeDesc(descriptor* desc, int regno){
    if(desc==NULL) return;
    desc->symbol->regno = -1;
    if(!desc->symbol->stored){
        if(desc->symbol->id[0]!='$' || desc->symbol->live){
            char prnt[20];
            sprintf(prnt, "R%d", regno+1);
            emitTarget(LDST, "ST", prnt, NULL, desc->symbol->id, -1);
        }
        desc->symbol->stored = true;
    }
    freeDesc(desc->next, regno);
    free(desc);
}

// Free a register
void freeReg(int regno){
    RB[regno].score = 0;
    freeDesc(RB[regno].desc, regno);
    RB[regno].desc = NULL;
}

// Free all registers
void freeAllRegs(){
    for(int i=0;i<RSIZE;i++){
        freeReg(i);
    }
}

// Load a symbol into a register
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

// Allocate a register for a symbol
void allocateReg(int regno, sym* S){
    addDesc(regno, S);
    RB[regno].score = 1;
}

// Kill a temporary
void killTemp(char* name, int regno){
    if(name[0]!='$') return;
    sym* S = findSym(name);
    S->live = false;
    S->regno = -1;
    RB[regno].score--;
}

// Get a suitable register for a symbol
int getReg(char* name, bool lhs, int cantTake){
    if(isConst(name)) return -1;


    // 1. Check if symbol is already in a register
    sym* S = findSym(name);
    if(S->regno!=-1) return S->regno;
    
    // 2. Check if any register is free
    for(int i=0;i<RSIZE;i++){
        if(RB[i].desc==NULL){
            loadReg(i, S);
            if(!lhs){
                char prnt[20];
                sprintf(prnt, "R%d", i+1);
                emitTarget(LDST, "LD", name, NULL, prnt, -1);
            }
            return i;
        }
    }

    // 3. Check if any register is dead (all the variables stored in that register have latest values in memory, and temporaries are not live)
    for(int i=0; i<RSIZE; i++){
        if(i==cantTake) continue;
        bool dead = true;
        descriptor* mover = RB[i].desc;
        while(mover){
            if(mover->symbol->id[0]=='$' && mover->symbol->live){
                dead = false;
                break;
            }
            else if(!mover->symbol->stored){
                dead = false;
                break;
            }
            mover = mover->next;
        }
        if(dead){
            loadReg(i, S);
            if(!lhs){
                char prnt[20];
                sprintf(prnt, "R%d", i+1);
                emitTarget(LDST, "LD", name, NULL, prnt, -1);
            }
            return i;
        }
    }

    // 4. Check if any register contains only temporaries, neither of which are live
    for(int i=0;i<RSIZE;i++){
        if(i==cantTake) continue;
        bool dead = true;
        descriptor* mover = RB[i].desc;
        while(mover){
            if(mover->symbol->id[0]!='$' || mover->symbol->live){
                dead = false;
                break;
            }
            mover = mover->next;
        }
        if(dead){
            loadReg(i, S);
            if(!lhs){
                char prnt[20];
                sprintf(prnt, "R%d", i+1);
                emitTarget(LDST, "LD", name, NULL, prnt, -1);
            }
            return i;
        }
    }

    // 5. Find the register with the lowest score
    int minscore = INT_MAX;
    int minreg = -1;
    for(int i=0;i<RSIZE;i++){
        if(i==cantTake) continue;
        if(RB[i].score<minscore){
            minscore = RB[i].score;
            minreg = i;
        }
    }
    if(minreg != -1){
        loadReg(minreg, S);
        if(!lhs){
            char prnt[20];
            sprintf(prnt, "R%d", minreg+1);
            emitTarget(LDST, "LD", name, NULL, prnt, -1);
        }
        return minreg;
    }

    yyerror("Out of registers"); // This should never happen
}

// Add a symbol to a reg descriptor
void addDesc(int regno, sym* S){
    descriptor* d = (descriptor*)malloc(sizeof(descriptor));
    d->symbol = S;
    d->next = RB[regno].desc;
    RB[regno].desc = d;
    RB[regno].score++;
}

// Remove a symbol from a reg descriptor
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

// Emit a target code quadruple
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

// Convert intermediate code to target code
void ICtoTC(){
    quadArray* mover = QA;
    int ins = 1;
    insMap = (int*)malloc((instr+1)*sizeof(int));
    while(mover){
        if(leaders[ins]){
            freeAllRegs();
        }
        insMap[ins] = targetinstr+1;
        switch(mover->q->type){
            case EQ:
                // Set operation T = A
                if(mover->q->op==NULL){
                    sym* S = findSym(mover->q->res);
                    if(isConst(mover->q->arg1)){
                        // A is a constant
                        int regt = getReg(mover->q->res,true,-1);
                        char prnt[20];
                        sprintf(prnt, "R%d", regt+1);
                        emitTarget(LDST, "LDI", mover->q->arg1, NULL, prnt, -1);
                    }    
                    else{
                        // A is a variable or temporary
                        int rega = getReg(mover->q->arg1,false,-1);
                        if(S->regno!=-1) removeDesc(S->regno, S);
                        S->regno = rega;
                        addDesc(rega, S);
                        killTemp(mover->q->arg1, rega);
                    }
                    S->stored = false;
                }
                else{
                    // Arithmetic Operation T =  A OP B
                    int rega = getReg(mover->q->arg1,false,-1);
                    int regb = getReg(mover->q->arg2,false,rega);

                    killTemp(mover->q->arg1, rega);
                    killTemp(mover->q->arg2, regb);

                    int regt = getReg(mover->q->res,true,-1);
                    sym* S = findSym(mover->q->res);
                    S->stored = false;
                    
                    char prna[20], prnb[20], prnt[20], prnop[10];
                    if(rega==-1) sprintf(prna, "%s", mover->q->arg1);
                    else sprintf(prna, "R%d", rega+1);
                    if(regb==-1) sprintf(prnb, "%s", mover->q->arg2);
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
                // Conditional Jump IFFALSE A OP B GOTO L
                int rega = getReg(mover->q->arg1,false,-1);
                int regb = getReg(mover->q->arg2,false,rega);

                killTemp(mover->q->arg1, rega);
                killTemp(mover->q->arg2, regb);

                char prna[20], prnb[20], prnop[10];
                if(rega==-1) sprintf(prna, "%s", mover->q->arg1);
                else sprintf(prna, "R%d", rega+1);
                if(regb==-1) sprintf(prnb, "%s", mover->q->arg2);
                else sprintf(prnb, "R%d", regb+1);
                switch(mover->q->op[0]){
                    case '!': sprintf(prnop, "JEQ"); break;
                    case '=': sprintf(prnop, "JNE"); break;
                    case '<': switch(mover->q->op[1]){
                        case '=': sprintf(prnop, "JGT"); break;
                        default: sprintf(prnop, "JGE"); break;
                    } break;
                    case '>': switch(mover->q->op[1]){
                        case '=': sprintf(prnop, "JLT"); break;
                        default: sprintf(prnop, "JLE"); break;
                    } break;
                }
                freeAllRegs();
                emitTarget(JCOND, prnop, prna, prnb, NULL, mover->q->label);
                break;
            case WHILE:
                // Unconditional Jump GOTO L
                freeAllRegs();
                emitTarget(JUMP, NULL, NULL, NULL, NULL, mover->q->label);
                break;
        }

        mover = mover->next;
        ins++;
    }

    freeAllRegs();
    insMap[instr] = targetinstr+1;
}

// Identify target code leaders
void identifyTargetLeaders(){
    targetLeaders = (bool*)calloc(targetinstr+1, sizeof(bool));
    for(int i=1;i<=instr;i++){
        if(leaders[i]) targetLeaders[insMap[i]]=true;
    }
}

// Print the target code
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
                fprintf(fp, "%s %s %s\n", mover->q->op, mover->q->res, mover->q->arg1);
                break;
            case OP:
                fprintf(fp, "%s %s %s %s\n", mover->q->op, mover->q->res, mover->q->arg1, mover->q->arg2);
                break;
            case JCOND:
                mover->q->label = insMap[mover->q->label];
                fprintf(fp, "%s %s %s %d\n", mover->q->op, mover->q->arg1, mover->q->arg2, mover->q->label);
                break;
            case JUMP:
                mover->q->label = insMap[mover->q->label];
                fprintf(fp, "%s %d\n", "JMP", mover->q->label);
                break;
        }
        mover = mover->next;
    }

    fprintf(fp, "\n\t%d\t:\t",targetinstr+1);
}

/* Cleanup */

// Clear the symbol table
void clearSymTable(sym* S){
    if(S==NULL) return;
    clearSymTable(S->next);
    free(S->id);
    free(S);
}

// Clear the quadruple
void clearQuad(quad* q){
    if(q==NULL) return;
    if(q->op) free(q->op);
    if(q->arg1) free(q->arg1);
    if(q->arg2) free(q->arg2);
    if(q->res) free(q->res);
    free(q);
}

// Clear the quadruple array
void clearQuadArray(quadArray* arr){
    if(arr==NULL) return;
    clearQuadArray(arr->next);
    clearQuad(arr->q);
    free(arr);
}

// Cleanup master function
void cleanup(){
    clearSymTable(ST);
    clearQuadArray(QA);
    clearQuadArray(TQA);
    free(insMap);
    free(leaders);
    free(targetLeaders);
    free(RB);
}

/* Main */
int main(int argc, char *argv[]) {

    if (argc > 1) RSIZE = atoi(argv[1]); // Overwrite the default register bank size if provided
    
    if(setjmp(parseEnv)==0){
        // Parsing
        yyparse();
        printf("+++ Parsing Successful\n");

        printSymTable();
        printf("+++ Symbol Table generated in symtable.txt\n");

        // Intermediate Code Generation
        ICGen();
        printf("+++ Intermediate Code generated in ic.txt\n");
        
        // Target Code Generation
        printf("+++ %d registers available\n", RSIZE);
        RB = (reg*)malloc(RSIZE*sizeof(reg));
        ICtoTC();
        TCGen();
        printf("+++ Target Code generated in tc.txt\n");

        // Cleanup
        cleanup();
    }
    else{
        printf("--- Process Failed\n");
    }
}