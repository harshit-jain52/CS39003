#include "TinyC_22CS10030_22CS10049.h"

// SymbolType

SymbolType::SymbolType(string type_, int width_, SymbolType* arrType_): type(type_), width(width_), arrType(arrType_) {}
int SymbolType::getSize(){
    if(type == "arr") return width*arrType->getSize();
    return sizeMap[type];
}
// Symbol

Symbol::Symbol(string name_, string inh_type, int width_, SymbolType* arrType_): name(name_), type(new SymbolType(inh_type, width_, arrType_)), initial_value("null"), size(width_), offset(0), nestedTable(NULL) {}