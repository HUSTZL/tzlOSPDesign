#include <stdio.h>
#include <pthread.h>
#include <unistd.h>
#include <stdlib.h>
#include <semaphore.h>
#define philosophernum 5
#define chopsticksnum 5
pthread_mutex_t mutex[chopsticksnum];
pthread_t philosopher[philosophernum];
int philosopherId[philosophernum];

void *Philosopher(void *args) {
    int num = *(int*)args;
    while(1) {
        int t = rand() % 401 + 100;
        printf("philosopher%d思考%d ms\n", num, t);
        usleep(t * 1000);

        t = rand() % 401 + 100;
        printf("philosopher%d休息%d ms\n", num, t);
        usleep(t * 1000);

        if(num != 0) {
            pthread_mutex_lock(&mutex[num]);
            printf("philosopher%d获得了左手边的筷子%d\n", num, num);
            //usleep(1000 * 1000);
            pthread_mutex_lock(&mutex[(num+4)%5]);
            printf("philosopher%d获得了右手边的筷子%d\n", num, (num+4)%5);
        }
        else {
            pthread_mutex_lock(&mutex[(num+4)%5]);
            printf("philosopher%d获得了右手边的筷子%d\n", num, num);
            //usleep(1000 * 1000);
            pthread_mutex_lock(&mutex[num]);
            printf("philosopher%d获得了左手边的筷子%d\n", num, (num+4)%5);
        }

        t = rand() % 401 + 100;
        printf("philosopher%d获得了两只筷子%d和%d，吃饭%d ms\n", num, num, (num+4)%5, t);
        usleep(t * 1000);

        pthread_mutex_unlock(&mutex[(num+4)%5]);
        printf("philosopher%d放下了右手边的筷子%d\n", num, (num+4)%5);

        pthread_mutex_unlock(&mutex[num]);
        printf("philosopher%d放下了左手边的筷子%d\n", num, num);
    }
}
int main () {
    for(int i = 0; i < philosophernum; i++) {
        philosopherId[i] = i;
        pthread_create(&philosopher[i], NULL, Philosopher, &philosopherId[i]);   
    }
    for(int i = 0; i < philosophernum; i++) 
        pthread_join(philosopher[i], NULL);
    return 0;
}