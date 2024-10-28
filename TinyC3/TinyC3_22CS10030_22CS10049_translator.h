#ifndef _TRANSLATOR_H
#define _TRANSLATOR_H

extern int yyparse();

#include <iostream>
#include <string>
#include <cstring>
#include <list>
#include <vector>
#include <stack>
#include <map>
#include <iomanip>
using namespace std;

#define __VOID_SZ 0
#define __CHAR_SZ 1
#define __INT_SZ 4
#define __FLOAT_SZ 8
#define __PTR_SZ 4

class SymbolType;
class Symbol;
class SymbolTable;
class Quadruple;
class QuadTable;
class Expression;
class Array;
class Statement;
class Environment;

/*
enum: TYPE
*description: Defines the data types of the symbols
*/
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

/*
class: SymbolType
*description: Defines the complete type of a symbol
*attributes:
    type: TYPE -- data type of the symbol
    width: int -- width of the symbol (if the type is an array, otherwise 1)
    arrType: SymbolType* -- type of the array/pointer elements (if the type is an array/pointer)
*methods:
    SymbolType(TYPE, SymbolType*, int) -- constructor
    getSize() -- returns the computed size of the type
    getType() -- returns the type in string format
*/
class SymbolType {
public:
    TYPE type; 
    int width; // size of the type
    SymbolType* arrType;

    SymbolType(TYPE, SymbolType* = NULL, int = 1);
    int getSize();
    string getType();
};

/*
class: Symbol
*description: Defines a symbol in the symbol table
*attributes:
    name: string -- name of the symbol
    type: SymbolType* -- type of the symbol
    initial_value: string -- initial value of the symbol
    size: int -- size of the symbol
    offset: int -- offset of the symbol in the symbol table
    nestedTable: SymbolTable* --
*methods:
    Symbol(string, TYPE, string) -- constructor
    update(SymbolType*) -- updates the type of the symbol to the given type
    convertType(TYPE) -- converts the type of the symbol to the given type
*/
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
    Symbol* convertType(TYPE);

};

/*
class: SymbolTable
*description: Defines a symbol table
*attributes:
    name: string -- name of the symbol table
    count: int -- number of symbols in the symbol table
    symbols: list<Symbol> -- list of symbols in the symbol table
    parent: SymbolTable* -- parent symbol table (NULL if it is the global symbol table)
*methods:
    SymbolTable(string, SymbolTable*) -- constructor
    lookup(string) -- looks up a symbol in the symbol table, adds it if not found
    print() -- prints the symbol table
    update() -- updates the symbol table
*/
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

/*
class: Quadruple
*description: Defines a quadruple in the intermediate code
*attributes:
    op: string -- operation
    arg1: string -- argument 1
    arg2: string -- argument 2
    res: string -- result
*methods:
    Quadruple(string, string, string, string) -- constructor
    Quadruple(string, int, string, string) -- constructor
    print() -- prints the quadruple
*/
class Quadruple {
public:
    string op;
    string arg1;
    string arg2;
    string res;   

    Quadruple(string, string, string = "=", string = "");
    Quadruple(string, int, string = "=", string = "");

    void print();
};

/*
class: QuadTable
*description: Defines the table of quadruples
*attributes:
    quads: vector<Quadruple*> -- incremental list of quadruples
*methods:
    QuadTable() -- constructor
    print() -- prints the quad table
*/
class QuadTable {
public:
    vector<Quadruple*> quads;

    QuadTable();
    void print();
};

/*
class: Array
*description: Defines array attributes (used while parsing)
*attributes:
    loca: Symbol* -- symbol corresponding to address of array (used for offset calculation)
    type: type_ -- type of Array (array or pointer or neither)
    symbol: Symbol* -- symbol corresponding to the array
    childType: SymbolType* -- type of the array elements
*methods:
    Array(Symbol*) -- constructor
*/
class Array{
public:
    Symbol* loca;
    enum type_ {NONE, ARRAY, POINTER} type;
    Symbol* symbol;
    SymbolType *childType; 

    Array(Symbol* = NULL);
};

/*
class: Expression
*description: Defines expression attributes (used while parsing)
*attributes:
    symbol: Symbol* -- symbol corresponding to the expression
    type: type_ -- type of the expression (bool or non-bool)
    truelist: list<int> -- list of jump instructions into which we must insert the label to which the control should jump if the expression is true
    falselist: list<int> -- list of jump instructions into which we must insert the label to which the control should jump if the expression is false
*methods:
    Expression(Symbol*) -- constructor
    convtoInt() -- converts the expression to an integer
    convtoBool() -- converts the expression to a boolean
*/
class Expression {
public:
    Symbol *symbol;
    enum type_ {NONBOOL, BOOL} type;
    list<int> truelist;
    list<int> falselist;

    Expression(Symbol* = NULL);
    void convtoInt();
    void convtoBool();
};

/*
class: Statement
*description: Defines statement attributes (used while parsing)
*attributes:
    nextlist: list<int> -- list of jump instructions into which we must insert the label to which the control should jump after the statement
*methods:
    Statement() -- constructor
*/
class Statement {
public:
    list<int>nextlist;

    Statement();
};

/*
class: Environment
*description: Defines the environment of the parser
*attributes:
    STstack: stack<SymbolTable*> -- stack of symbol tables (current symbol table at the top)
    currSymbol: Symbol* -- current symbol
    currType: TYPE -- current type
    quadTable: QuadTable* -- table of quadruples
    blockCount: int -- count of blocks encountered
    sizeMap: map<TYPE, int> -- map of data types to their sizes
    strMap: map<TYPE, string> -- map of data types to their string representations
*methods:
    Environment() -- constructor
*/
class Environment{
public:
    stack<SymbolTable*> STstack;
    Symbol* currSymbol;
    TYPE currType;
    QuadTable* quadTable;
    int blockCount;
    map<TYPE, int> sizeMap;
    map<TYPE, string> strMap;

    Environment();
};

// Global variables
extern Environment* parseEnv;

// Global functions
void emit(string, string, string="", string="");
void emit(string, string, int, string="");

list<int> makelist(int);
list<int> merge(list<int>, list<int>);
void backpatch(list<int>, int);

bool typeCheck(Symbol *&, Symbol *&);
bool typeCheck(SymbolType *, SymbolType *);

int nextinstr();
Symbol* gentemp(TYPE, string = "-");

#endif