#pragma once

#include <QMainWindow>

QT_BEGIN_NAMESPACE
    namespace Ui { class evalRegister; }
QT_END_NAMESPACE


class evalRegister : public QMainWindow
{
    Q_OBJECT

public:
    evalRegister(QWidget *parent = nullptr);
    ~evalRegister();

private slots:
    void actionOpenTriggered();
    void actionExitTriggered();
    void ComboBoxCurrentTextChanged(const QString &arg1);
    void ButtonEvaluateClicked();

private:
    Ui::evalRegister *ui;

    void gettingSVGpath();
    void graphsFunction();
};
