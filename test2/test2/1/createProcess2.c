#include<unistd.h>
#include<stdio.h>
int main()
{
	printf("\"#\"代表父进程输出信息；\"@\"代表子进程输出信息。\n");
	pid_t pid=fork();
	if(pid){
		printf("# 1.进程号：%d\n",getpid());
                printf("# 2.其父进程的进程号：%d\n",getppid());
		printf("# 3.父进程结束\n\n");
	}else{
		printf("@ 1.进程号：%d\n",getpid());
		printf("@ 2.暂时挂起子进程10s：\n");
		sleep(10);
		printf("\n@ 3.父进程结束后，子进程的父进程进程号：%d\n",getppid());
		printf("@ 4.暂时挂起子进程10s：\n");
		sleep(10);
		printf("@ 5.子进程结束\n");
	}
	return 0;
}

