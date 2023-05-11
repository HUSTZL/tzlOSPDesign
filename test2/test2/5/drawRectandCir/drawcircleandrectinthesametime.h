#ifndef DRAWCIRCLEANDRECTINTHESAMETIME_H
#define DRAWCIRCLEANDRECTINTHESAMETIME_H

#include <QDialog>

namespace Ui {
class DrawCircleAndRectInTheSameTime;
}

class DrawCircleAndRectInTheSameTime : public QDialog
{
    Q_OBJECT

public:
    explicit DrawCircleAndRectInTheSameTime(QWidget *parent = nullptr);
    ~DrawCircleAndRectInTheSameTime();
    void paintEvent(QPaintEvent *);

private:
    Ui::DrawCircleAndRectInTheSameTime *ui;
    QPixmap *pixmap1, *pixmap2;

protected slots:
    void onTimeOut(){
        repaint();
    }
};

#endif // DRAWCIRCLEANDRECTINTHESAMETIME_H
