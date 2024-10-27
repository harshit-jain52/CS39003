// covering conditional statements (also containing boolean expressions)

int main(){
    int x,y,z; 

    if (x > 0) {
        y = 10;
    } else {
        y = 20;
    }

    if (z == 2 || x >= 3 && y <= 4) {
        y = x > 10 ? 10 : 20;
    }

    return 0;
}