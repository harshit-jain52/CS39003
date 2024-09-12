make all

for i in {0..6}; do
    ./a.out <testcases/sample$i.txt
done

make clean