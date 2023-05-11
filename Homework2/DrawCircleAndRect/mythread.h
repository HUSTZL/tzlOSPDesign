#ifndef MYTHREAD_H
#define MYTHREAD_H
#include<QPixmap>
#include<QRunnable>
#include<QMutex>

class myThread:public QObject,public QRunnable
{
    Q_OBJECT
public:
    myThread(QPixmap *pixmap);
    void run();
private:
    QPixmap *pixmap;
//signals:
//    void rep();
};

#endif // MYTHREAD_H

