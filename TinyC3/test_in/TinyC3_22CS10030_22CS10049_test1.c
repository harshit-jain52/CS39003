// covering basic expressions, arithmetic operators

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

    a = x + y < z;
    a = x + (y < z);
    
    int* w = &x;
 
    return 0;
}