#pragma once

#include <QMainWindow>
#include "FigureViewer.h"

QT_BEGIN_NAMESPACE
    namespace Ui { class evalRegister; }
QT_END_NAMESPACE

class evalRegister : public QMainWindow
{
    Q_OBJECT

public:
    evalRegister(QWidget *parent = nullptr);
    ~evalRegister();

    // Public Funcions
    void setSpectro(const QString &filename);

private slots:
    void actionOpenTriggered();
    void actionLoadTriggered();
    void actionExitTriggered();
    void ComboBoxCurrentTextChanged(const QString &arg1);
    void typeOfGraphComboBoxTextChanged(const QString &arg1);
    void colorComboBoxTextChanged(const QString &arg1);
    void ButtonEvaluateClicked();
    void ButtonBinBehavior();
    void ButtonStep01Clicked();
    void ButtonOpenExplorer();
    void SpinBoxN1ValueChanged(int arg1);
    void SpinBoxNoverLapValueChanged(int arg1);

private:
    Ui::evalRegister *ui;
    FigureViewer *figureViewer; // Obj. to call our signal or slots?!?!?
    FigureViewer *figureViewer_STD; // Yes, it is to call our signal and slots :)

    // Auxiliar Functions
    void figuresPath(const QString &figures);
    void STEP00();
    void STEP01();
    QString searchInfoBRW();
    QString loadPathFromFile(const QString &key);
    void savePathToFile(const QString &key, const QString &path);
    void saveToIni();
    void loadFromIni();

    // Functions to jl_eval_string()
    void evalJulia(const QString& key, const QString& value);
    void evalJuliaString(const QString &key, const QString &value);
    void evalJuliaInt(const QString &key, int value);
    void evalJuliaFloat(const QString &key, float value);
    QString juliaStringValue(const QString& juliaVar);
    int juliaIntValue(const QString& juliaVar);
    float juliaFloatValue(const QString& juliaVar);

    // Julia auxiliar functions
    void codeStep00_saving();
    void codeStep01_saving();

    // Auxiliar Variables
    double initialSpinValue;

    // Auxiliar Const
    const int scaleFactor = 100;

    // Julia Path
    QString FILEBRW = nullptr;
    QString mainPath = nullptr;
    QString infoPath = nullptr; // Actually these have to be a Q_PROPERTY, but...
};



