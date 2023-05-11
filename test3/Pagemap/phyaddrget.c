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
void getphysicaladdr(unsigned long pid, unsigned long vaddr) {
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
    printf("pid = %lu, 虚拟地址 = 0x%lx, 所在页号 = %lu, 物理地址 = 0x%lx, 所在物理页框号 = %lu\n", pid, vaddr, v_pageIndex, paddr, phy_pageIndex);
    return ;
}
int main(int argc , char* argv[]) {
    getphysicaladdr(atoi(argv[1]), (unsigned long)strtol(argv[2],NULL,16));
    return 0;
}
