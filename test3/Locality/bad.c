#include <unistd.h>
#include <stdio.h>
#include <time.h>
#include <time.h>
int MyArray[2048][2048];
int main () {
    pid_t pid = getpid();
    printf("now process id is %d\n", pid);
    clock_t start,end;
    start = clock();
    for(int i = 0; i < 2048; i++)
        for(int j = 0; j < 2048; j++)
            MyArray[j][i] = 0;
    end = clock();
    printf("time=%f\n",(double)(end-start)/CLOCKS_PER_SEC);
    while(1);
    return 0;
}