#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "QPushButton"
#include "draw.h"
#include <time.h>
#include <QPainter>
#include <drawcircleandrectinthesametime.h>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::on_btn_clicked()
{
    DrawCircleAndRectInTheSameTime *draw = new DrawCircleAndRectInTheSameTime();
    draw->show();
    this->close();
}
