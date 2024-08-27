/* Test File */

#include <stdio.h>
#include <stdarg.h>

extern int yylineno;
const long INF = 1e9;

struct node_ {
    int value;
	struct node_* next;
};

union foo {
    char* c;
    int* p;
};

typedef struct node_ node;

inline void newline(){
    auto char* str = "Customized newline function";
    printf("%s\n", str);
}

enum week_ { Mon = 1, Tue};
typedef enum week_ week;

int LargestNumber(int n, ...)
{
    va_list ptr;
    va_start(ptr, n);
   
    int max = va_arg(ptr, int);
 
    for (int i = 0; i < n-1; i++) {
        int temp = va_arg(ptr, int);
        max = temp > max ? temp : max;
    }

    va_end(ptr); 
    return max;
}

int main()
{
    long int x = 10;
    short unsigned int y = 20;

    const float f0 = 12.34;
    float f1 = 12.;
    float f2 = .34;
    float f3 = 12.34e-2;
    float f4 = 12.34e+2;
    float f5 = .34E2;
    float f6 = 1234e-2;
    double d1 = 12.34;
    char c1 = '$';
    char c2 = '\r';
    char c3 = 'x';
    char c4 = ' ';
    char c5 = '"';
    char c6 = '\'';
    char c7 = '\n';
    char c8 = '';   // Invalid
    char* str1 = "\"";
    char* str2 = "";
    _Bool err = 1;  

    node* head = (node*)malloc(sizeof(node));
    head->value = 10;
    head->next = NULL;
    printf("Node head value = &d\n", (*head).value);

    week day = Mon;
    switch(day){
        case Mon: printf("Monday\n"); break;
        case Tue: printf("Tuesday\n"); break;
        default: printf("Invalid day\n");
    }

    printf("\n %d ", LargestNumber(3, 3, 4, 5));

    int iter = 0;
    do {
        printf("Iteration %d\n", iter);
    } while(iter++ < 5);

    // Punctuators
    x++;
    x--;
    x = x&y;
    x = x*y;
    x = x+y;
    x = x-y;
    x = ~y;
    x = !y;
    x = x/y;
    x = x%y;
    x = x<<y;
    x = x>>y;
    x = (x>=y || x==INF) ? x : y;
    x = x^y;
    x = x|y;
    x *= y;
    x /= y;
    x %= y;
    x += y;
    x -= y;
    x <<= y;
    x >>= y;
    x &= y;
    x ^= y;
    x |= y;

    int arr[5] = {1, 2, 3, 4, 5};

    /*
     /* Nested comment attempt
     // this is not a comment inside comment
    */

    @ // Invalid
    
    if(err) {
        goto exit;
    } else {
        printf("No error\n");
    }
    
    exit:
    return 0;
}
