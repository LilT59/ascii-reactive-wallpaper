#pragma once

#include <QColor>
#include <QElapsedTimer>
#include <QImage>
#include <QQuickItem>
#include <QTimer>
#include <QUrl>
#include <vector>

class QMediaPlayer;
class QMovie;
class QVideoSink;

class AsciiRenderer : public QQuickItem
{
    Q_OBJECT
    Q_PROPERTY(qreal time READ time WRITE setTime NOTIFY timeChanged)
    Q_PROPERTY(int mode READ mode WRITE setMode NOTIFY modeChanged)
    Q_PROPERTY(int detail READ detail WRITE setDetail NOTIFY detailChanged)
    Q_PROPERTY(int characterSize READ characterSize WRITE setCharacterSize NOTIFY characterSizeChanged)
    Q_PROPERTY(int colorDepth READ colorDepth WRITE setColorDepth NOTIFY colorDepthChanged)
    Q_PROPERTY(int frameRate READ frameRate WRITE setFrameRate NOTIFY frameRateChanged)
    Q_PROPERTY(QColor primaryColor READ primaryColor WRITE setPrimaryColor NOTIFY primaryColorChanged)
    Q_PROPERTY(int sourceType READ sourceType WRITE setSourceType NOTIFY sourceTypeChanged)
    Q_PROPERTY(QUrl imageSource READ imageSource WRITE setImageSource NOTIFY imageSourceChanged)
    Q_PROPERTY(QString characterRamp READ characterRamp WRITE setCharacterRamp NOTIFY characterRampChanged)
    Q_PROPERTY(int imageFit READ imageFit WRITE setImageFit NOTIFY imageFitChanged)
    Q_PROPERTY(bool sourceColor READ sourceColor WRITE setSourceColor NOTIFY sourceColorChanged)
    Q_PROPERTY(bool customAnimationColor READ customAnimationColor WRITE setCustomAnimationColor NOTIFY customAnimationColorChanged)
    Q_PROPERTY(QString sourceError READ sourceError NOTIFY sourceErrorChanged)
    Q_PROPERTY(bool reactiveEnabled MEMBER m_reactiveEnabled NOTIFY reactiveEnabledChanged)
    Q_PROPERTY(bool pointerMovement MEMBER m_pointerMovement NOTIFY pointerMovementChanged)
    Q_PROPERTY(bool clickRipple MEMBER m_clickRipple NOTIFY clickRippleChanged)
    Q_PROPERTY(int effectRadius MEMBER m_effectRadius NOTIFY effectRadiusChanged)
    Q_PROPERTY(qreal effectStrength MEMBER m_effectStrength NOTIFY effectStrengthChanged)
    Q_PROPERTY(qreal tension MEMBER m_tension NOTIFY tensionChanged)
    Q_PROPERTY(qreal damping MEMBER m_damping NOTIFY dampingChanged)

public:
    explicit AsciiRenderer(QQuickItem *parent = nullptr);
    qreal time() const { return m_time; }
    int mode() const { return m_mode; }
    int detail() const { return m_detail; }
    int characterSize() const { return m_charHeight; }
    int colorDepth() const { return m_colorDepth; }
    int frameRate() const { return m_frameRate; }
    QColor primaryColor() const { return m_color; }
    int sourceType() const { return m_sourceType; }
    QUrl imageSource() const { return m_imageSource; }
    QString characterRamp() const { return m_ramp; }
    int imageFit() const { return m_imageFit; }
    bool sourceColor() const { return m_sourceColor; }
    bool customAnimationColor() const { return m_customAnimationColor; }
    QString sourceError() const { return m_sourceError; }

    void setTime(qreal value);
    void setMode(int value);
    void setDetail(int value);
    void setCharacterSize(int value);
    void setColorDepth(int value);
    void setFrameRate(int value);
    void setPrimaryColor(const QColor &value);
    void setSourceType(int value);
    void setImageSource(const QUrl &value);
    void setCharacterRamp(const QString &value);
    void setImageFit(int value);
    void setSourceColor(bool value);
    void setCustomAnimationColor(bool value);

    Q_INVOKABLE void movePointer(qreal x, qreal y);
    Q_INVOKABLE void clickPointer(qreal x, qreal y);
    Q_INVOKABLE void resetPointer();

signals:
    void timeChanged();
    void modeChanged();
    void detailChanged();
    void characterSizeChanged();
    void colorDepthChanged();
    void frameRateChanged();
    void primaryColorChanged();
    void sourceTypeChanged();
    void imageSourceChanged();
    void characterRampChanged();
    void imageFitChanged();
    void sourceColorChanged();
    void customAnimationColorChanged();
    void sourceErrorChanged();
    void reactiveEnabledChanged();
    void pointerMovementChanged();
    void clickRippleChanged();
    void effectRadiusChanged();
    void effectStrengthChanged();
    void tensionChanged();
    void dampingChanged();

protected:
    QSGNode *updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) override;
    void geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry) override;

private:
    void rebuildGrid();
    void rebuildImage();
    void processImage(const QImage &image);
    void setSourceError(const QString &error);
    void updateAdaptivePalette(bool animated);
    int nearestPaletteColor(const QColor &color) const;
    void rebuildImageColorIndices();
    void addImpulse(qreal x, qreal y, qreal strength);
    void stepSimulation();
    void regenerateCharacters();
    void updateMatrix(qreal deltaTime);
    qreal brightnessAt(int x, int y) const;
    static qreal hash(int x, int y);

    qreal m_time = 0;
    int m_mode = 0;
    int m_detail = 1;
    QColor m_color = QColor("#7fdbff");
    int m_sourceType = 0;
    int m_imageFit = 1;
    bool m_sourceColor = false;
    bool m_customAnimationColor = false;
    int m_colorDepth = 32;
    int m_frameRate = 24;
    QUrl m_imageSource;
    QString m_ramp = QStringLiteral(" .:-=+*#%@");
    bool m_reactiveEnabled = true;
    bool m_pointerMovement = true;
    bool m_clickRipple = true;
    int m_effectRadius = 6;
    qreal m_effectStrength = 1.5;
    qreal m_tension = 0.18;
    qreal m_damping = 0.92;
    int m_columns = 0;
    int m_rows = 0;
    int m_charWidth = 11;
    int m_charHeight = 19;
    qreal m_lastX = -1;
    qreal m_lastY = -1;
    bool m_simulationActive = false;
    bool m_atlasDirty = true;
    std::vector<qreal> m_heights;
    std::vector<qreal> m_velocities;
    std::vector<qreal> m_imageBrightness;
    std::vector<QColor> m_imageColors;
    std::vector<int> m_imageColorIndices;
    std::vector<int> m_characters;
    std::vector<int> m_colorIndices;
    std::vector<qreal> m_matrixBrightness;
    std::vector<int> m_matrixCharacters;
    qreal m_lastMatrixTime = 0;
    QVector<QColor> m_palette;
    QString m_sourceError;
    QMovie *m_movie = nullptr;
    QMediaPlayer *m_player = nullptr;
    QVideoSink *m_videoSink = nullptr;
    int m_mediaFrame = 0;
    bool m_animatedSource = false;
    QElapsedTimer m_mediaThrottle;
    QTimer m_simulationTimer;
};
