#include "evalregister.h"

#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    //a.setStyle("windows"); // Fusion, macintosh, windows
    evalRegister w;
    w.show();
    return a.exec();
}
