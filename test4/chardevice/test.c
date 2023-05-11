#include <stdio.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
char buffer[64];
#define DEV_NAME "/dev/test"
int main() {
    int fd = open(DEV_NAME, O_RDWR);
    if (fd < 0) {
		printf("open %s failded\n", DEV_NAME);
		return -1;
	}
    sprintf(buffer,"%d %d", 520, 10);
    write(fd, buffer, strlen(buffer));
    sprintf(buffer,"It is fate?");
    write(fd, buffer, strlen(buffer));
    read(fd, buffer, 64);
    printf("1:%s\n", buffer);
    sprintf(buffer,"%d %d %d", 1206, 0314, 0521);
    write(fd, buffer, strlen(buffer));
    sprintf(buffer,"I can not believe?");
    write(fd, buffer, strlen(buffer));
    read(fd, buffer, 64);
    printf("2:%s\n", buffer);
	close(fd);
	return 0;
}
