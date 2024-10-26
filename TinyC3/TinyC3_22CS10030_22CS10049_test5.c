// covering function declarations and function calls

int foo(int x);

int add(int a, int b){
    return a+b;
}

int fib(int n){
    if(n==0 || n==1){
        return n;
    }
    return fib(n-1) + fib(n-2);
}

int main(){

    int a = 10, b = 20, c = 30;
    int d = add(a, b);
    int e = fib(c);


    return 0;
}