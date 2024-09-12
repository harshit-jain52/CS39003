#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#define KEYWORD             1
#define IDENTIFIER          2
#define INTEGER_CONSTANT    3
#define FLOATING_CONSTANT   4
#define CHAR_CONSTANT       5
#define STRING_LITERAL      6
#define PUNCTUATOR          7
#define COMMENT             8
#define INVALID             -1
#define ALPHABET_SIZE       256

extern char* yytext;
extern int yylex();
extern int _yylineno_;

// Function to count newlines in a string
int count_newlines(char *s)
{
    int count = 0;
    for (int i = 0; s[i]; i++)
        count += (s[i] == '\n');

    return count;
}

// Linked List of integers, for line numbers
struct linked_node{
    int data;
    struct linked_node* next;
};
typedef struct linked_node* linked_list;

linked_list insertLL(int data, linked_list head) {
    if(head!=NULL && head->data == data) return head;
    linked_list new_node = (linked_list)malloc(sizeof(struct linked_node));
    new_node->data = data;
    new_node->next = head;
    return new_node;
}

void freeLL(linked_list head){
    if(head==NULL) return;
    freeLL(head->next);
    free(head);
}

// Symbol Table for Keywords (Hardcode implementation of 37 keywords with their frequencies)
typedef struct {
    char *word;
    int frequency;
} keyWord;

keyWord keyWords[] = {
    {"auto", 0},
    {"break", 0},
    {"case", 0},
    {"char", 0},
    {"const", 0},
    {"continue", 0},
    {"default", 0},
    {"do", 0},
    {"double", 0},
    {"else", 0},
    {"enum", 0},
    {"extern", 0},
    {"float", 0},
    {"for", 0},
    {"goto", 0},
    {"if", 0},
    {"inline", 0},
    {"int", 0},
    {"long", 0},
    {"register", 0},
    {"restrict", 0},
    {"return", 0},
    {"short", 0},
    {"signed", 0},
    {"sizeof", 0},
    {"static", 0},
    {"struct", 0},
    {"switch", 0},
    {"typedef", 0},
    {"union", 0},
    {"unsigned", 0},
    {"void", 0},
    {"volatile", 0},
    {"while", 0},
    {"_Bool", 0},
    {"_Complex", 0},
    {"_Imaginary", 0}
};

const int keyWordCount = sizeof(keyWords) / sizeof(keyWord);

void initKeywords(){
    for (int i = 0; i < keyWordCount; i++){
        keyWords[i].frequency=0;
    }
}

void addKeyWord(char *word) {
    for (int i = 0; i < keyWordCount; i++) {
        if (strcmp(keyWords[i].word, word) == 0) {
            keyWords[i].frequency++;
            return;
        }
    }
}

void printKeyWords() {
    for (int i = 0; i < keyWordCount; i++) {
        printf("\t%s -- %d time(s)\n", keyWords[i].word, keyWords[i].frequency);
    }
}

// Symbol Table for Constants (Linked Lists implementation with 3 types of constants)
struct const_{
    char *word;
    struct const_ *next;
    enum type{
        INTEGER = INTEGER_CONSTANT,
        FLOAT = FLOATING_CONSTANT,
        CHAR = CHAR_CONSTANT,
    } type;
};

typedef struct const_* constTable;

constTable addConstant(constTable T, const char *word, int type) {
    constTable newConst = (constTable)malloc(sizeof(struct const_));
    newConst->word = (char *)malloc(strlen(word) + 1);
    strcpy(newConst->word, word);
    newConst->type = type;
    newConst->next = T;
    T = newConst;
    return T;
}

void printConstants(constTable T) {
    while (T != NULL) {
        printf("\t%s -- ",T->word);
        if(T->type == INTEGER_CONSTANT)
            printf("INTEGER_CONSTANT\n");
        else if(T->type == FLOATING_CONSTANT)
            printf("FLOATING_CONSTANT\n");
        else if(T->type == CHAR_CONSTANT)
            printf("CHAR_CONSTANT\n");
        T = T->next;
    }
}

void freeConstants(constTable T) {
    if (T == NULL) return;
    freeConstants(T->next);
    free(T->word);
    free(T);
}

// Symbol Table for Punctuators (Trie implementation)
typedef struct TrieNode {
    struct TrieNode* children[ALPHABET_SIZE];
    int frequency;
    bool isEndOfWord;
} TrieNode;
const int punctuator_size = 4;

TrieNode* createNode() 
{
    TrieNode* node = (TrieNode*)malloc(sizeof(TrieNode));
    node->isEndOfWord = false;
    for (int i = 0; i < ALPHABET_SIZE; i++) {
        node->children[i] = NULL;
    }
    node->frequency = 0;
    return node;
}

void insert(TrieNode* root, const char* punctuator) {
    TrieNode* node = root;
    while (*punctuator) {
        unsigned char index = (unsigned char)*punctuator;
        if (node->children[index] == NULL) {
            node->children[index] = createNode();
        }
        node = node->children[index];
        punctuator++;
    }
    node->isEndOfWord = true;
    node->frequency++;
}

void printNames(TrieNode* node, char* punctuator_base, int depth) {
    if (node == NULL) return;

    if (node->isEndOfWord) {
        punctuator_base[depth] = '\0';
        printf("\t%s -- appeared %d time(s)\n", punctuator_base, node->frequency);
    }

    for (int i = 0; i < ALPHABET_SIZE; i++) {
        if (node->children[i] != NULL) {
            punctuator_base[depth] = (char)i;
            printNames(node->children[i], punctuator_base, depth + 1);
        }
    }
}

void printPunctuators(TrieNode* t) {
    char punctuator_base[punctuator_size];
    printNames(t, punctuator_base, 0);
}

void freeTrie(TrieNode* root) {
    if (root == NULL) return;
    for (int i = 0; i < ALPHABET_SIZE; i++) {
        freeTrie(root->children[i]);
    }
    free(root);
}

// Symbol Table for Identifiers and String Literals (Linked List implementation with line numbers)
struct tableWithLineNums{
    char *word;
    struct tableWithLineNums *next;
    linked_list lineNums;
};
typedef struct tableWithLineNums* symbolTable;

symbolTable insertSymbolTable(symbolTable T, const char *word, int lineNum) {
    symbolTable mover = T;
    while (mover != NULL) {
        if (strcmp(mover->word, word) == 0) {
            mover->lineNums = insertLL(lineNum, mover->lineNums);
            return T;
        }
        mover = mover->next;
    }

    symbolTable newId = (symbolTable)malloc(sizeof(struct tableWithLineNums));
    newId->word = (char *)malloc(strlen(word) + 1);
    strcpy(newId->word, word);
    newId->next = T;
    newId->lineNums = insertLL(lineNum, NULL);
    T = newId;
    return T;
}

void printSymbolTable(symbolTable T) {
    while (T != NULL) {
        printf("\t%s -- at line(s) ", T->word);
        linked_list lineNums = T->lineNums;
        while (lineNums != NULL) {
            printf("%d ", lineNums->data);
            lineNums = lineNums->next;
        }
        printf("\n");
        T = T->next;
    }
}

void freeSymbolTable(symbolTable T) {
    if (T == NULL) return;
    freeSymbolTable(T->next);
    free(T->word);
    free(T->lineNums);
    free(T);
}

// Symbol Table for TinyC Compiler
struct tinyC_{
    constTable constants;
    symbolTable identifiers;
    symbolTable stringLiterals;
    TrieNode* root_punctuators;
};
typedef struct tinyC_* tinyC_SymbolTable;

tinyC_SymbolTable init_SymbolTable() {
    tinyC_SymbolTable ST = (tinyC_SymbolTable)malloc(sizeof(struct tinyC_));
    initKeywords();
    ST->constants = NULL;
    ST->identifiers = NULL;
    ST->stringLiterals = NULL;
    ST->root_punctuators = createNode();
    return ST;
}

void printTinyCTable(tinyC_SymbolTable T){
    printf("\n1. All Keywords:\n");
    printKeyWords();

    printf("\n2. Identifiers defined/declared:\n");
    printSymbolTable(T->identifiers);

    printf("\n3. Constants:\n");
    printConstants(T->constants);

    printf("\n4. String Literals:\n");
    printSymbolTable(T->stringLiterals);

    printf("\n5. Punctuators used:\n");
    printPunctuators(T->root_punctuators);
}

void free_TC_ST(tinyC_SymbolTable T) {
    if(T == NULL) {
        return;
    }
    freeConstants(T->constants);
    freeSymbolTable(T->identifiers);
    freeSymbolTable(T->stringLiterals);
    freeTrie(T->root_punctuators);
    free(T);
    return;
}

// Driver
int main(int argc, char *argv[]) {

    // Initialize Symbol Table
    tinyC_SymbolTable TINYC_ST = init_SymbolTable();

    printf("Tokenizing the input file...\n\n");
    int next_token = 0;

    while (next_token = yylex())
    {
        switch (next_token)
        {
        case KEYWORD:
            printf("<KEYWORD,%s>\n", yytext);
            addKeyWord(yytext);
            break;
        case IDENTIFIER:
            printf("<IDENTIFIER,%s>\n", yytext);
            TINYC_ST->identifiers = insertSymbolTable(TINYC_ST->identifiers, yytext, _yylineno_);
            break;
        case FLOATING_CONSTANT:
            printf("<CONSTANT,%s>\n", yytext);
            TINYC_ST->constants = addConstant(TINYC_ST->constants, yytext, FLOATING_CONSTANT);
            break;
        case INTEGER_CONSTANT:
            printf("<CONSTANT,%s>\n", yytext);
            TINYC_ST->constants = addConstant(TINYC_ST->constants, yytext, INTEGER_CONSTANT);
            break;
        case CHAR_CONSTANT:
            printf("<CONSTANT,%s>\n", yytext);
            TINYC_ST->constants = addConstant(TINYC_ST->constants, yytext, CHAR_CONSTANT);
            break;
        case STRING_LITERAL:
            printf("<STRING_LITERAL,%s>\n", yytext);
            TINYC_ST->stringLiterals = insertSymbolTable(TINYC_ST->stringLiterals, yytext, _yylineno_);
            break;
        case PUNCTUATOR:
            printf("<PUNCTUATOR,%s>\n", yytext);
            insert(TINYC_ST->root_punctuators, yytext);
            break;
        case COMMENT:
            _yylineno_ += count_newlines(yytext);
            // printf("%s %d\n", yytext, _yylineno_);
            break;
        default:
            printf("<INVALID_TOKEN,%s> at line no. %d\n", yytext, _yylineno_);
            break;
        }
    }

    printf("\n\nTokenization complete.\n\nPrinting the symbol tables:\n");

    // Print Symbol Table
    printTinyCTable(TINYC_ST);

    // Memory Deallocation
    free_TC_ST(TINYC_ST);
    
    return 0;
}
