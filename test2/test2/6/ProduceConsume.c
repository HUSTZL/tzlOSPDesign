#include <stdio.h>
#include <pthread.h>
#include <unistd.h>
#include <stdlib.h>
#include <semaphore.h>
int arr[11];//共享缓冲区
sem_t data;
sem_t space;
pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
void *produce1() {
    while(1) {
        sem_wait(&space);
        pthread_mutex_lock(&mutex);

        int product = rand() % 1000 + 1000, pos = 0;
        for(int i = 1; i <= 10; i++)
            if(arr[i] == 0) {
                arr[i] = product;
                pos = i;
                break;
            }
        printf("生产者1生产了第%d号产品：%d\n",pos, product);
        
        pthread_mutex_unlock(&mutex);
        sem_post(&data);

        int t = rand() % 901 + 100;
        usleep(t * 1000);
    }
}

void *produce2() {
    while(1) {
        sem_wait(&space);
        pthread_mutex_lock(&mutex);

        int product = rand() % 1000 + 2000, pos = 0;
        for(int i = 1; i <= 10; i++)
            if(arr[i] == 0) {
                arr[i] = product;
                pos = i;
                break;
            }
        printf("生产者2生产了第%d号产品：%d\n",pos, product);
        pthread_mutex_unlock(&mutex);
        sem_post(&data);

        int t = rand() % 901 + 100;
        usleep(t * 1000);
    }
}

void *consume() {
    while(1) {
        sem_wait(&data);
        pthread_mutex_lock(&mutex);

        int product = 0, pos = 0;
        for(int i = 1; i <= 10; i++)
            if(arr[i] != 0) {
                product = arr[i];
                arr[i] = 0;
                pos = i;
                break;
            }
        printf("消费者消费了第%d号产品：%d\n",pos, product);

        pthread_mutex_unlock(&mutex);
        sem_post(&space);

        int t = rand() % 901 + 100;
        usleep(t * 1000);
    }
}
int main () {
    sem_init(&data,0,0);
	sem_init(&space,0,9);
    pthread_t p1, p2;
    pthread_t c1, c2, c3;
    pthread_create(&p1,NULL,produce1,NULL);
    pthread_create(&p2,NULL,produce2,NULL);
    pthread_create(&c1,NULL,consume,NULL);
    pthread_create(&c2,NULL,consume,NULL);
    pthread_create(&c3,NULL,consume,NULL);
    pthread_join(p1,NULL);
	pthread_join(p2,NULL);
	pthread_join(c1,NULL);
	pthread_join(c2,NULL);
	pthread_join(c3,NULL);
    return 0;
}