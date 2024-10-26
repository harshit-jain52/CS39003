#include "TinyC3_22CS10030_22CS10049_translator.h"

SymbolTable* currentST;
SymbolTable* globalST;
int blockCount;
Symbol* currentSymbol;
TYPE currentType;
QuadTable* quadTable;

map<TYPE, int> sizeMap = {
    {TYPE_VOID, __VOID_SZ},
    {TYPE_CHAR, __CHAR_SZ},
    {TYPE_INT, __INT_SZ},
    {TYPE_FLOAT, __FLOAT_SZ},
    {TYPE_PTR, __PTR_SZ}
};

map<TYPE, string> strMap = {
    {TYPE_VOID, "void"},
    {TYPE_CHAR, "char"},
    {TYPE_INT, "int"},
    {TYPE_FLOAT, "float"},
    {TYPE_FUNC, "function"}
};

/* SymbolType */

SymbolType::SymbolType(TYPE type_, SymbolType* arrType_, int width_): type(type_), width(width_), arrType(arrType_) {}

int SymbolType::getSize(){
    if(type == TYPE_ARRAY) return width*(arrType->getSize());
    return sizeMap[type];
}

string SymbolType::getType(){
    if(type == TYPE_ARRAY) return "array(" + to_string(width) + ", " + arrType->getType() + ")";
    if(type == TYPE_PTR) return "ptr(" + arrType->getType() + ")";
    return strMap[type];
}

/* Symbol */

Symbol::Symbol(string name_, TYPE inh_type, string init_val): name(name_), type(new SymbolType(inh_type)), offset(0), nestedTable(NULL), initial_value(init_val) {
    size = type->getSize();
}

Symbol* Symbol::update(SymbolType* type_){
    type = type_;
    size = type->getSize();
    return this;
}

Symbol* Symbol::convertType(TYPE retType){
    if(type->type == TYPE_INT){
        if(retType == TYPE_FLOAT){
            Symbol* temp = gentemp(TYPE_FLOAT);
            emit("=", temp->name, "inttofloat(" + name + ")");
            return temp;
        }
        if(retType == TYPE_CHAR){
            Symbol* temp = gentemp(TYPE_CHAR);
            emit("=", temp->name, "inttochar(" + name + ")");
            return temp;
        }
        return this;
    }

    if(type->type == TYPE_FLOAT){
        if(retType == TYPE_INT){
            Symbol* temp = gentemp(TYPE_INT);
            emit("=", temp->name, "floattoint(" + name + ")");
            return temp;
        }
        if(retType == TYPE_CHAR){
            Symbol* temp = gentemp(TYPE_CHAR);
            emit("=", temp->name, "floattochar(" + name + ")");
            return temp;
        }
        return this;
    }
    
    if(type->type == TYPE_CHAR){
        if(retType == TYPE_INT){
            Symbol* temp = gentemp(TYPE_INT);
            emit("=", temp->name, "chartoint(" + name + ")");
            return temp;
        }
        if(retType == TYPE_FLOAT){
            Symbol* temp = gentemp(TYPE_FLOAT);
            emit("=", temp->name, "chartofloat(" + name + ")");
            return temp;
        }
        return this;
    }

    return this;
}

/* SymbolTable */

SymbolTable::SymbolTable(string name_, SymbolTable* parent_): name(name_), parent(parent_), count(0) {}

Symbol* SymbolTable::lookup(string name){
    for(auto it = symbols.begin(); it != symbols.end(); it++){
        if(it->name == name) return &(*it);
    }

    Symbol* sym = new Symbol(name);
    symbols.push_back(*sym);
    return &symbols.back();
}

void SymbolTable::update(){
    int offset=0;
    vector<SymbolTable*> nestedTables;

    for(auto it = symbols.begin(); it != symbols.end(); it++){
        it->offset = offset;
        offset += it->size;

        if(it->nestedTable) nestedTables.push_back(it->nestedTable);
    }

    for(auto it = nestedTables.begin(); it != nestedTables.end(); it++){
        (*it)->update();
    }
}

void SymbolTable::print(){}

/* Quadruple */

Quadruple::Quadruple(string res_, string arg1_, string op_, string arg2_): res(res_), arg1(arg1_), op(op_), arg2(arg2_) {}
Quadruple::Quadruple(string res_, int arg1_, string op_, string arg2_): res(res_), op(op_), arg2(arg2_) { arg1 = to_string(arg1_); }
// Quadruple::Quadruple(string res_, float arg1_, string op_, string arg2_): res(res_), op(op_), arg2(arg2_) { arg1 = to_string(arg1_); }

void Quadruple::print(){}

/* QuadTable */

void QuadTable::print(){}

/* Expression */

Expression::Expression(Symbol* symbol_): symbol(symbol_) {}

void Expression::convtoInt(){
    if(type == Expression::BOOL){
        symbol = gentemp(TYPE_INT);

        backpatch(truelist, nextinstr());
        emit("=", symbol->name, "true"); 

        emit("goto", to_string(nextinstr() + 1));  

        backpatch(falselist, nextinstr());
        emit("=", symbol->name, "false");
    }
}

void Expression::convtoBool(){
    if(type == Expression::NONBOOL){
        falselist = makelist(nextinstr());

        emit("==", "", symbol->name, "0");

        truelist = makelist(nextinstr());

        emit("goto", "");
    }
}

/* Array */

Array::Array(Symbol* symbol_): symbol(symbol_) {}

/* Global Functions */

void emit(string op, string res, string arg1, string arg2){
    quadTable->quads.push_back(new Quadruple(res, arg1, op, arg2));
}

void emit(string op, string res, int arg1, string arg2){
    quadTable->quads.push_back(new Quadruple(res, arg1, op, arg2));
}

list<int> makelist(int i){
    return list<int>(1, i);
}

list<int> merge(list<int> a, list<int> b){
    list<int> c = a;
    c.merge(b);
    return c;
}

void backpatch(list<int> a, int addr){
    for(auto it = a.begin(); it != a.end(); it++){
        quadTable->quads[*it - 1]->res = to_string(addr);
    }
}

bool typeCheck(Symbol*& a, Symbol*& b){
    if(typeCheck(a->type, b->type)) return true;

    if(a->type->type == TYPE_INT || b->type->type == TYPE_INT){
        a = a->convertType(TYPE_INT);
        b = b->convertType(TYPE_INT);
        return true;
    }

    if(a->type->type == TYPE_FLOAT || b->type->type == TYPE_FLOAT){
        a = a->convertType(TYPE_FLOAT);
        b = b->convertType(TYPE_FLOAT);
        return true;
    }

    return false;
}

bool typeCheck(SymbolType* a, SymbolType* b){
    if(!a || !b) return true;
    if(!a || !b || a->type != b->type) return false;
    return typeCheck(a->arrType, b->arrType);
}

int nextinstr(){
    return quadTable->quads.size() + 1;
}

Symbol* gentemp(TYPE type, string val){
    Symbol *temp = new Symbol("t" + to_string(currentST->count++), type, val);
    currentST->symbols.push_back(*temp);
    return &currentST->symbols.back();
}

void changeTable(SymbolTable* T){
    currentST = T;
}

int main(){
    blockCount = 0;
    globalST = new SymbolTable("Global");
    currentST = globalST;

    // yyparse();

    globalST->update();
    globalST->print();
}