#ifndef MYTHREAD2_H
#define MYTHREAD2_H
#include<QPixmap>
#include<QRunnable>
#include <QMutex>
class myThread2:public QObject,public QRunnable
{
    Q_OBJECT
public:
    myThread2(QPixmap *pixmap);
    void run();
private:
    QPixmap *pixmap;
//signals:
//    void rep2();
};

#endif

