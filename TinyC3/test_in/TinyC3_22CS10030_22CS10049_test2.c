// covering operations involving arrays and pointers 

int main() {
    int x[10][20][30];
    int y[10][5];
    char z[5];
    int* a[2];
    float **b[3][4];

    x[1][2][3] = 10;

    y[1][2] = 10;

    z[3] = x[1][5][7];

    int* p = &y[3][4];

    int** q = x[1];

    int*** r = &q;

    return 0;
}