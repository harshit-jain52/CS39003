/* Test File */

#include <stdio.h>

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

enum week_ { Mon = 1, Tue, Wed, Thur, Fri, Sat, Sun };
typedef enum week_ week;

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
    float f7 = 1234e2;
    double d1 = 12.34;
    char c1 = '$';
    char c2 = '\r';

    _Bool err = 1;  

    node* head = (node*)malloc(sizeof(node));
    head->value = 10;
    head->next = NULL;
    printf("Node head value = &d\n", (*head).value);

    week day = Mon;
    switch(day){
        case Mon: printf("Monday\n"); break;
        case Tue: printf("Tuesday\n"); break;
        case Wed: printf("Wednesday\n"); break;
        case Thur: printf("Thursday\n"); break;
        case Fri: printf("Friday\n"); break;
        case Sat: printf("Saturday\n"); break;
        case Sun: printf("Sunday\n"); break;
        default: printf("Invalid day\n");
    }

    /*
         *
        * *
       * * *
      * * * *
     * * * * *
      PATTERN
    */

    // first loop to print all rows
    for(int i=0; i<5; i++) {
        // inner loop to print white spaces
        for(int j=0; j<2*(5-i) - 1; j++) {
            printf(" ");
        }
        // inner loop to print stars
        for(int j=0; j<2*i + 1; j++) {
            printf("*");
        }
        printf("\n");
    }

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

    if(err) {
        goto exit;
    } else {
        printf("No error\n");
    }
    
    @

    exit:
    return 0;
}
