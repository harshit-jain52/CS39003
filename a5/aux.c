void mprn(int mem[], int idx){
    printf("+++ MEM[%d] set to %d\n",idx,mem[idx]);
}

void eprn(int reg[], int idx){
    printf("+++ Standalone expression evaluates to %d\n",reg[idx]);
}

int pwr(int a, int b){
    int ans = 1;
    while(b){
        if(b&1) ans*=a;
        a*=a;
        b>>=1;
    }
    return ans;
}