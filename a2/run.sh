lex list.l
g++ evalexpr.cpp
./a.out <testcases/list.txt
./a.out <testcases/biglist.txt

for i in {1..11}; do
    ./a.out <testcases/err$i.txt
done
