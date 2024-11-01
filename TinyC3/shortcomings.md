## Shortcomings and Bugs

1. Use of boolean expression in arithmetic context:
    eg. int x = y + x||z; gives segmentation fault

2. Similarly, use of parenthesis around logical expression:
    eg. if((x==y) || (y==z)) gives segmentation fault, while 
        if( x==y  ||  y==z ) does not

3. Return to caller has not been handled (as it may be run-time dependent):
    eg. some TACs do not have goto labels defined, they are blank.