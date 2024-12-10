#pragma once

#include <QWidget>

class FigureViewer : public QWidget
{
    Q_OBJECT
    Q_PROPERTY(QString filename READ filename WRITE setFilename NOTIFY filenameChanged FINAL)
    Q_PROPERTY(int currentChannel READ currentChannel WRITE setCurrentChannel NOTIFY currentChannelChanged FINAL)

public:
    // Constructor
    FigureViewer(QWidget *parent = nullptr);

    // My public function
    void setImage(const QString &imagePath);
    void BINSelected_Func(int &BINSelected_ComboBox);
    void SpectroParametersN1(int &n1_ComboBox);
    void SpectroParametersNoverLap(int &n_overlap1_ComboBox);

    // Q_PROPERTY WRITE
    void setFilename(const QString &filename);
    void setCurrentChannel(int currentChannel);

    // Q_PROPERTY READ
    QString filename() const;
    int currentChannel();

    // My Public auxiliar functions
    void clear();

    // My Public variables
    int BINSelected = 1;
    int n1 = 8200;
    int n_overlap1 = 8100;

signals:
    // Q_PROPERTY NOTIFY
    void filenameChanged(const QString &filename);
    void currentChannelChanged(int currentChannel);


protected:
    void paintEvent(QPaintEvent *event) override;
    void mouseMoveEvent(QMouseEvent *event) override;
    void mousePressEvent(QMouseEvent *event) override;

private:
    QImage image;
    int pixelSize;
    int hoveredX = -1;
    int hoveredY = -1;
    bool imageLoaded = false;

    QString m_filename;
    int m_currentChannel;

    // Julia auxiliar Functions
    void evalJulia(const QString& key, const QString& value);
    void evalJuliaString(const QString &key, const QString &value);
    void evalJuliaInt(const QString& key, int value);
    void evalJuliaFloat(const QString& key, float value);
    QString juliaStringValue(const QString& juliaVar);
    int juliaIntValue(const QString& juliaVar);
    float juliaFloatValue(const QString& juliaVar);
};

