#include "TinyC3_22CS10030_22CS10049_translator.h"

/* SymbolType */

SymbolType::SymbolType(TYPE type_, SymbolType* arrType_, int width_): type(type_), width(width_), arrType(arrType_) {}

int SymbolType::getSize(){
    if(type == TYPE_ARRAY) return width*(arrType->getSize());
    return Environment::parseEnv().sizeMap[type];
}

string SymbolType::getType(){
    if(type == TYPE_ARRAY) return "array(" + to_string(width) + ", " + arrType->getType() + ")";
    if(type == TYPE_PTR) return "ptr(" + arrType->getType() + ")";
    return Environment::parseEnv().strMap[type];
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
            Environment::parseEnv().quadTable->emit("=", temp->name, "inttofloat(" + name + ")");
            return temp;
        }
        if(retType == TYPE_CHAR){
            Symbol* temp = gentemp(TYPE_CHAR);
            Environment::parseEnv().quadTable->emit("=", temp->name, "inttochar(" + name + ")");
            return temp;
        }
        return this;
    }

    if(type->type == TYPE_FLOAT){
        if(retType == TYPE_INT){
            Symbol* temp = gentemp(TYPE_INT);
            Environment::parseEnv().quadTable->emit("=", temp->name, "floattoint(" + name + ")");
            return temp;
        }
        if(retType == TYPE_CHAR){
            Symbol* temp = gentemp(TYPE_CHAR);
            Environment::parseEnv().quadTable->emit("=", temp->name, "floattochar(" + name + ")");
            return temp;
        }
        return this;
    }
    
    if(type->type == TYPE_CHAR){
        if(retType == TYPE_INT){
            Symbol* temp = gentemp(TYPE_INT);
            Environment::parseEnv().quadTable->emit("=", temp->name, "chartoint(" + name + ")");
            return temp;
        }
        if(retType == TYPE_FLOAT){
            Symbol* temp = gentemp(TYPE_FLOAT);
            Environment::parseEnv().quadTable->emit("=", temp->name, "chartofloat(" + name + ")");
            return temp;
        }
        return this;
    }

    return this;
}

void Symbol::setinit(Symbol* rhs){
    if(rhs->initial_value != "-"){
        initial_value = rhs->initial_value;  
        if(type->type != rhs->type->type) 
            initial_value = "-"; 
    }
}

/* SymbolTable */

SymbolTable::SymbolTable(string name_, SymbolTable* parent_): name(name_), parent(parent_), count(0) {}

Symbol* SymbolTable::lookup(string name){
    for(list<Symbol>::iterator it = symbols.begin(); it != symbols.end(); it++){
        if(it->name == name) return &(*it);
    }

    Symbol* sym = new Symbol(name);
    symbols.push_back(*sym);
    return &symbols.back();
}

void SymbolTable::update(){
    int offset=0;
    vector<SymbolTable*> nestedTables;

    for(list<Symbol>::iterator it = symbols.begin(); it != symbols.end(); it++){
        it->offset = offset;
        offset += it->size;

        if(it->nestedTable) nestedTables.push_back(it->nestedTable);
    }

    for(vector<SymbolTable*>::iterator it = nestedTables.begin(); it != nestedTables.end(); it++){
        (*it)->update();
    }
}

void SymbolTable::print(){
    printDeco();
    cout << "Symbol Table: " << name << "\tParent: " << (parent==NULL?"NULL":parent->name) << endl;

    printDeco();
    printSTCols({"Name", "Type", "Initial Value", "Size", "Offset", "Nested Table"});

    vector<SymbolTable*> nestedTables;

    for(list<Symbol>::iterator it = symbols.begin(); it != symbols.end(); it++){
        const vector<string> symbols_values = {it->name, it->type->getType(), it->initial_value, to_string(it->size), to_string(it->offset), (it->nestedTable==NULL?"NULL":it->nestedTable->name)};
        printSTCols(symbols_values);
        if(it->nestedTable) nestedTables.push_back(it->nestedTable);
    }
    
    printDeco();
    cout << endl;

    for(vector<SymbolTable*>::iterator it = nestedTables.begin(); it != nestedTables.end(); it++){
        (*it)->print();
    }
}

/* Quadruple */

Quadruple::Quadruple(string res_, string arg1_, string op_, string arg2_): res(res_), arg1(arg1_), op(op_), arg2(arg2_) {}
Quadruple::Quadruple(string res_, int arg1_, string op_, string arg2_): res(res_), op(op_), arg2(arg2_) { arg1 = to_string(arg1_); }

void Quadruple::print(){
    if(op == "+" || op == "-" || op == "*" || op == "/" || op == "%" || op == "|" || op == "^" || op == "&" || op == "<<" || op == ">>"){
        cout << res << " = " << arg1 << " " << op << " " << arg2 << endl;
    }
    else if (op == "==" || op == "!=" || op == "<=" || op == ">=" || op == "<" || op == ">"){
        cout << "if " << arg1 << " " << op << " " << arg2 << " goto " << res << endl;
    }
    else if(op=="ff"){
        cout << "ifFalse " << arg1 << " goto " << res << endl;
    }
    else if(op == "= &" || op == "= *" || op == "= -" || op == "= !" || op == "= ~"){
        cout << res << " " << op << arg1 << endl;
    }
    else if(op == "*="){
        cout << "*" << res << " = " << arg1 << endl;
    }
    else if(op == "=[]"){
        cout << res << " = " << arg1 << "[" << arg2 << "]" << endl;
    }
    else if(op == "[]="){
        cout << res << "[" << arg1 << "]" << " = " << arg2 << endl;
    }
    else if(op == "goto" || op == "param" || op == "return"){
        cout << op << " " << res << endl;
    }
    else if(op == "call"){
        cout << res << " = call " << arg1 << ", " << arg2 << endl;
    }
    else if(op == "label"){
        cout << res << ":" << endl;
    }
    else if(op == "="){
        cout << res << " = " << arg1 << endl;
    }
}

/* QuadTable */

QuadTable::QuadTable(): quads(0) {}

void QuadTable::print(){
    cout << "Three Address Codes:" << endl;
    for(int i=0; i<quads.size(); i++){
        string serial = to_string(i+1) + ".";
        cout << setw(5) << left << setfill(' ') << serial;
        quads[i]->print();
    }
}

/* Array */

Array::Array(Symbol* symbol_): symbol(symbol_) {}

/* Expression */

Expression::Expression(Symbol* symbol_): symbol(symbol_) {}

void Expression::convtoInt(){
    if(type == Expression::BOOL){
        symbol = gentemp(TYPE_INT);

        backpatch(truelist, nextinstr());
        Environment::parseEnv().quadTable->emit("=", symbol->name, "1"); 

        Environment::parseEnv().quadTable->emit("goto", to_string(nextinstr() + 2));  

        backpatch(falselist, nextinstr());
        Environment::parseEnv().quadTable->emit("=", symbol->name, "0");
    }
}

void Expression::convtoBool(){
    if(type == Expression::NONBOOL){
        falselist = makelist(nextinstr());
        Environment::parseEnv().quadTable->emit("ff", "", symbol->name);
    }
}

/* Statement */

Statement::Statement() {}

/* Environment */

Environment::Environment(){
    STstack.push(new SymbolTable("Global"));
    quadTable = new QuadTable();
    blockCount = 0;
    sizeMap = {
        {TYPE_VOID, __VOID_SZ},
        {TYPE_CHAR, __CHAR_SZ},
        {TYPE_INT, __INT_SZ},
        {TYPE_FLOAT, __FLOAT_SZ},
        {TYPE_PTR, __PTR_SZ}
    };
    strMap = {
        {TYPE_VOID, "void"},
        {TYPE_CHAR, "char"},
        {TYPE_INT, "int"},
        {TYPE_FLOAT, "float"},
        {TYPE_FUNC, "function"},
        {TYPE_BLOCK, "block"}
    };
}

Environment& Environment::parseEnv(){
    static Environment env;
    return env;
}

/* Global Functions */

void QuadTable::emit(string op, string res, string arg1, string arg2){
    quads.push_back(new Quadruple(res, arg1, op, arg2));
}

void QuadTable::emit(string op, string res, int arg1, string arg2){
    quads.push_back(new Quadruple(res, arg1, op, arg2));
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
    for(list<int>::iterator it = a.begin(); it != a.end(); it++){
        Environment::parseEnv().quadTable->quads[*it - 1]->res = to_string(addr);
    }
}

bool typeCheck(Symbol*& a, Symbol*& b){
    if(typeCheck(a->type, b->type)) return true;

    if(a->type->type == TYPE_FLOAT || b->type->type == TYPE_FLOAT){
        a = a->convertType(TYPE_FLOAT);
        b = b->convertType(TYPE_FLOAT);
        return true;
    }

    if(a->type->type == TYPE_INT || b->type->type == TYPE_INT){
        a = a->convertType(TYPE_INT);
        b = b->convertType(TYPE_INT);
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
    return Environment::parseEnv().quadTable->quads.size() + 1;
}

Symbol* gentemp(TYPE type, string val){
    Symbol *temp = new Symbol("t" + to_string(Environment::parseEnv().STstack.top()->count++), type, val);
    Environment::parseEnv().STstack.top()->symbols.push_back(*temp);
    return &Environment::parseEnv().STstack.top()->symbols.back();
}

void printSTCols(const vector<string>& names, int nameW, char sep, int numW) {
    for(int i=0; i<names.size(); i++){
        if(i==3 || i==4) 
            cout << left << setw(numW) << setfill(sep) << names[i];
        else 
            cout << left << setw(nameW) << setfill(sep) << names[i];
    }
    cout << endl;
}

inline void printDeco(){
    cout << setfill('-') << setw(240) << "-" << endl;
}

int main(){

    yyparse();

    Environment::parseEnv().STstack.top()->update();
    Environment::parseEnv().STstack.top()->print();

    Environment::parseEnv().quadTable->print();
}