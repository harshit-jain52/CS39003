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

enum TYPE {
    TYPE_VOID,
    TYPE_CHAR,
    TYPE_INT,
    TYPE_FLOAT,
    TYPE_PTR,
    TYPE_FUNC,
    TYPE_ARRAY,
    TYPE_BLOCK
};

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

class SymbolType {
public:
    TYPE type; 
    int width; // size of the type
    SymbolType* arrType;

    SymbolType(TYPE, SymbolType* = NULL, int = 1);
    int getSize();
    string getType();
};

class Symbol {
public:
    string name;
    SymbolType* type;
    string initial_value;
    int size;
    int offset;
    SymbolTable* nestedTable;

    Symbol(string, TYPE = TYPE_INT, string="-");
    Symbol* update(SymbolType*);
    // Symbol* convertType(TYPE);

};

class SymbolTable {
public:
    string name;
    int count;
    list<Symbol> symbols;
    SymbolTable* parent;
    
    SymbolTable(string = "NULL", SymbolTable* = NULL);
    Symbol* lookup(string);

    void print();
    void update();
};

class Quadruple {
public:
    string op;
    string arg1;
    string arg2;
    string res;   

    Quadruple(string, string, string = "=", string = "");
    Quadruple(string, int, string = "=", string = "");
    Quadruple(string, float, string = "=", string = "");

    void print();
};

class QuadTable {
public:
    vector<Quadruple*> quads;

    void print();
};

class Expression {
public:
    Symbol *symbol;
    enum type_ {NONBOOL, BOOL} type;
    list<int> truelist;
    list<int> falselist;
    list<int> nextlist;

    Expression(Symbol* = NULL);
    void convtoInt();
    void convtoBool();
};

class Array{
public:
    Symbol* loca;
    enum type_ {NONE, ARRAY, POINTER} type;
    Symbol* symbol;
    SymbolType *childType; 

    Array(Symbol* = NULL);
};

class Statement {
public:
    list<int>nextlist;
};

