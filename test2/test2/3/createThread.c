#include<Windows.h>
#include<stdio.h>

DWORD A() {
	for(int i = 1; i <= 1000; i++) {
		printf("A : %d\n", i);
		Sleep(100);
	}
	return 0;
}

DWORD B () {
	for(int i = 1000; i >= 1; i--) {
		printf("B : %d\n", i);
		Sleep(100);
	}
	return 0;	
}

int main()
{
	HANDLE hThread[2];
	DWORD  threadId1, threadId2;

	hThread[0] = CreateThread(NULL, 0, A, 0, 0, &threadId1);
	hThread[1] = CreateThread(NULL, 0, B, 0, 0, &threadId1);
	WaitForMultipleObjects(2, hThread, 1, INFINITE);
	return 0;
}




