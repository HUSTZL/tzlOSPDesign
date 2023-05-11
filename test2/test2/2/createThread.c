#include <stdio.h>
#include <unistd.h>
#include <pthread.h>
#include <stdlib.h>
 
void *A() {
    for(int i = 1; i <= 1000; i++) {
        printf("A : %d\n", i);
        usleep(100000);
    }
    printf("A Thread End\n");
    pthread_exit(NULL);
}

void *B() {
    for(int i = 1000; i >= 1; i--) {
        printf("B : %d\n", i);
        usleep(100000);
    }
    printf("B Thread End\n");
    pthread_exit(NULL);
}
 
int main(){
    pthread_t t1,t2;
    pthread_create(&t1,NULL,A,NULL);
    pthread_create(&t2,NULL,B,NULL);   
    pthread_join(t1, NULL);
    pthread_join(t2, NULL);                                            
    return 0;
}
 
