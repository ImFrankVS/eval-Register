#include "evalregister.h"

#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    evalRegister w;
    w.show();
    return a.exec();
}
