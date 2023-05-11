#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdint.h>
#include <sys/wait.h>
char buf[200];
//计算虚拟地址对应的地址，传入虚拟地址vaddr
void getphysicaladdr(char* str, unsigned long pid, unsigned long vaddr) {
    unsigned long paddr = 0;
    int pageSize = getpagesize();

    unsigned long v_pageIndex = vaddr / pageSize;
    unsigned long v_offset = v_pageIndex * sizeof(uint64_t);
    unsigned long page_offset = vaddr % pageSize;
    uint64_t item = 0;
    sprintf(buf, "%s%lu%s", "/proc/", pid, "/pagemap");
    int fd = open(buf, O_RDONLY);
    lseek(fd, v_offset, SEEK_SET);
    read(fd, &item, sizeof(uint64_t));

    uint64_t phy_pageIndex = (((uint64_t)1 << 55) - 1) & item;
    paddr = (phy_pageIndex * pageSize) + page_offset;//再加上页内偏移量就得到了物理地址
    printf("[%s]pid = %lu, 虚拟地址 = 0x%lx, 所在页号 = %lu, 物理地址 = 0x%lx, 所在物理页框号 = %lu\n", str, pid, vaddr, v_pageIndex, paddr, phy_pageIndex);
    return ;
}

const int a = 52010;//全局常量
int e = 52010;//全局变量
void Hellofuction() {//全局函数
    printf("Hello the world!\n");
    return ;
}

int main()
{
    int b = 0;//局部变量
    static int c = 0;//局部静态变量
    const int d = 0;//局部常量
    int *p = (int*)malloc(0);//动态内存

    int pid = fork();//创建子进程
    if(pid == 0) {
        printf("[进程1]\n");
        //a = 1;
        getphysicaladdr("全局常量", getpid(), (unsigned long)&a);
        getphysicaladdr("全局变量", getpid(), (unsigned long)&e);
        getphysicaladdr("全局函数", getpid(), (unsigned long)Hellofuction);
        getphysicaladdr("局部变量", getpid(), (unsigned long)&b);
        getphysicaladdr("局部静态变量", getpid(), (unsigned long)&c);
        getphysicaladdr("局部常量", getpid(), (unsigned long)&d);
        exit(0);
    }
    else {
        wait(NULL);
        printf("[进程2]\n");
        getphysicaladdr("全局常量", getpid(), (unsigned long)&a);
        getphysicaladdr("全局变量", getpid(), (unsigned long)&e);
        getphysicaladdr("全局函数", getpid(), (unsigned long)Hellofuction);
        getphysicaladdr("局部变量", getpid(), (unsigned long)&b);
        getphysicaladdr("局部静态变量", getpid(), (unsigned long)&c);
        getphysicaladdr("局部常量", getpid(), (unsigned long)&d);
    }
    return 0;
}
