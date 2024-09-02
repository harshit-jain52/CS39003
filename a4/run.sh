make all

for i in {0..4}; do
    ./a.out <testcases/sample$i.txt
done

make clean