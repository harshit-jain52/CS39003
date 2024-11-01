// covering basic expressions, arithmetic operators, type conversions

int main() {
    int x,y,z; 

    ++x; 
    x++; 
    y--; 
    --y;
    z = ~x + 10;
    y = !x - 12; 
    x = y >> 3; 
    x = y << 3;


    float a; 

    a = -x + (y*z)/3;

    a = (x|y) & z; 
    
    int* w = &x;

    int p = 3.14;
    int q = 'a';
    float r = 5;
    float s = 'z';
    char t = 84;
 
    return 0;
}