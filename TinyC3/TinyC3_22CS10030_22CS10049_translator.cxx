#include "TinyC3_22CS10030_22CS10049_translator.h"

/* -------------------- SymbolType -------------------- */

// Default Constructor
SymbolType::SymbolType(TYPE type_, SymbolType* arrType_, int width_): type(type_), width(width_), arrType(arrType_) {}

// Calculate size of symbol type: for arrays, size = width * size of array type; else size = size of type in sizeMap
int SymbolType::getSize(){
    if(type == TYPE_ARRAY) return width*(arrType->getSize());
    return Environment::parseEnv().sizeMap[type];
}

// Get string representation of symbol type: for arrays and pointers, find recursively; else return string from strMap
string SymbolType::getType(){
    if(type == TYPE_ARRAY) return "array(" + to_string(width) + ", " + arrType->getType() + ")";
    if(type == TYPE_PTR) return "ptr(" + arrType->getType() + ")";
    return Environment::parseEnv().strMap[type];
}

/* -------------------- Symbol -------------------- */

// Default Constructor
Symbol::Symbol(string name_, TYPE inh_type, string init_val): name(name_), type(new SymbolType(inh_type)), offset(0), nestedTable(NULL), initial_value(init_val) {
    size = type->getSize();
}

// Update symbol type and size
Symbol* Symbol::update(SymbolType* type_){
    type = type_;
    size = type->getSize();
    return this;
}

// Convert symbol type to given type, and emit conversion quadruples if necessary
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

// Set initial value of newly declared symbol based on another symbol
void Symbol::setinit(Symbol* rhs){
    if(rhs->initial_value != "-"){
        initial_value = rhs->initial_value;  
        if(type->type != rhs->type->type) 
            initial_value = "-"; 
    }
}

// Print the symbol
void Symbol::print(){
    const vector<string> symbols_values = {name, type->getType(), initial_value, to_string(size), to_string(offset), (nestedTable==NULL?"NULL":nestedTable->name)};
    printSTCols(symbols_values);
}

/* -------------------- SymbolTable -------------------- */

// Default Constructor
SymbolTable::SymbolTable(string name_, SymbolTable* parent_): name(name_), parent(parent_), count(0) {}

// Recursively find a symbol and return the pointer to it, return NULL if not found
Symbol* SymbolTable::lookup(string name){
    for(list<Symbol>::iterator it = symbols.begin(); it != symbols.end(); it++){
        if(it->name == name) return &(*it);
    }

    if(parent != NULL) return parent->lookup(name);
    return NULL;
}

// Update the symbol table before printing: calculate offsets and update nested tables recursively
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

// Print the symbol table and its nested tables recursively
void SymbolTable::print(){
    printDeco();
    cout << "Symbol Table: " << name << "\tParent: " << (parent==NULL?"NULL":parent->name) << endl;

    printDeco();
    printSTCols({"Name", "Type", "Initial Value", "Size", "Offset", "Nested Table"});

    vector<SymbolTable*> nestedTables;

    for(list<Symbol>::iterator it = symbols.begin(); it != symbols.end(); it++){
        it->print();
        if(it->nestedTable) nestedTables.push_back(it->nestedTable);
    }
    
    printDeco();
    cout << endl;

    for(vector<SymbolTable*>::iterator it = nestedTables.begin(); it != nestedTables.end(); it++){
        (*it)->print();
    }
}

/* -------------------- Quadruple -------------------- */

// Overloaded Constructors
Quadruple::Quadruple(string res_, string arg1_, string op_, string arg2_): res(res_), arg1(arg1_), op(op_), arg2(arg2_) {}
Quadruple::Quadruple(string res_, int arg1_, string op_, string arg2_): res(res_), op(op_), arg2(arg2_) { arg1 = to_string(arg1_); }

// Print the quadruple based on the operation
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

/* -------------------- QuadTable -------------------- */

// Default Constructor
QuadTable::QuadTable(): quads(0) {}

// Print the quad array (three address codes)
void QuadTable::print(){
    cout << "Three Address Codes:" << endl;
    for(int i=0; i<quads.size(); i++){
        string serial = to_string(i+1) + ".";
        cout << setw(5) << left << setfill(' ') << serial;
        quads[i]->print();
    }
}

// Overloaded method to add quadruple to the table
void QuadTable::emit(string op, string res, string arg1, string arg2){
    quads.push_back(new Quadruple(res, arg1, op, arg2));
}

// Overloaded method to add quadruple to the table
void QuadTable::emit(string op, string res, int arg1, string arg2){
    quads.push_back(new Quadruple(res, arg1, op, arg2));
}

/* -------------------- Array -------------------- */

// Default Constructor
Array::Array(Symbol* symbol_): symbol(symbol_) {}

/* -------------------- Expression -------------------- */

// Default Constructor
Expression::Expression(Symbol* symbol_): symbol(symbol_) {}

// Convert expression to integer: if boolean, emit quadruples to convert to integer
void Expression::convtoInt(){
    if(type == Expression::BOOL){
        symbol = gentemp(TYPE_INT);

        backpatch(truelist, nextinstr());
        Environment::parseEnv().quadTable->emit("=", symbol->name, "1"); 

        Environment::parseEnv().quadTable->emit("goto", to_string(nextinstr() + 1));  

        backpatch(falselist, nextinstr());
        Environment::parseEnv().quadTable->emit("=", symbol->name, "0");
    }
}

// Convert expression to boolean: if non-boolean, emit quadruples to convert to boolean
void Expression::convtoBool(){
    if(type == Expression::NONBOOL){
        falselist = makelist(nextinstr());
        Environment::parseEnv().quadTable->emit("ff", "", symbol->name);
    }
}

/* -------------------- Statement -------------------- */

// Default Constructor
Statement::Statement() {}

/* -------------------- Environment -------------------- */

// Private Constructor
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

// Return the singleton instance of the class
Environment& Environment::parseEnv(){
    static Environment env;
    return env;
}

// Return the pointer to a given symbol in the environment, add it if not found
Symbol* Environment::lookup(string name){
    Symbol* sym =  STstack.top()->lookup(name);
    if(sym==NULL || name=="return") sym = addSymbol(name);
    return sym;
}

// Add a symbol in the current symbol table
Symbol* Environment::addSymbol(string name){
    Symbol* sym = new Symbol(name);
    STstack.top()->symbols.push_back(*sym);
    return &STstack.top()->symbols.back();
}

/* -------------------- Global Functions -------------------- */

// Create and return a list with a single integer
list<int> makelist(int i){
    return list<int>(1, i);
}

// Return a list with elements of both input lists
list<int> merge(list<int> a, list<int> b){
    list<int> c = a;
    c.merge(b);
    return c;
}

// Iterate over the list and attach the quadruples with the given address (label)
void backpatch(list<int> a, int addr){
    for(list<int>::iterator it = a.begin(); it != a.end(); it++){
        Environment::parseEnv().quadTable->quads[*it - 1]->res = to_string(addr);
    }
}

// Check if two symbol types are compatible, and convert if necessary
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

// Recursively check if two symbol types are compatible
bool typeCheck(SymbolType* a, SymbolType* b){
    if(!a || !b) return true;
    if(!a || !b || a->type != b->type) return false;
    return typeCheck(a->arrType, b->arrType);
}

// Return the next instruction number (size of quad array + 1)
int nextinstr(){
    return Environment::parseEnv().quadTable->quads.size() + 1;
}

// Generate a temporary symbol ("t" + count of temporaries in current table) and add it to the symbol table
Symbol* gentemp(TYPE type, string val){
    Symbol *temp = new Symbol("t" + to_string(Environment::parseEnv().STstack.top()->count++), type, val);
    Environment::parseEnv().STstack.top()->symbols.push_back(*temp);
    return &Environment::parseEnv().STstack.top()->symbols.back();
}

/* -------------------- Helper Functions for Printing -------------------- */

// Print the symbol table columns with given widths and separators
void printSTCols(const vector<string>& names, int nameW, char sep, int numW) {
    for(int i=0; i<names.size(); i++){
        if(i==3 || i==4) 
            cout << left << setw(numW) << setfill(sep) << names[i];
        else 
            cout << left << setw(nameW) << setfill(sep) << names[i];
    }
    cout << endl;
}

// Print a horizontal line
inline void printDeco(){
    cout << setfill('-') << setw(240) << "-" << endl;
}

/* -------------------- Main Program --------------------*/
int main(){

    try{
        // Parse the input using flex and bison
        yyparse();

        // Update and print the symbol table
        Environment::parseEnv().STstack.top()->update();
        Environment::parseEnv().STstack.top()->print();

        // Print the quad array
        Environment::parseEnv().quadTable->print();
    }
    catch(const char* msg){
        cout << msg << endl;
    }

}