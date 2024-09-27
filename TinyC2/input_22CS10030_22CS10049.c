/* Test File */

// External Declarations
extern int globe;
static double PI = 3.14159;
volatile long INF = 1e9;

// Function prototype
_Bool bool_foo(char *val);

// Function definition
inline void newline(){
    auto char* str = "Customized newline function";
    printf("%s\n", str);
}

int KandRstyle(p, q)
int p, q;
{
    return p^q;
}

int main(int argc, char const *argv[])
{   
    // Declaration statements
    long int x = 10, iter = 0;
    float f = 12.34e-5 + 90;
    char c = '$';
    char str[] = "Hello, Tiny World!";
    int arr[5] = {2, 3, 5, 7, 11};
    register int fast_var = 50;

    // Assignment Expression
    x += 5;
    fast_var *= 2;

    // Logical Expression
    _Bool flag = (x > 5 && fast_var < 100) || (x != INF);

    // Iteration Statements
    do {
        printf("Iteration %ld\n", iter);
    } while(iter++ < 5);

    while(iter>0) iter--;

    for(int i=0; ;i++){
        if(i==1) continue;
        if(i==10) break;
    }

    // Cast Expression
    double a = (double)x/2;

    // Unary Expression
    double* ptr = &a;
    double val = *ptr;

    // Multiplicative and Additive Expression
    int res2 = val*2 + val/2 - x%5;

    // Shift Expression
    x = (x<<3)>>2;
    
    // Function Call
    _Bool err = bool_foo(str);

    // Selection Statements
    switch(x) {
        case 5:
            printf("x is 5\n");
            break;
        case 15:
            printf("x is 15\n");
            break;
        default:
            printf("x is something else\n");
            break;
    }

    // Jump Statement
    if(err) {
        goto exit;
    } else {
        printf("No error\n");
    }
    
    // Labelled Statement
    exit:
        return 0;
}

/*
End
Of
File
*/