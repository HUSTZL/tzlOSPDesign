#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdlib.h>
#include <signal.h>
#include <unistd.h>
#include <sys/ipc.h>

void handler(int sig) {
    printf("Bye,Wolrd!\n");
    exit(0);
    return ;
}

int main () {
    pid_t pid = fork();
    if(pid) {
        char c;
        while(1) {
            printf("To terminate Child Process. Yes or No? \n");
            scanf("%c", &c);
            if(c == 'Y') {
                kill(pid, SIGUSR1);
                //printf("SIGKILL!\n");
                break;
            }
            sleep(2);
        }
        sleep(4);
    }
    else {
        signal(SIGUSR1, handler);
        while(1) {
            printf("I am Child Process, alive!\n");
            sleep(2);
        }
    }
    return 0;
}