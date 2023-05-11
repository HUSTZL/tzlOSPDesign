#include "draw.h"
#include "ui_draw.h"

draw::draw(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::draw)
{
    ui->setupUi(this);
    printCircle();
    printRect();
}

void draw::printCircle() {
    QGraphicsScene *scene = new QGraphicsScene;
    for(int i = 1; i <= 360; i++) {
        QGraphicsPathItem *thePath = new QGraphicsPathItem;
        QPainterPath *painterPath = new QPainterPath;
        QRectF newRect(-200, -200, 400, 400);
        painterPath->arcMoveTo(newRect, i-1);
        painterPath->arcTo(newRect, i-1, 1);
        thePath->setPath(*painterPath);

        QPen pen = thePath->pen();
        pen.setWidth(5);
        pen.setColor(Qt::blue);
        thePath->setPen(pen);
        scene->addItem(thePath);
        ui->graphicsView->setScene(scene);
        ui->graphicsView->show();
        emit rep();
        usleep(100);
    }
}

void draw::printRect() {
    QGraphicsScene *scene = new QGraphicsScene;
    QGraphicsRectItem* rect0 = new QGraphicsRectItem(50, 50, 400, 400, 0);
    QPen pen = rect0->pen();
    pen.setWidth(5);
    pen.setColor(Qt::red);
    rect0->setPen(pen);
    scene->addItem(rect0);
    ui->graphicsView_2->setScene(scene);
    ui->graphicsView_2->show();
}

draw::~draw()
{
    delete ui;
}
