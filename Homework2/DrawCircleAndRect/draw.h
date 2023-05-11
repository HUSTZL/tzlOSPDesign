#ifndef DRAW_H
#define DRAW_H

#include <QDialog>
#include <QGraphicsRectItem>
#include <cmath>
#include <pthread.h>
#include <sys/time.h>
#include <unistd.h>

namespace Ui {
class draw;
}

class draw : public QDialog
{
    Q_OBJECT

public:
    explicit draw(QWidget *parent = nullptr);
    ~draw();


private:
    Ui::draw *ui;
    void printCircle();
    void printRect();

signals:
    void rep();
};

#endif // DRAW_H
