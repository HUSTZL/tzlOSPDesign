#include "drawcircleandrectinthesametime.h"
#include "ui_drawcircleandrectinthesametime.h"
#include "mythread.h"
#include "mythread2.h"
#include <QThreadPool>
#include <QPainter>
#include <QTimer>
#include <QPixmap>
#define REPAINT_TIME 200

DrawCircleAndRectInTheSameTime::DrawCircleAndRectInTheSameTime(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::DrawCircleAndRectInTheSameTime)
{
    ui->setupUi(this);
    pixmap1=new QPixmap(this->width()/2, this->height());
    pixmap1->fill(Qt::white);

    pixmap2=new QPixmap(this->width()/2, this->height());
    pixmap2->fill(Qt::white);

    myThread *m0=new myThread(pixmap1);
    QThreadPool::globalInstance()->start(m0);

    myThread2 *m1=new myThread2(pixmap2);
    QThreadPool::globalInstance()->start(m1);

    QTimer *qt0=new QTimer();
    qt0->setInterval(REPAINT_TIME);
    qt0->start();
    connect(qt0,SIGNAL(timeout()),this,SLOT(onTimeOut()));
}

DrawCircleAndRectInTheSameTime::~DrawCircleAndRectInTheSameTime()
{
    delete ui;
}

void DrawCircleAndRectInTheSameTime::paintEvent(QPaintEvent *){
    QPainter painter(this);
    painter.drawPixmap(0,0,*pixmap1,0,0,0,0);
    painter.drawPixmap(pixmap1->width(),0,*pixmap2,0,0,0,0);
}
