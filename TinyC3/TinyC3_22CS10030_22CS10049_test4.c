// covering loops (while, do-while, for)

int main() {
    int x,y,z; 

    while (x > 0) {
        for(x = 10; x > 0; x--)
            y = 10;
    }

    do {
        y = 20;
    } while (x > 0 || z <= 3);


    for (z = 0; z < 10; z++) {
        y = 30;
        y++;
    }

    return 0;
}