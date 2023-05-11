#include "mythread.h"
#include<QPainter>
#include<QThread>
#define SLEEP_TIME_MS 50

QMutex mutex;
myThread::myThread(QPixmap *pixmap):
    pixmap(pixmap)
{
}
void myThread::run(){
    for(int i = 1; i <= 200; i++) {
        mutex.lock();

        QPainter* painter = new QPainter(pixmap);//需要动态分配painter，以保证可以释放，保证不会同时画图。

        QColor red(0xFF,0,0);//设置颜色
        QPen pen(red);//定义画笔
        pen.setWidth(5);//
        painter->setPen(pen);

        if(1 <= i && i <= 50)
            painter->drawLine(100+8*(i-1),100,100+8*i,100);
        else if(51 <= i && i <= 100)
            painter->drawLine(500,100+8*(i-51),500,100+8*(i-50));
        else if(101 <= i && i <= 150)
            painter->drawLine(500-8*(i-101),500,500-8*(i-100),500);
        else
            painter->drawLine(100,500-8*(i-151),100,500-8*(i-150));
        delete painter;

        mutex.unlock();

        QThread::msleep(SLEEP_TIME_MS);
        //emit rep();
    }
}

