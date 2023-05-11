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
    pixmap=new QPixmap(this->size());
    pixmap->fill(Qt::white);
    myThread *m0=new myThread(pixmap);
    QThreadPool::globalInstance()->start(m0);

    myThread2 *m1=new myThread2(pixmap);
    QThreadPool::globalInstance()->start(m1);

    //connect(m0,SIGNAL(rep()),this,SLOT(repaint()));
    //connect(m1,SIGNAL(rep2()),this,SLOT(repaint()));

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
    painter.drawPixmap(0,0,*pixmap,0,0,0,0);
}
