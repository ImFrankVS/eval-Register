#include "evalregister.h"
#include <QtWidgets/QApplication>
#include <QStringList>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    // Chechk for 'fusion' argument...
    QStringList arguments = QCoreApplication::arguments();
    if (arguments.contains("fusion", Qt::CaseInsensitive)) {
        // Alternate Design
        app.setStyle("Fusion");

        QPalette palette;
        palette.setColor(QPalette::Window, QColor(53, 53, 53));
        palette.setColor(QPalette::WindowText, Qt::white);
        palette.setColor(QPalette::Base, QColor(42, 42, 42));
        palette.setColor(QPalette::AlternateBase, QColor(66, 66, 66));
        palette.setColor(QPalette::ToolTipBase, Qt::white);
        palette.setColor(QPalette::ToolTipText, Qt::white);
        palette.setColor(QPalette::Text, Qt::white);
        palette.setColor(QPalette::Button, QColor(53, 53, 53));
        palette.setColor(QPalette::ButtonText, Qt::white);
        palette.setColor(QPalette::BrightText, Qt::red);

        // Define specific colors for the disabled state
        palette.setColor(QPalette::Disabled, QPalette::Button, QColor(80, 80, 80));
        palette.setColor(QPalette::Disabled, QPalette::ButtonText, QColor(128, 128, 128));
        palette.setColor(QPalette::Disabled, QPalette::WindowText, QColor(128, 128, 128));
        palette.setColor(QPalette::Disabled, QPalette::Text, QColor(128, 128, 128));

        app.setPalette(palette);
    }

    evalRegister window;
    window.show();

    return app.exec();
}

















































// Loading StyeSheet....
// QFile styleSheetFile("./styles/ConsoleStyle.qss");
// if (styleSheetFile.open(QFile::ReadOnly)) {
//     QString styleSheet = QLatin1String(styleSheetFile.readAll());
//     app.setStyleSheet(styleSheet);
// } else {
//     qWarning() << "Error: No StyleSheet loaded";
// }

//app.setStyle("Fusion");
