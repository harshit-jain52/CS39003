int foo(int x){
    return sizeof(x);
}

int main(){
    int a;
    foo(a);
    return 0;
}