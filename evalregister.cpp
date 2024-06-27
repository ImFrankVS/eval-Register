#include "evalregister.h"
#include "./ui_evalregister.h"

// Project Libraries
#include <QDir>
#include <QDebug>
#include <QFileDialog>
#include <QStandardPaths>
#include <QProgressBar>
#include <julia.h>

// Libraries for gettingSVGPaths function
#include <QFileInfoList>
#include <QStringList>
#include <QMessageBox>

JULIA_DEFINE_FAST_TLS  // Julia goes brrrrr....

// Constructor
evalRegister::evalRegister(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::evalRegister)
{ // The Constructor starts here...
    ui->setupUi(this);
    ui->progressBarStep0->hide(); // Hiding QProgressBar....

    // Message for Julia Libraries...
    //QMessageBox::warning(nullptr, "Julia libraries", "Se viene el show de cmds chavales.");

    // Initializing Julia
    jl_init();
    jl_eval_string("println(\"Julia initialized...\")");
    jl_eval_string("include(\"methods/DEPS_01.jl\")");

    // Color Schemes
    QStringList colorSchemes = { "blues", "bluesreds", "greens", "heat", "redsblues", "algae", "amp", "balance", "matter", "bam", "berlic", "broc", "roma", "tofino", "Spectral" };
    ui->colorComboBox->addItems(colorSchemes);

    // Type of Graph
    QStringList typeOfGraphs = { "std ΔV", "std ΔV conv", "# V values", "# V values conv" };
    ui->typeOfGraphComboBox->addItems(typeOfGraphs);

    // Definning Slots...
    connect(ui->actionOpen, &QAction::triggered, this, &evalRegister::actionOpenTriggered);
    connect(ui->actionExit, &QAction::triggered, this, &evalRegister::actionExitTriggered);
    connect(ui->myComboBox, &QComboBox::currentTextChanged, this, &evalRegister::ComboBoxCurrentTextChanged);
    connect(ui->buttonEvaluate, &QPushButton::clicked, this, &evalRegister::ButtonEvaluateClicked);
}



// Destructor
evalRegister::~evalRegister()
{
    jl_eval_string("println(\"Julia shutting down...\")");
    jl_atexit_hook(0);
    delete ui;
}



void evalRegister::actionExitTriggered() { close(); }



void evalRegister::actionOpenTriggered()
{
    // File Dialog
    QString documentsPath = "";
    //if(ui->textFileSelected->text().isEmpty()) { documentsPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation); }
    QString fileName = QFileDialog::getOpenFileName(this, "Select .brw file", documentsPath, "BRW files (*.brw);;BXR files (*.bxr);;All Files (*)");

    QFileInfo fileInfo(fileName);

    // File was not selected...
    if (fileName.isEmpty()) {
        return;
    }

    while (fileInfo.suffix().compare("brw", Qt::CaseInsensitive)) {
        QMessageBox::warning(nullptr, "Incorrect extension", "This file does not have the .brw extension.");

        fileName = QFileDialog::getOpenFileName(this, "Select .brw file", "", "BRW files (*.brw);;BXR files (*.bxr);;All Files (*)");
        fileInfo.setFile(fileName);

        if (fileName.isEmpty()) {
            return;
        }
    }

    // Setting the file path as the window title...
    setWindowTitle(fileName);

    // Changing the value of "textFileSelected"
    ui->textFileSelected->clear();
    ui->textFileSelected->insert(fileInfo.fileName());
}



void evalRegister::ButtonEvaluateClicked()
{
    // Checking for a file seleted
    if(ui->textFileSelected->text().isEmpty()) {
        QMessageBox::warning(nullptr, "File not selected", "Please select a file to evaluate");

        return;
    }

    // Loading process
    QMessageBox::StandardButton reply;
    reply = QMessageBox::question(nullptr, "Confirm",
                                  "Do you want to start the process?",
                                  QMessageBox::Yes | QMessageBox::No);
    if (reply == QMessageBox::No) { return; }

    //ui->progressBarStep0->show(); //Showing the QProgressBar

    // Returnig to the main path
    QString currentPath = QDir::currentPath();
    QString appDirPath = QCoreApplication::applicationDirPath();

    if(currentPath != appDirPath) {
        QString appPath = "cd(\"" + appDirPath + "\")";
        QByteArray appPathUTF = appPath.toUtf8();
        const char *appPathConst = appPathUTF.constData();
        jl_eval_string(appPathConst);
    }

    // Sending .brw path to Julia
    QString fileName = windowTitle();
    QString FILEBRW = "FILEBRW = \"" + fileName + "\"";
    QByteArray FILEBRWutf = FILEBRW.toUtf8();
    const char *FILEBRWconst = FILEBRWutf.constData();
    jl_eval_string(FILEBRWconst);

    // Sending limUpperChunk value to Julia
    qDebug() << "LimUpperChunk C++: " << ui->limUpperSpinBox->value();
    QString limUpperChunk = "limUpperChunk = " + QString::number(ui->limUpperSpinBox->value());
    QByteArray limUpperChunkutf = limUpperChunk.toUtf8();
    const char *limUpperChunkconst = limUpperChunkutf.constData();
    jl_eval_string(limUpperChunkconst);

    // Setting Graph Configuration
    QString QtitleGraph = "QtitleGraph = \"" + ui->typeOfGraphComboBox->currentText() + "\";";
    QByteArray QtitleGraphutf = QtitleGraph.toUtf8();
    const char *QtitleGraphconst = QtitleGraphutf.constData();
    jl_eval_string(QtitleGraphconst); // Title

    QString Qcolor = "Qcolor = :" + ui->colorComboBox->currentText() + ";";
    QByteArray Qcolorutf = Qcolor.toUtf8();
    const char *Qcolorconst = Qcolorutf.constData();
    jl_eval_string(Qcolorconst); // ColorScheme

    if (ui->cbarCheckBox->checkState() == 2 ) {
        QString Qcbar = "Qcbar = true;";
        QByteArray Qcbarutf = Qcbar.toUtf8();
        const char *Qcbarconst = Qcbarutf.constData();
        jl_eval_string(Qcbarconst); // cbar = true
    } else {
        QString Qcbar = "Qcbar = false;";
        QByteArray Qcbarutf = Qcbar.toUtf8();
        const char *Qcbarconst = Qcbarutf.constData();
        jl_eval_string(Qcbarconst); // cbar = false
    }

    // Julia Callings
    jl_eval_string("cd(\"methods/\")");

    // Step 1 - Only the graphs
    jl_eval_string("include(\"CODE_STEP_01.jl\")"); // This is working, but... I need C++ control!

    // Assign the return value of Julia to a C object of Julia type
    jl_value_t *N = jl_eval_string("string(ChunkSizeSpace( Variables, limUpperChunk ))");
    const char *N_str = jl_string_ptr(N);
    QString N_qstr = QString::fromUtf8(N_str);
    int sigma = N_qstr.toInt();
    qDebug() << "Numero de segmentos: " << sigma;

    jl_value_t *BINSIZE = jl_eval_string("string(fs)");
    const char *BINSIZE_str = jl_string_ptr(BINSIZE);
    QString BINSIZE_qstr = QString::fromUtf8(BINSIZE_str);
    float binsize = BINSIZE_qstr.toFloat();
    qDebug() << "BINSIZE: " << binsize;
    QString continueProcess = "Do you want to continue the process?\n\nBINSIZE: " + QString::number(binsize) + " GB\nSegments: " + QString::number(sigma);

    // Sharing N and BINSIZE
    QMessageBox::StandardButton accepted;
    accepted = QMessageBox::question(nullptr, "Confirm",
                                  continueProcess,
                                  QMessageBox::Yes | QMessageBox::No);
    if (accepted == QMessageBox::No) { return; }


    //int percentage100; // AuxVar to QProgressBar....
    // Foor loop...
    for(int n = 1; n <= sigma; n++) {
        QString Qn = "n = " + QString::number(n) + ";";
        QByteArray Qnutf = Qn.toUtf8();
        const char *Qnconst = Qnutf.constData();
        jl_eval_string(Qnconst);

        jl_eval_string("BINRAW = OneSegment( Variables, n, N );");
        jl_eval_string("BINRAW = Digital2Analogue( Variables, BINRAW );");
        jl_eval_string("BINNAME = joinpath( PATHVOLTAGE, string( \"BIN\", lpad( n, n0s, \"0\" ), \".jld2\" ) );");
        jl_eval_string("NΔV = stdΔV( Variables, BINRAW, ΔT );");
        jl_eval_string("RowCount = UniqueCount( BINRAW );");
        jl_eval_string("h = copy( RowCount ); hg = convgauss( sigma, h );");
        jl_eval_string("data = vec( RemoveInfs( abs.( log.( hg ) ) ) );");
        jl_eval_string("P = Zplot( data, \"W\", Qcolor ); title!( QtitleGraph );");
        jl_eval_string("PF = plot( P, wsize = ( 800, 800 ), cbar = Qcbar, legendtitle = QtitleGraphSecs, legendposition = :bottom );");
        jl_eval_string("FIGNAME = joinpath( PATHFIGURES, string( \"BIN\", lpad( n, n0s, \"0\" ), \".svg\" ));");
        jl_eval_string("FIGNAME = joinpath( PATHFIGURES, FIGNAME );");
        jl_eval_string("savefig( PF, FIGNAME );");

        jl_eval_string("println(\"$n listo de $N\");");

        //QString segmento = QString::number(n) + " listo de " + QString::number(sigma);
        //QMessageBox::about(nullptr, "Segment Status", segmento);

        //float percentage = n/sigma * 100;
        //percentage100 = static_cast<int>(round(percentage));
        //ui->progressBarStep0->setValue(round(percentage100));
    }

    //jl_eval_string("step00 = Dict( \"NVoltValues\" => NVoltValuesRAW, \"stdΔt\" => stdΔt, \"Empties\" => Empties );");
    //jl_eval_string("jldsave( joinpath( PATHINFO, \"STEP00.jld2\" ); step00 );");

    // Run a needed filebrw path functions....
    gettingSVGpath();

    // Step-01-Finished Message...
    QMessageBox::about(nullptr, "Finished process", "The process has finished...");
}



void evalRegister::ComboBoxCurrentTextChanged(const QString &arg1)
{
    QString currentPath = QDir::currentPath();

    QString directoryPath = currentPath;
    QString fileNameStr = QFileInfo(directoryPath).fileName();
    QString parentDirPath = QFileInfo(directoryPath).absolutePath() + "/" + fileNameStr + "/Figures";

    QString fileSVG = parentDirPath + "/" + arg1 + ".svg";

    QPixmap pic(fileSVG);
    ui->imgLabel->setPixmap(pic);
}



void evalRegister::gettingSVGpath()
{
    QString directoryPath = windowTitle();
    qDebug() << "BRW File Path: " << directoryPath;
    QFileInfo fileInfo(directoryPath);

    QDir parentDir = fileInfo.absoluteDir().absolutePath() + "/..";
    QString figuresPath = parentDir.absolutePath() + "/" + fileInfo.baseName() + "/Figures";

    qDebug() << "Figures Path: " << figuresPath ;
    qDebug() << "Parent Dir: " << parentDir;

    QDir figuresDir(figuresPath);
    if (!figuresDir.exists()) {
        QMessageBox::warning(nullptr, "Folder not found", "The 'Figures' folder was not found in the specified directory.");
        return;
    }

    QStringList nameFilters;
    nameFilters << "*.svg";

    QFileInfoList svgFilesInfo = figuresDir.entryInfoList(nameFilters, QDir::Files, QDir::Name);

    QStringList svgFiles;
    for (const QFileInfo &fileInfo : svgFilesInfo) {
        QString fileNameWithoutExtension = fileInfo.completeBaseName();
        svgFiles.append(fileNameWithoutExtension);
    }

    qDebug() << "SVG Files: " << svgFiles;

    ui->myComboBox->clear();
    ui->myComboBox->addItems(svgFiles);
    ui->myComboBox->setCurrentIndex(0);
}




