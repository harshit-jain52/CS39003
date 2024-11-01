// covering function declarations and function calls

int function_declaration(int x);

int function_add(int a, int b){
    return a+b;
}

int countWays(int denom[], int n, int sum) {
    if(sum == 0) {
        return 1;
    }

    if(sum < 0 || n <= 0) {
        return 0;
    }

    return countWays(denom, n-1, sum) + countWays(denom, n, sum-denom[n-1]);
}

int main(){

    int n = 3;

    int denom[n];
    denom[0] = 1;
    denom[1] = 2;
    denom[2] = 3;

    int sum = 5;

    int ways = countWays(denom, n, sum);

    return 0;
}