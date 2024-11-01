// covering operations involving arrays and pointers 

int main() {
    int x[5][6][7];
    int y[3][5];
    char z[5];
    int* a[4];
    float **b[2][3];

    x[0][1][2] = 10;

    y[2][4] = 10;

    z[3] = x[1][1][2];

    int* p = &y[2][4];

    int** q = x[1];

    int*** r = &q;
}