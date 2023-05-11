#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdint.h>
#include <sys/wait.h>
int main()
{
    int pid = fork();//创建子进程
    if(pid == 0) {
        printf("[进程1]运行 pid = %d\n", getpid());
    }
    else {
        printf("[进程2]运行 pid = %d\n", getpid());
    }
    while(1);
    return 0;
}
