#include "mythread2.h"
#include<QPainter>
#include<QThread>
#define SLEEP_TIME_MS 50

extern QMutex mutex;
myThread2::myThread2(QPixmap *pixmap):
    pixmap(pixmap)
{
}
void myThread2::run(){
    for(int i = 1; i <= 180; i++) {
        mutex.lock();

        QPainter* painter = new QPainter(pixmap);//需要动态分配painter，以保证可以释放，保证不会同时画图。

        QColor blue(0,0,0xFF);//设置颜色
        QPen pen(blue);//定义画笔
        pen.setWidth(5);
        painter->setPen(pen);

        QRectF rect(700, 100, 400, 400);

        painter->drawArc(rect,(i-1)*2*16,2*16);

        delete painter;

        mutex.unlock();

        QThread::msleep(SLEEP_TIME_MS);
        //emit rep();
    }
}

