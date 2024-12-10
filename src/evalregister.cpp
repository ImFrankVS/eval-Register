#include "evalregister.h"
#include "ui_evalregister.h"

// Project Libraries
#include <QFileDialog>
#include <QProgressDialog>
#include <QDesktopServices>
#include <QStandardPaths>
#include <QMessageBox>
#include <QSettings>
#include <QSpinBox>
#include <QSlider>
#include <QTimer>
#include <QString>
#include <QDebug>
#include <QDir>
#include <QUrl>
#include <julia.h>

JULIA_DEFINE_FAST_TLS  // Julia goes brrrrr....

// Constructor
evalRegister::evalRegister(QWidget *parent)
    : QMainWindow(parent), ui(new Ui::evalRegister)
{ // The Constructor starts here...
    ui->setupUi(this);

    figureViewer = new FigureViewer(ui->figureViewerWidget);
    figureViewer_STD = new FigureViewer(ui->figureViewer2);

    // Julia libraries
    system("julia -e \"include(\\\"./methods/DEPS_01.jl\\\");\""); // & pause");

    // Initializing Julia
    jl_init();
    jl_eval_string("println(\"Julia initialized...\");");

    // Color Schemes
    QStringList colorSchemes = { "vik", "blues", "bluesreds", "grays", "greens", "heat", "reds", "redsblues", "algae", "amp", "matter", "inferno" };
    ui->labelCbar->setPixmap(QPixmap(QString(QCoreApplication::applicationDirPath() + "/resources/cbar/vik.png")).scaled(ui->imgLabel->size(), Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation));
    ui->colorComboBox->addItems(colorSchemes);

    // Type of Graph
    QStringList typeOfGraphs = { "STEP00", "STEP01" }; // , "ACD", "STEP02" };
    ui->typeOfGraphComboBox->addItems(typeOfGraphs);

    // Definning Slots...
    connect(ui->actionOpen, &QAction::triggered, this, &evalRegister::actionOpenTriggered); // Open
    connect(ui->actionLoad, &QAction::triggered, this, &evalRegister::actionLoadTriggered); // Load
    connect(ui->actionExit, &QAction::triggered, this, &evalRegister::actionExitTriggered); // Exit
    connect(ui->myComboBox, &QComboBox::currentTextChanged, this, &evalRegister::ComboBoxCurrentTextChanged);
    connect(ui->typeOfGraphComboBox, &QComboBox::currentTextChanged, this, &evalRegister::typeOfGraphComboBoxTextChanged);
    connect(ui->colorComboBox, &QComboBox::currentTextChanged, this, &evalRegister::colorComboBoxTextChanged);
    connect(ui->buttonEvaluate, &QPushButton::clicked, this, &evalRegister::ButtonEvaluateClicked);
    connect(ui->buttonBinBehaviour, &QPushButton::clicked, this, &evalRegister::ButtonBinBehavior);
    connect(ui->buttonStep01, &QPushButton::clicked, this, &evalRegister::ButtonStep01Clicked);
    connect(ui->buttonExplorer, &QPushButton::clicked, this, &evalRegister::ButtonOpenExplorer);
    connect(ui->spinBoxN1, qOverload<int>(&QSpinBox::valueChanged), this, &evalRegister::SpinBoxN1ValueChanged);
    connect(ui->spinBoxN_overlap, qOverload<int>(&QSpinBox::valueChanged), this, &evalRegister::SpinBoxNoverLapValueChanged);

    ui->maxGBSlider->setRange(ui->maxGBSpinBox->minimum() * scaleFactor, ui->maxGBSpinBox->maximum() * scaleFactor);

    // Anonymous Signals and Slots
    connect(ui->maxGBSlider, &QSlider::valueChanged, [=](int value) {
        ui->maxGBSpinBox->setValue(static_cast<double>(value) / scaleFactor);
    });

    connect(ui->maxGBSpinBox, qOverload<double>(&QDoubleSpinBox::valueChanged), [=](double value) {
        ui->maxGBSlider->setValue(static_cast<int>(value * scaleFactor));
    });

    // Foreign Slots...
    connect(figureViewer, &FigureViewer::filenameChanged, this, &evalRegister::setSpectro); // I love this <3
    connect(figureViewer_STD, &FigureViewer::filenameChanged, this, &evalRegister::setSpectro);

    // Freign Anonymous Signals and Slots
    connect(figureViewer, &FigureViewer::currentChannelChanged, [=](int value) {
        ui->labelChannelCAR->setText("Channel: " + QString::number(value));
    });

    connect(figureViewer_STD, &FigureViewer::currentChannelChanged, [=](int value) {
        ui->labelChannelVSD->setText("Channel: " + QString::number(value));
    });

    // Hiding some widgets
    ui->labeln1->hide();
    ui->spinBoxN1->hide();
    ui->labeln_overlap->hide();
    ui->spinBoxN_overlap->hide();
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
    // Ensure that brwPath.txt is saved in
    if (QDir::currentPath() != QCoreApplication::applicationDirPath()) {
        QDir::setCurrent(QCoreApplication::applicationDirPath());
    }

    // Reading brwPath.txt to load the last path
    QString lastPath = loadPathFromFile("lastOpenBRW");

    // File Dialog: Open the last folder selected
    QString fileName = QFileDialog::getOpenFileName(this, "Select .brw file", lastPath, "BRW files (*.brw);;BXR files (*.bxr);;All Files (*)");
    QFileInfo fileInfo(fileName);

    // File was not selected...
    if (fileName.isEmpty()) {
        return;
    }

    // File extension validation
    while (fileInfo.suffix().compare("brw", Qt::CaseInsensitive)) {
        QMessageBox::warning(this, "Incorrect extension", "This file does not have the .brw extension.");

        fileName = QFileDialog::getOpenFileName(this, "Select .brw file", "", "BRW files (*.brw);;BXR files (*.bxr);;All Files (*)");
        fileInfo.setFile(fileName);

        if (fileName.isEmpty()) {
            return;
        }
    }

    // Writing the last path in the file brwPath.txt
    savePathToFile("lastOpenBRW", fileInfo.absolutePath());

    // Cleaning for a new file opened
    if (!FILEBRW.isEmpty() && FILEBRW != fileName) {
        QMessageBox::StandardButton reply = QMessageBox::question(
            this, "Confirm File Change",
            QString("You have already opened a file. If you select a new one, the current file will be closed. "
                    "Do you want to set '%1' as the new path?").arg(fileInfo.fileName()),
            QMessageBox::Yes | QMessageBox::No);

        if (reply == QMessageBox::Yes) {
            ui->myComboBox->clear();
            figureViewer->clear();
            figureViewer_STD->clear();
            ui->imgLabel->clear();
            ui->buttonStep01->setEnabled(false);
            ui->buttonExplorer->setEnabled(false);
            ui->label_N->setText("SEGMENTS: ");
            ui->label_fs->setText("BINSIZE: ");
            ui->label_ft->setText("BINTIME: ");
            ui->labelDescription->setText("Description: ");
            ui->textFileSelected->clear();

            FILEBRW = nullptr;
            mainPath = nullptr;
            infoPath = nullptr;
        } else { return; }
    }

    // Save the file brw path
    FILEBRW = fileName;
    qDebug() << "FILEBRW: " << FILEBRW;

    // Setting the file path as the window title...
    setWindowTitle(FILEBRW);

    // Changing the value of "textFileSelected"
    ui->textFileSelected->insert(fileInfo.fileName());
}



void evalRegister::actionLoadTriggered()
{
    // Ensure that brwPath.txt is saved in
    if (QDir::currentPath() != QCoreApplication::applicationDirPath()) {
        QDir::setCurrent(QCoreApplication::applicationDirPath());
    }

    // Reading brwPath.txt to load the last path
    QString lastPath = loadPathFromFile("lastLoadBRW");

    // File Dialog: Open the last folder selected
    QString fileName = QFileDialog::getOpenFileName(this, "Select config.ini file", lastPath, "ini files (*.ini)");
    QFileInfo fileInfo(fileName);

    // File was not selected...
    if (fileName.isEmpty()) {
        return;
    }

    // File extension validation
    while (fileInfo.suffix().compare("ini", Qt::CaseInsensitive)) {
        QMessageBox::warning(this, "Incorrect extension", "This file does not have the .brw extension.");

        fileName = QFileDialog::getOpenFileName(this, "Select config.ini file", "", "ini files (*.ini)");
        fileInfo.setFile(fileName);

        if (fileName.isEmpty()) {
            return;
        }
    }

    // Writing the last path in the file brwPath.txt
    savePathToFile("lastLoadBRW", fileInfo.absolutePath());

    // Setting the new PATHMAIN
    if (!QDir::setCurrent(fileInfo.absolutePath())) {
        qDebug() << "Error: Changing execution path";
    }

    // Reading some variables from config.ini
    QSettings settings("config.ini", QSettings::IniFormat);
    QString fileSelected = settings.value("fileSelected").toString();

    if (mainPath == nullptr) {
        mainPath = settings.value("mainPath").toString();
    }

    // Cleaning for a new file loaded
    if (mainPath != fileInfo.absolutePath()) {
        QMessageBox::StandardButton reply = QMessageBox::question(
            this, "Confirm File Change",
            QString("You have already loaded a file. If you select a new one, the current file will be closed. "
                    "Do you want to set '%1' as the new path?").arg(fileSelected),
            QMessageBox::Yes | QMessageBox::No);

        if (reply == QMessageBox::No) {
            return;
        }
    }

    // Some auxiliar functions
    loadFromIni();
    figuresPath("STEP00");
    ui->typeOfGraphComboBox->setEnabled(true);

    // Load code for Spectrograms
    evalJuliaString("PATHINFO", infoPath);

    // Julia Callings
    QDir::setCurrent(QCoreApplication::applicationDirPath());
    jl_eval_string("cd(\"methods/\");");
    jl_eval_string("include(\"CODE_SPEC.jl\");");

    // Enabling buttons...
    ui->buttonStep01->setEnabled(true);
    ui->buttonExplorer->setEnabled(true);
    ui->buttonBinBehaviour->setEnabled(true);

    // Setting the file path as the window title...
    setWindowTitle(mainPath);

    // Save the file brw path
    qDebug() << "mainPath: " << mainPath;

    // Update STEP01 button
    ui->buttonStep01->setEnabled(true);
}



void evalRegister::ButtonEvaluateClicked()
{
    // Checking for a file seleted
    if(ui->textFileSelected->text().isEmpty()) {
        QMessageBox::warning(this, "File not selected", "Please select a file to evaluate");
        return;
    }

    // Verify if file exists
    if(!QFile::exists(FILEBRW)) {
        QString brwErrorMessage = "Verify that the path is correct: " + FILEBRW;
        QMessageBox::warning(this, "File not found", brwErrorMessage);
        return;
    }

    // Returnig to the main path
    if (QDir::currentPath() != QCoreApplication::applicationDirPath()) {
        QDir::setCurrent(QCoreApplication::applicationDirPath());
    }

    // Sending .brw path and MaxGB to Julia
    evalJuliaString("FILEBRW", FILEBRW);
    evalJuliaFloat("MaxGB", ui->maxGBSpinBox->value());
    evalJuliaInt("minSegments", ui->spinBoxMinSegments->value());

    // Setting Graph Configuration
    evalJulia("cm_", ":" + ui->colorComboBox->currentText());

    // Setting some configurations....
    evalJuliaFloat("limSat", ui->doubleSpinBoxLimSat->value());
    evalJuliaInt("THR_EMP", ui->spinBoxVoltageThr->value());
    evalJuliaInt("Δt", ui->spinBoxVoltageInt->value());

    evalJuliaInt("n1", ui->spinBoxN1->value());
    evalJuliaInt("n_overlap1", ui->spinBoxN_overlap->value());

    // Julia Callings
    jl_eval_string("cd(\"methods/\");");

    // Step 1 - Only the graphs
    jl_eval_string("include(\"CODE_STEP_00.jl\");");

    // Assign the return value of Julia to a C object of Julia type
    QString description = juliaStringValue("Variables[\"Description\"]");
    int N = juliaIntValue("N");
    float fs = juliaFloatValue("fs");
    float ft = juliaFloatValue("ft");
    int defaultTime = juliaIntValue("flagQtUI");

    // Checking for Δt
    jl_eval_string("maxLim = floor(Int, ( ft * 1000 ) - 1);");
    int maxLim = juliaIntValue("maxLim");

    // Setting spinBoxVoltageInt maximumValue and Δt to highest value in Julia
    ui->spinBoxVoltageInt->setMaximum(maxLim);

    if(ui->spinBoxVoltageInt->value() >= maxLim) {
        evalJuliaInt("Δt", ui->spinBoxVoltageInt->maximum());
        qDebug() << "Δt set to maximun: " << ui->spinBoxVoltageInt->maximum();
    }

    // Updating Description:
    ui->labelDescription->setText(QString("Description: " + description));

    // Updating Settings of each segment
    ui->label_N->setText("SEGMENTS: " + QString::number(N));
    ui->label_fs->setText("BINSIZE: " + QString::number(fs) + " GB");

    if(defaultTime == 1 ) {
        ui->label_ft->setText("BINTIME: " + QString::number(ft) + " seg (Default Time)" );
    } else {
        ui->label_ft->setText("BINTIME: " + QString::number(ft) + " seg" );
    }

    QString continueProcess = "";

    if(defaultTime == 1) { // Default
        continueProcess = "Do you want to continue the process?\n\nSegments: " + QString::number(N) + "\nBINSIZE: " + QString::number(fs) + " GB\nBINTIME: " + QString::number(ft) + " seg (Default Time)";
    } else { // No Default
        continueProcess = "Do you want to continue the process?\n\nSegments: " + QString::number(N) + "\nBINSIZE: " + QString::number(fs) + " GB\nBINTIME: " + QString::number(ft) + " seg";
    }

    // Sharing N, BINSIZE and Time
    QMessageBox::StandardButton accepted;
    accepted = QMessageBox::question(nullptr, "Confirm",
                                  continueProcess,
                                  QMessageBox::Yes | QMessageBox::No);
    if (accepted == QMessageBox::No) { return; }

    // Clearing Spectro img
    ui->imgLabel->clear();

    // For loop Step-00...
    QProgressDialog progress("Getting segments...", "Cancel", 0, N + 1, this);
    progress.setWindowFlags(progress.windowFlags() & ~Qt::WindowContextHelpButtonHint);
    progress.setWindowModality(Qt::WindowModal);
    progress.setMinimumDuration(0);
    progress.setValue(0);

    // Update ui to show everyEvent (Force to show QProgressBar)
    QApplication::processEvents();

    for(int n = 1; n <= N; n++) {
        if (progress.wasCanceled()) { break; }
        evalJuliaInt("n", n);
        STEP00();
        progress.setValue(n);
        if (progress.wasCanceled()) { break; }
        QApplication::processEvents();
    }
    progress.setValue(N + 1);

    // Run a needed filebrw path functions....
    /*
     * TO DO:
     *      This is the best place to execute the STEP01, after codeStep00_saving
     */

    // Saving some paths from STEP00
    QFileInfo fileInfo(juliaStringValue("PATHMAIN"));
    mainPath = fileInfo.absoluteFilePath(); // Change to mainPath to saveTiIni();

    // Calling some aditional functions
    codeStep00_saving();
    figuresPath("STEP00");
    ui->typeOfGraphComboBox->setEnabled(true);

    // Setting mainPath to saveToIni()
    QDir::setCurrent(mainPath);
    saveToIni();

    // initialSpinValue Update
    ui->buttonStep01->setEnabled(true);
    ui->buttonExplorer->setEnabled(true);
    ui->buttonBinBehaviour->setEnabled(true);

    // Step-01-Finished Message...
    QMessageBox::about(this, "Finished process", "The process has finished...");
}



void evalRegister::ButtonBinBehavior()
{
    // Checking if PATHINFO is ok!
    if(searchInfoBRW() == nullptr) {
        return;
    }

    evalJuliaString("PATHINFO", searchInfoBRW());
    evalJuliaString("mainPath", mainPath);

    jl_eval_string("println(PATHINFO);");

    // Change path to execute CODE_BinBehavior.jl
    evalJuliaString("appPath", QCoreApplication::applicationDirPath());
    jl_eval_string("cd(appPath)");

    // Julia Callings
    jl_eval_string("cd(\"methods/\");");
    jl_eval_string("include(\"CODE_BinBehavior.jl\");");

    // Returning to the mainPath
    jl_eval_string("cd(mainPath)");

    // Setting BinBehaviour in imgLabel
    QString figure = QDir::cleanPath(juliaStringValue("FILEFIGURE_RawBinBehavior")) + ".png";
    qDebug() << "Figure:" << figure;
    ui->imgLabel->setPixmap(QPixmap(figure));
}



void evalRegister::ComboBoxCurrentTextChanged(const QString &arg1)
{
//  Template for a QPixmap: ui->imgLabel->setPixmap(pic.scaled(ui->imgLabel->size(), Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation)); // Qt::KeepAspectRatio,Qt::SmoothTransformation));
    QString parentDirPath;
    int typeOfGraph = ui->typeOfGraphComboBox->currentIndex();

    switch (typeOfGraph) {
        case 0:
            parentDirPath = QFileInfo(mainPath).absoluteFilePath() + "/Figures/STEP00";
            break;
        case 1:
            parentDirPath = QFileInfo(mainPath).absoluteFilePath() + "/Figures/STEP01";
            break;
    }

    QString fileSVG = parentDirPath + "/" + arg1 + ".png";
    QString fileSVG2 = parentDirPath + "/" + arg1 + "std.png";

    // Research/Update for files added or removed
    if(QPixmap().load(fileSVG) && QPixmap().load(fileSVG2)) {
        figureViewer->setImage(fileSVG);
        figureViewer_STD->setImage(fileSVG2);
        int currentIndex = ui->myComboBox->currentIndex();
        figureViewer->BINSelected_Func(currentIndex);
    } else {
        qDebug() << "Error: No file found";
        int index = ui->myComboBox->findText(arg1);
        if (index != -1) {
            ui->myComboBox->removeItem(index);
        }
    }
}



void evalRegister::typeOfGraphComboBoxTextChanged(const QString &arg1)
{
    figuresPath(arg1);
}



void evalRegister::colorComboBoxTextChanged(const QString &arg1)
{
    QString filePath = QString(QCoreApplication::applicationDirPath() + "/resources/cbar/%1.png").arg(arg1);
    QPixmap pixmap(filePath);

    // Check if the image was uploaded
    if (!pixmap.isNull()) {
        ui->labelCbar->setPixmap(pixmap);
    } else {
        ui->labelCbar->setText("Error: Cbar not found.");
        ui->labelCbar->clear();
    }
}



void evalRegister::figuresPath(const QString &figures)
{
    QString directoryPath = FILEBRW;
    qDebug() << "BRW File Path: " << directoryPath;

    QFileInfo fileInfo(directoryPath);
    QDir parentDir = fileInfo.absoluteDir().absolutePath() + "/..";
    QString figuresPath = parentDir.absolutePath() + "/" + fileInfo.baseName() + "/Figures/" + figures;

    qDebug() << "Figures Path: " << figuresPath;
    qDebug() << "Parent Dir: " << parentDir;

    QDir figuresDir(figuresPath);

    if (!figuresDir.exists()) {
        QMessageBox::warning(this, "Folder not found", "The 'Figures' folder was not found in the specified directory.");
        return;
    }

    QStringList nameFilters;
    nameFilters << "*_.png";

    QFileInfoList filesInfo = figuresDir.entryInfoList(nameFilters, QDir::Files, QDir::Name);

    QStringList files;
    for (const QFileInfo &fileInfo : filesInfo) {
        QString fileNameNoExtension = fileInfo.completeBaseName();
        files.append(fileNameNoExtension);
    }

    qDebug() << "Files: " << files;

    ui->myComboBox->clear();
    ui->myComboBox->addItems(files);
    ui->myComboBox->setCurrentIndex(0);
}



void evalRegister::ButtonStep01Clicked() // This function need to be Update
{
    // Checking if PATHINFO is ok!
    if(searchInfoBRW() == nullptr) {
        return;
    }

    evalJuliaString("PATHINFO", searchInfoBRW());
    evalJuliaString("mainPath", mainPath);
    jl_eval_string("println(\"PATHMAIN: \", mainPath)");
    jl_eval_string("println(\"PATHINFO: \", PATHINFO)");

    // Setting some configurations....
    evalJulia("cm_", ":" + ui->colorComboBox->currentText());
    evalJuliaFloat("limSat", ui->doubleSpinBoxLimSat->value());
    evalJuliaInt("THR_EMP", ui->spinBoxVoltageThr->value());
    evalJuliaInt("Δt", ui->spinBoxVoltageInt->value());

    // Change path to execute STEP01.jl
    evalJuliaString("appPath", QCoreApplication::applicationDirPath());
    jl_eval_string("cd(appPath)");

    // Julia Callings
    jl_eval_string("cd(\"methods/\");");
    jl_eval_string("include(\"CODE_STEP_01.jl\");");

    // Assign the return value of Julia to a C object of Julia type
    int N = juliaIntValue("N");

    // For loop Step-01...
    QProgressDialog progress("Getting figures...", "Cancel", 0, N + 1, this);
    progress.setWindowFlags(progress.windowFlags() & ~Qt::WindowContextHelpButtonHint);
    progress.setWindowModality(Qt::WindowModal);
    progress.setMinimumDuration(0);
    progress.setValue(0);

    // Update ui to show everyEvent (Force to show QProgressBar)
    QApplication::processEvents();

    for(int n = 1; n <= N; n++) {
        if (progress.wasCanceled()) { break; }
        evalJuliaInt("n", n);
        jl_eval_string("include(\"CODE_STEP01_Figures.jl\");");
        progress.setValue(n);
        if (progress.wasCanceled()) { break; }
        QApplication::processEvents();
    }
    progress.setValue(N + 1);

    // Calling some aditional functions
    codeStep01_saving();
    figuresPath("STEP01");
    ui->typeOfGraphComboBox->setEnabled(true);

    // Setting mainPath to saveToIni()
    QDir::setCurrent(mainPath);
    saveToIni();

    // Step-01-Finished Message...
    QMessageBox::about(this, "Finished process", "The process has finished...");
}



void evalRegister::STEP00()
{
    jl_eval_string("BINRAW = OneSegment( RAW, Variables, n, N );");
    jl_eval_string("BINRAW = Digital2Analogue( Variables, BINRAW );");
    jl_eval_string("local nChs, nfrs = size( BINRAW );");

    if (ui->saveBINCheckBox->checkState() == 2 ) {
        jl_eval_string("BINNAME = joinpath( PATHSTEP00, string( \"BIN\", lpad( n, n0s, \"0\" ), \".jld2\" ) );");
        jl_eval_string("jldsave( BINNAME; Data = Float16.( BINRAW ) );");
    }

    jl_eval_string("SatChs, SatFrs = SupInfThr( BINRAW, THR_EMP );");
    jl_eval_string("PerSat = zeros( nChs );");
    jl_eval_string("PerSat[ SatChs ] .= round.( length.( SatFrs ) ./ nfrs, digits = 2 );");
    jl_eval_string("empties = findall( PerSat .>= limSat );");

    // # Cardinality
    jl_eval_string("Cardinality[ n ] = UniqueCount( BINRAW );"); // sigma
    jl_eval_string("data = zscore( PatchEmpties( Cardinality[ n ], empties ) );");
    jl_eval_string("P = Zplot( data, cm_ );");
    jl_eval_string("PF = plot( P, wsize = ( 64, 64 ), cbar = false, margins = -2mm );");
    jl_eval_string("FIGNAME = joinpath( PATHFIGURES_STEP00, string( \"BIN\", lpad( n, n0s, \"0\" ), \"_\" ) );");
    jl_eval_string("Plots.png( PF, FIGNAME );");

    // # VoltageShiftDeviation
    jl_eval_string("VoltageShiftDeviation[ n ] = STDΔV( Variables, BINRAW, Δt );");
    jl_eval_string("data = zscore( PatchEmpties( VoltageShiftDeviation[ n ], empties ) );");
    jl_eval_string("P = Zplot( data, cm_ );");
    jl_eval_string("PF = plot( P, wsize = ( 64, 64 ), cbar = false, margins = -2mm );");
    jl_eval_string("FIGNAME = joinpath( PATHFIGURES_STEP00, string( \"BIN\", lpad( n, n0s, \"0\" ), \"_std\" ) );");
    jl_eval_string("Plots.png( PF, FIGNAME );");

    // Last part of for loop
    jl_eval_string("Empties[ n ] = empties;");
    jl_eval_string("println(\"$n listo de $N\");");
}



QString evalRegister::searchInfoBRW()
{
    QFileInfo fileInfo(mainPath);
    QDir parentDir = fileInfo.absoluteDir().absolutePath();
    infoPath = parentDir.absolutePath() + "/" + fileInfo.baseName() + "/Info";

    QDir infoDir(infoPath);

    if (!infoDir.exists()) {
        QMessageBox::warning(this, "Folder not found", "The 'Info' folder was not found in the specified directory.");
        return nullptr;
    }

    QStringList nameFilters;
    nameFilters << "*.jld2";

    QFileInfoList jld2FilesInfo = infoDir.entryInfoList(nameFilters, QDir::Files, QDir::Name);

    QStringList requiredFiles = { "Parameters", "STEP00", "Variables" };
    QSet<QString> foundFiles;

    for (const QFileInfo &fileInfo : jld2FilesInfo) {
        QString fileNameNoExtension = fileInfo.completeBaseName();

        if (requiredFiles.contains(fileNameNoExtension)) {
            foundFiles.insert(fileNameNoExtension);
        }
    }

    // Check if all required files were found
    bool allFilesFound = (foundFiles.size() == requiredFiles.size());

    if (!allFilesFound) {
        qDebug() << "There are missing files";

        QStringList missingFiles;
        for (const QString &requiredFile : requiredFiles) {
            if (!foundFiles.contains(requiredFile)) {
                missingFiles.append(requiredFile + ".jld2");
            }
        }

        QString missingFilesMessage = "The following files are missing:\n" + missingFiles.join("\n");
        QMessageBox::warning(this, "Missing files", missingFilesMessage);

        return nullptr;
    }

    return infoPath;
}



QString evalRegister::loadPathFromFile(const QString &key)
{
    QFile pathFile("brwPath.txt");
    QString path = "";

    if (pathFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&pathFile);
        while (!in.atEnd()) {
            QString line = in.readLine();
            if (line.startsWith(key + "=")) {
                path = line.mid(key.length() + 1);
                break;
            }
        }
        pathFile.close();
    }

    return path;
}



void evalRegister::savePathToFile(const QString &key, const QString &path)
{
    QFile pathFile("brwPath.txt");
    QStringList lines;

    // Read existing lines
    if (pathFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&pathFile);
        while (!in.atEnd()) {
            QString line = in.readLine();
            if (!line.startsWith(key + "=")) {
                lines.append(line);
            }
        }
        pathFile.close();
    }

    // Add or update the path
    lines.append(key + "=" + path);

    // Write back to file
    if (pathFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream out(&pathFile);
        for (const QString &line : lines) {
            out << line << "\n";
        }
        pathFile.close();
    }
}



void evalRegister::saveToIni()
{
    QSettings settings("config.ini", QSettings::IniFormat);

    // Save Variables
    settings.setValue("maxGB", ui->maxGBSpinBox->value()); // double
    settings.setValue("minSegments", ui->spinBoxMinSegments->value()); // int
    settings.setValue("colorScheme", ui->colorComboBox->currentText()); // QString
    settings.setValue("threEmp", ui->spinBoxVoltageThr->value()); // int
    settings.setValue("voltageInt", ui->spinBoxVoltageInt->value()); // int
    settings.setValue("maxLim", ui->spinBoxVoltageInt->maximum()); // int
    settings.setValue("limSat", ui->doubleSpinBoxLimSat->value()); // double
    settings.setValue("segments", ui->label_N->text()); // QString
    settings.setValue("binSize", ui->label_fs->text()); // QString
    settings.setValue("binTime", ui->label_ft->text()); // QString
    settings.setValue("description", ui->labelDescription->text()); //QString

    // Save Paths
    settings.setValue("fileSelected", ui->textFileSelected->text());
    settings.setValue("FILEBRW", FILEBRW);
    settings.setValue("mainPath", mainPath);
}



void evalRegister::loadFromIni()
{
    QSettings settings("config.ini", QSettings::IniFormat);

    // Load Variables
    ui->maxGBSpinBox->setValue(settings.value("maxGB").toDouble());
    ui->spinBoxMinSegments->setValue(settings.value("minSegments").toInt());
    ui->spinBoxVoltageThr->setValue(settings.value("threEmp").toInt());
    ui->spinBoxVoltageInt->setValue(settings.value("voltageInt").toInt());
    ui->spinBoxVoltageInt->setMaximum(settings.value("maxLim").toInt());
    ui->doubleSpinBoxLimSat->setValue(settings.value("limSat").toDouble());
    ui->label_N->setText(settings.value("segments").toString());
    ui->label_fs->setText(settings.value("binSize").toString());
    ui->label_ft->setText(settings.value("binTime").toString());
    ui->labelDescription->setText(settings.value("description").toString());

    // This is the correct way to load last colorScheme
    QString colorScheme = settings.value("colorScheme").toString();
    int index = ui->colorComboBox->findText(colorScheme);
    if (index != -1) {
        ui->colorComboBox->setCurrentIndex(index);
    }

    // Load Paths
    ui->textFileSelected->setText(settings.value("fileSelected").toString());
    FILEBRW = settings.value("FILEBRW").toString();
    mainPath = settings.value("mainPath").toString();
    infoPath = searchInfoBRW();
}



void evalRegister::codeStep00_saving()
{
    jl_eval_string("close( RAW )");

    jl_eval_string("Empties = sort( unique!( vcat( Empties... ) ) );");
    jl_eval_string("step00 = Dict( \"Cardinality\" => Cardinality, \"VoltageShiftDeviation\" => VoltageShiftDeviation,\"Empties\" => Empties);");
    jl_eval_string("jldsave( FILESTEP00; Data = step00 );");

    jl_eval_string("Parameters = Dict( \"MaxGB\" => MaxGB, \"limSat\" => limSat, \"THR_EMP\" => THR_EMP, \"Δt\" => Δt, \"cm_\" => cm_, \"N\" => N, \"cm_\" => cm_);");
    jl_eval_string("jldsave( FILEPARAMETERS; Data = Parameters );");

    jl_eval_string("BINRAW = nothing;");
    jl_eval_string("Cardinality = nothing;");
    jl_eval_string("VoltageShiftDeviation = nothing;");
    jl_eval_string("Empties = nothing;");
    jl_eval_string("data = nothing;");
    jl_eval_string("step00 = nothing;");
    jl_eval_string("Parameters = nothing;");

    jl_eval_string("GC.gc();");
}

void evalRegister::codeStep01_saving()
{
    jl_eval_string("step01 = Dict( \"Cardinality\" => Cardinality, \"VoltageShiftDeviation\" => VoltageShiftDeviation, \"Sats\" => Sats, \"Repaired\" => Repaired, \"Empties\" => Empties );");
    jl_eval_string("jldsave( FILESTEP01; Data = step01 );");

    jl_eval_string("NewParameters = Dict( \"THR_SES\" => THR_SES, \"minchan\" => minchan, \"maxrad\"  => maxrad, \"maxIt\"   => maxIt );");
    jl_eval_string("Parameters = merge( Parameters, NewParameters );");
    jl_eval_string("jldsave( FILEPARAMETERS; Data = Parameters );");

    jl_eval_string("BINRAW = nothing;");
    jl_eval_string("BINPATCH = nothing;");
    jl_eval_string("Cardinality = nothing;");
    jl_eval_string("VoltageShiftDeviation = nothing;");
    jl_eval_string("Sats = nothing;");

    jl_eval_string("Repaired = nothing;");
    jl_eval_string("Variables = nothing;");
    jl_eval_string("step00 = nothing;");
    jl_eval_string("Parameters = nothing;");

    jl_eval_string("GC.gc();");
}



void evalRegister::ButtonOpenExplorer()
{
    if (mainPath.isEmpty()) { qDebug() << "Error: mainPath is empty."; }

    QString figuresPath = mainPath + "/Figures";

    QDir figuresDir(figuresPath);
    if (!figuresDir.exists()) {
        qDebug() << "Error: Figures directory does not exist at specified path.";
    }

    QString directory = QDir::toNativeSeparators(figuresPath);
    if (directory.isEmpty()) {
        qDebug() << "Error: Failed to convert path to native format.";
    }

    if (!QDesktopServices::openUrl(QUrl::fromLocalFile(directory))) {
        qDebug() << "Error: Could not open directory in file explorer.";
    }

    qDebug() << "Directory opened successfully: " << directory;
}



// This slot just see n1_SpinBox and not n_overlap_SpinBox
void evalRegister::SpinBoxN1ValueChanged(int arg1)
{
    figureViewer->SpectroParametersN1(arg1);
}



void evalRegister::SpinBoxNoverLapValueChanged(int arg1)
{
    figureViewer->SpectroParametersNoverLap(arg1);
}



void evalRegister::setSpectro(const QString &filename)
{
    QPixmap pic(filename);

    if (!pic.isNull()) {
        ui->imgLabel->setPixmap(pic.scaled(ui->imgLabel->size(), Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation));
    } else {
        ui->imgLabel->setText("Error: BINTIME < 0.5s");
    }
}



// Function to jl_eval_string
void evalRegister::evalJulia(const QString& key, const QString& value) {
    QString evalString = key + " = " + value + ";";
    QByteArray evalUtf = evalString.toUtf8();
    const char *evalConst = evalUtf.constData();
    jl_eval_string(evalConst);
}

void evalRegister::evalJuliaString(const QString &key, const QString &value) {
    QString stringValue = "\"" + value + "\"";
    evalJulia(key, stringValue);
}

void evalRegister::evalJuliaInt(const QString& key, int value) {
    evalJulia(key, QString::number(value));
}

void evalRegister::evalJuliaFloat(const QString& key, float value) {
    evalJulia(key, QString::number(value));
}

QString evalRegister::juliaStringValue(const QString& juliaVar)
{
    QString stringVar = "string(" + juliaVar + ");";
    QByteArray varUtf = stringVar.toUtf8();
    const char *varConst = varUtf.constData();

    jl_value_t *value = jl_eval_string(varConst);
    const char *value_str = jl_string_ptr(value);

    return QString::fromUtf8(value_str);
}

int evalRegister::juliaIntValue(const QString& juliaVar)
{
    return juliaStringValue(juliaVar).toInt();
}

float evalRegister::juliaFloatValue(const QString& juliaVar)
{
    return juliaStringValue(juliaVar).toFloat();
}








