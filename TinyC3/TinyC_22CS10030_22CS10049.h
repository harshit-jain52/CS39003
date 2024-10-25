#include <iostream>
#include <list>
#include <vector>
#include <map>
using namespace std;

#define __VOID_SZ 0
#define __CHAR_SZ 1
#define __INT_SZ 4
#define __FLOAT_SZ 8
#define __PTR_SZ 4

map<string, int> sizeMap = {
    {"void", __VOID_SZ},
    {"char", __CHAR_SZ},
    {"int", __INT_SZ},
    {"float", __FLOAT_SZ},
    {"ptr", __PTR_SZ}
};
// typedef enum type_ {
//     TYPE_VOID,
//     TYPE_CHAR,
//     TYPE_INT,
//     TYPE_FLOAT,
//     TYPE_PTR
// }type_;

class SymbolType {
public:
    string type; 
    int width; // size of the type
    SymbolType* arrType;

    SymbolType(string, int = 1, SymbolType* = NULL);
    int getSize();
};

class Symbol {
public:
    string name;
    SymbolType* type;
    string initial_value;
    int size;
    int offset;
    SymbolType* nestedTable;

    Symbol(string, string, int = 0, SymbolType* = NULL);

};

class SymbolTable {
public:
    string name;
    int count;
    list<Symbol> table;
    SymbolTable* parent;
    
    SymbolTable(string = "global");

    Symbol* lookup(string);
    Symbol* gentemp(SymbolType*, string = ""); 

    void print();
    void update();
};

class Quadruple {
public:
    string op;
    string arg1;
    string arg2;
    string result;   

    Quadruple(string, string, string = "=", string = "");
    Quadruple(string, int, string = "=", string = "");
    Quadruple(string, float, string = "=", string = "");

    void print();
};

class QuadTable {
public:
    vector<Quadruple> quads;
    
    void print();
};



