#include <stdio.h>
#include <linux/kernel.h>
#include <sys/syscall.h>
#include <unistd.h>
int main () {
	int nRet1 = syscall(451, 20, 18);
	int nRet2 = syscall(452, 30, 18, 48);
	printf("%d %d\n", nRet1, nRet2);
	return 0;
}
