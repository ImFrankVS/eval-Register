#include "FigureViewer.h"

// Project Libraries
#include <QPainter>
#include <QMouseEvent>
#include <QImage>
#include <QMessageBox>
#include <QDebug>
#include <julia.h>

// Constructor
FigureViewer::FigureViewer(QWidget *parent)
    : QWidget(parent), pixelSize(5)
{ // Defining Widget Properties
    setFixedSize(320, 320);
    setMouseTracking(true);

    // image = QImage("ico_cinvestav.png");
    QImage img(64, 64, QImage::Format_RGB32);

    for(int y = 0; y < 64; y++) {
        for(int x = 0; x < 64; x++) {
            QColor color(255, 255, 255);
            img.setPixelColor(x, y, color);
        }
    }

    image = img;
}



void FigureViewer::setImage(const QString &imagePath)
{
    QImage newImage(imagePath);

    if (newImage.size() == QSize(64, 64)) {
        imageLoaded = true;
        image = newImage;
        update();
    } else {
        QMessageBox::warning(this, "Error", "The Figure must be 64x64 pixels.");
    }
}



void FigureViewer::paintEvent(QPaintEvent *event)
{
    QPainter painter(this);

    // Draw image, scalling each pixel to 10x10
    for(int y = 0; y < 64; y++) {
        for(int x = 0; x < 64; x++) {
            QColor color;

            // Change color if mouse is hovering over the pixel
            if (x == hoveredX && y == hoveredY) {
                color = QColor(255, 0, 0, 127);
            } else {
                color = image.pixelColor(x, y);
            }

            QRect rect(x * pixelSize, y * pixelSize, pixelSize, pixelSize);
            painter.fillRect(rect, color);
        }
    }
}



void FigureViewer::mouseMoveEvent(QMouseEvent *event)
{
    // Getting the coords for mouse hover
    int x = event->x() / pixelSize;
    int y = event->y() / pixelSize;

    if (x >= 0 && x < 64 && y >= 0 && y < 64) {
        hoveredX = x;
        hoveredY = y;
        update();

        int currentChannel = (y * 64) + (x + 1);
        setCurrentChannel(currentChannel);
    }
}



void FigureViewer::mousePressEvent(QMouseEvent *event)
{
    // Checking if FigureViewer is empty
    if(!imageLoaded) {
        return;
    }

    // Getting the coords for mouseClickEvent
    int x = event->x() / pixelSize;
    int y = event->y() / pixelSize;

    if (x >= 0 && x < 64 && y >= 0 && y < 64) {
        int pixelNumber = y * 64 + x + 1;

        // Calling 'evalJuliaString' function
        evalJuliaInt("segment", BINSelected);
        evalJuliaInt("channelSpectro", pixelNumber);
        evalJuliaInt("n1", n1);
        evalJuliaInt("n_overlap1", n_overlap1);

        jl_eval_string("BINNAME = joinpath( PATHSTEP00, string( \"BIN\", lpad( segment, n0s, \"0\" ), \".jld2\" ) );");
        jl_eval_string("BINPATCH = Float64.( LoadDict( BINNAME ) );");
        jl_eval_string("p = Channel_Spectrogram(BINPATCH, channelSpectro, n1, n_overlap1);");
        jl_eval_string("filename_string = joinpath( PATHSPECTROGRAMS, \"BIN_$(lpad(segment, n0s, \"0\"))_Channel_$channelSpectro\");");
        jl_eval_string("Plots.png(p, filename_string);");

        // Assign the filename_string from Julia to a C object of Julia type
        QString filename = juliaStringValue("filename_string") + ".png";
        qDebug() << "Spectro Path: " << filename;

        setFilename(filename);
    }
}



void FigureViewer::BINSelected_Func(int &BINSelected_ComboBox)
{
    FigureViewer::BINSelected = BINSelected_ComboBox + 1;
}



// This function is not using...
void FigureViewer::SpectroParametersN1(int &n1_ComboBox)
{
    n1 = n1_ComboBox;
}



void FigureViewer::SpectroParametersNoverLap(int &n_overlap1_ComboBox)
{
    n_overlap1 = n_overlap1_ComboBox;
}



QString FigureViewer::filename() const
{
    return m_filename;
}



int FigureViewer::currentChannel()
{
    return m_currentChannel;
}



void FigureViewer::setFilename(QString const &filename)
{
    if (m_filename == filename)
        return;

    m_filename = filename;
    emit filenameChanged(m_filename);
} // connect(secwind, &SecondWindow::messageChanged, this, &MainWindow::setFoo);



void FigureViewer::setCurrentChannel(int currentChannel)
{
    if (m_currentChannel == currentChannel)
        return;

    m_currentChannel = currentChannel;
    emit currentChannelChanged(m_currentChannel);
}



void FigureViewer::clear()
{
    // 64x64 QImage to clear FigureViewer
    QImage blankImage(64, 64, QImage::Format_RGB32);

    // Setting all pixels with white color
    for(int y = 0; y < 64; y++) {
        for(int x = 0; x < 64; x++) {
            QColor color(255, 255, 255);
            blankImage.setPixelColor(x, y, color);
        }
    } image = blankImage;

    // Reset hover
    hoveredX = -1;
    hoveredY = -1;

    // View refresh
    imageLoaded = false;
    update();
}


// Function to jl_eval_string
void FigureViewer::evalJulia(const QString& key, const QString& value) {
    QString evalString = key + " = " + value + ";";
    QByteArray evalUtf = evalString.toUtf8();
    const char *evalConst = evalUtf.constData();
    jl_eval_string(evalConst);
}

void FigureViewer::evalJuliaString(const QString &key, const QString &value) {
    QString stringValue = "\"" + value + "\"";
    evalJulia(key, stringValue);
}

void FigureViewer::evalJuliaInt(const QString& key, int value) {
    evalJulia(key, QString::number(value));
}

void FigureViewer::evalJuliaFloat(const QString& key, float value) {
    evalJulia(key, QString::number(value));
}

QString FigureViewer::juliaStringValue(const QString& juliaVar)
{
    QString stringVar = "string(" + juliaVar + ");";
    QByteArray varUtf = stringVar.toUtf8();
    const char *varConst = varUtf.constData();

    jl_value_t *value = jl_eval_string(varConst);
    const char *value_str = jl_string_ptr(value);

    return QString::fromUtf8(value_str);
}

int FigureViewer::juliaIntValue(const QString& juliaVar)
{
    return juliaStringValue(juliaVar).toInt();
}

float FigureViewer::juliaFloatValue(const QString& juliaVar)
{
    return juliaStringValue(juliaVar).toFloat();
}


