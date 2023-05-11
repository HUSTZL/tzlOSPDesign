#include <unistd.h>
#include <stdio.h>
#include <time.h>
#include <time.h>
int MyArray[10240][20480];
int main () {
    pid_t pid = getpid();
    printf("now process id is %d\n", pid);
    clock_t start,end;
    start = clock();
    for(int i = 0; i < 10240; i++)
        for(int j = 0; j < 20480; j++)
            MyArray[i][j] = 0;
    end = clock();
    printf("time=%f\n",(double)(end-start)/CLOCKS_PER_SEC);
    while(1);
    return 0;
}