#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
int N = 2400, M = 10, pagesize = 10, Algori = 0;FILE *p;//访问数目，页框数目，页面大小
int displayAlgori[4] = {0, 0, 0, 0};
int displayOrder[6] = {0, 0, 0, 0, 0, 0};
int A[1000000], B[100][200], PG[100][3], visorder[1000000], totVistime;// 0 页框号对应的装填的页号, 1 lastvis, 2 inqueuetime
void init();//初始化各种参数，指令数目，页面大小，页框数，访问次序，淘汰算法
int OPT(int nowVistime);int FIFO(int nowVistime);int LRU(int nowVistime);
double sequential(); double jump(); double branch(); double loop(); double rand0m();
int (*Algorithm[4])(int) = {NULL, OPT, FIFO, LRU};
double (*Run[6])() = {NULL, sequential, jump, branch, loop, rand0m};
char* eliminateStr[4] = {"", "OPT","FIFO","LRU"};
char* visitStr[6] = { "", "顺序","跳转","分支", "循环","随机"};
int main () {
    init();
    for(int i = 1; i <= 5; i++) 
        if(displayOrder[i]) {
            printf("[%s访问]:\n", visitStr[i]);
            for(int j = 1; j <= 3; j++) 
                if(displayAlgori[j]) {
                    memset(B, 0, sizeof(B));
                    memset(PG, 0, sizeof(0));
                    memset(visorder, 0, sizeof(visorder));
                    for(int k = 0; k < 100; k++)
                        PG[k][0] = -1;
                    Algori = j;
                    printf("%s算法缺页率 = %lf\n", eliminateStr[j], Run[i]());
                }
        }
    return 0;
}
void init() {
    printf("输入0默认模拟2400个指令，10个页框，页面大小为10。输入1调整指令数目和页框数目和页面大小\n");
    int opt = 0;
    scanf("%d", &opt);
    if(opt == 1) {
        printf("指令数目：");
        scanf("%d", &N);
        printf("页框数目：");
        scanf("%d", &M);
        printf("页面大小");
        scanf("%d", &pagesize);
    }
    printf("\n");
    srand((unsigned)time(NULL));
    for(int i = 0; i < N; i++) 
        A[i] = rand();
    
    printf("输入0展示全部实现的淘汰算法。输入N>0，然后输入N个数(1-3)分别表示想要得到展示的淘汰算法。其中1表示OPT算法，2表示FIFO，3表示LRU算法。\n");
    scanf("%d", &opt);
    if(opt == 0) 
        displayAlgori[1] = displayAlgori[2] = displayAlgori[3] = 1;
    else {
        printf("请输入%d个1-3的数字\n",opt);
        for(int i = 1; i <= opt; i++) {
            int temp = 0;
            scanf("%d", &temp);
            displayAlgori[temp] = 1;
        }
    }
    printf("\n");

    printf("输入0展示全部实现的访问次序。输入N>0，然后输入N个数(1-5)分别表示想要得到展示的淘汰算法。其中1-5分别表示顺序，跳转，分支，循环，或随机\n");
    scanf("%d", &opt);
    if(opt == 0) 
        displayOrder[1] = displayOrder[2] = displayOrder[3] = displayOrder[4] = displayOrder[5] = 1;
    else {
        printf("请输入%d个1-5的数字\n",opt);
        for(int i = 1; i <= opt; i++) {
            int temp = 0;
            scanf("%d", &temp);
            displayOrder[temp] = 1;
        }
    }
    printf("\n");

    printf("具体访问过程可查看output.txt\n\n");
    p = fopen("output.txt", "w");
}
int cmpfunc(const void * a, const void * b) {
   return ( *(int*)a - *(int*)b );
}
int OPT(int nowVistime) {
    int finalvistime[1000];
    for(int i = 0; i < M; i++)
        finalvistime[i] = totVistime;
    for(int i = 0; i < M; i++) {
        int j = totVistime-1;
        for( ; j > nowVistime; j--)
            if(PG[i][0] == visorder[j]) {
                finalvistime[i] = j;
                break;
            }
    }
    int despage = 0;
    for(int i = 0; i < M; i++)
        if(finalvistime[despage] < finalvistime[i])
            despage = i;
    return despage;
}
int FIFO(int nowVistime) {
    int despage = 0;
    for(int i = 0; i < M; i++)
        if(PG[despage][2] > PG[i][2])
            despage = i;
    return despage;
}
int LRU(int nowVistime) {
    int despage = 0;
    for(int i = 0; i < M; i++)
        if(PG[despage][1] > PG[i][1])
            despage = i;
    return despage;
}
int visArray(int id, int lastvis) {
    int page = id / M, bias = id % M, nopage = 1;
    for(int i = 0; i < M; i++) 
        if(PG[i][0] == page) {
            nopage = 0;
            page = i;
            PG[i][1] = lastvis;
            break;
        }
    if(nopage == 1) {
        int hasfreepage = 0;int i = 0;
        for(i = 0; i < M; i++) {
            if(PG[i][0] == -1) {
                hasfreepage = 1;
                break;
            }
        }
        if(hasfreepage == 0) 
            i = Algorithm[Algori](lastvis);
        PG[i][0] = page;
        PG[i][1] = lastvis;
        PG[i][2] = lastvis;
        for(int j = 0; j < M; j++)
            B[i][j] = A[page*M + j];
        page = i;
    }
    fprintf(p, "%d : %d %d\n", id, B[page][bias], nopage);
    return nopage;
}
double sequential() {
    int nowVistime = 0, nopagefault = 0; totVistime = 0;
    fprintf(p, "顺序访问过程\n");
    for(int i = 0; i < N; i++) {
        visorder[totVistime] = i/M;
        totVistime++;
    }
    for(int i = 0; i < N; i++) {
        nopagefault += visArray(i, nowVistime);
        nowVistime++;
    }
    return (double)nopagefault/totVistime;
}
int jumpfirst = 0;int storetemporder[50];
double jump() {
    int nowVistime = 0, nopagefault = 0; totVistime = 0;
    fprintf(p, "跳转访问过程\n");
    if(jumpfirst == 0) {
        for(int i = 0; i < 10; i++) {
            storetemporder[i<<1] = rand() % N;
            storetemporder[i<<1|1] = rand() % (N - storetemporder[i<<1] - 1) + 1;
        }
        jumpfirst = 1;
    }
    for(int i = 0; i < 10; i++) 
        for(int j = storetemporder[i<<1]; j < storetemporder[i<<1] + storetemporder[i<<1|1]; j++)
            visorder[totVistime] = j/M, totVistime++;
    for(int i = 0; i < 10; i++) 
        for(int j = storetemporder[i<<1]; j < storetemporder[i<<1] + storetemporder[i<<1|1]; j++)
            nopagefault += visArray(j, nowVistime), nowVistime++;
    return (double)nopagefault/totVistime;
}
int branchfirst = 0;int cutnum = 0;
double branch() {
    int nowVistime = 0, nopagefault = 0; totVistime = 0;
    fprintf(p, "分支访问过程\n");
    if(branchfirst == 0) {
        for(int i = 0; i < 10; i++) 
            storetemporder[i] = rand() % N;
        qsort(storetemporder,10,sizeof(int),cmpfunc);
        branchfirst = 1;
        for(int i = 0 ; i < 10; i++)
            if(storetemporder[i] != storetemporder[i+1])
                storetemporder[cutnum++] = storetemporder[i];
        cutnum = cutnum/2*2;
    }
    for(int i = 0; i < cutnum; i+= 2) 
        for(int j = storetemporder[i]; j < storetemporder[i+1]; j++)
            visorder[totVistime] = j/M, totVistime++;
    for(int i = 0; i < cutnum; i+= 2) 
        for(int j = storetemporder[i]; j < storetemporder[i+1]; j++)
            nopagefault += visArray(j, nowVistime), nowVistime++;      
    return (double)nopagefault/totVistime;
}
double loop() {
    int nowVistime = 0, nopagefault = 0; totVistime = 0;
    fprintf(p, "循环访问过程\n");
    for(int i = 0; i < N-20; i++) 
        for(int j = 0; j < 9; j++) {
            visorder[totVistime] = (i+j)/M;
            totVistime++;
        }
    for(int i = 0; i < N-20; i++) 
        for(int j = 0; j < 9; j++) {
            nopagefault += visArray(i+j, nowVistime), 
            nowVistime++;
        }
    return (double)nopagefault/totVistime;
}
int rand0morder[100000];
double rand0m() {
    int nowVistime = 0, nopagefault = 0; totVistime = 0;
    fprintf(p, "随机访问过程\n");
    for(int i = 0; i < 800; i++) {
        rand0morder[i] = rand() % N;
        visorder[totVistime] = rand0morder[i] / M;
        totVistime++;
    }
    for(int i = 0; i < 800; i++) {
        nopagefault += visArray(rand0morder[i], nowVistime), 
        nowVistime++;
    }
    return (double)nopagefault/totVistime;
}

