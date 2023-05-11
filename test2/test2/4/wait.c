#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/wait.h>
//WIFEXITED(status) 这个宏用来指出子进程是否为正常退出的，如果是，它会返回一个非零值。

//WEXITSTATUS(status) 当WIFEXITED返回非零值时，我们可以用这个宏来提取子进程的返回值，
//如果子进程调用exit(5)退出，WEXITSTATUS(status)就会返回5；
//如果子进程调用exit(7)，WEXITSTATUS(status)就会返回7。
//请注意，如果进程不是正常退出的，也就是说，WIFEXITED返回0，这个值就毫无意义。
int main () {
    printf("\"#\"代表父进程输出信息；\"@\"代表子进程输出信息。\n");
    pid_t pid = fork();
    if(pid) {
        printf("# 1.父进程等待子进程结束\n");
        int status = 0;
        wait(&status);
        printf("# 2.子进程返回数值为 %d\n", WEXITSTATUS(status));
    }
    else {
        printf("@ 1.子进程休眠5s\n");
        sleep(5);
        exit(3);
    }
    return 0;
}