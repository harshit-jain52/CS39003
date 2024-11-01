// covering conditional statements (also containing boolean expressions)

int main(){
    int x,y,z; 
    
    x=4; y=3; z=2;

    if (x > 0) {
        y = 10;
    } 
    else {
        y = 20;
    }

    if (z == 2 || x >= 3 && y <= 4) {
        float y;
        y = 3.14;
        if(y == 10 || y == 20) {
            z = 0;
        } else {
            z = 1;
        }
    }

    int a,b,c;
    a=0; b=1;

    if (a){
        c = 10;
    }
    else if(b){
        c = 20;
    }
    else{
        c = 30;
    }
    
    return 0;
}