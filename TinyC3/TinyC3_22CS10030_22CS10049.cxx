#include "TinyC3_22CS10030_22CS10049.h"

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

// Symbol* Symbol::convertType(TYPE type_){}

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
Quadruple::Quadruple(string res_, float arg1_, string op_, string arg2_): res(res_), op(op_), arg2(arg2_) { arg1 = to_string(arg1_); }

void Quadruple::print(){}

/* QuadTable */

void QuadTable::print(){}

/* Expression */

Expression::Expression(Symbol* symbol_): symbol(symbol_) {}
void Expression::convtoInt(){}
void Expression::convtoBool(){}

/* Array */

Array::Array(Symbol* symbol_): symbol(symbol_) {}