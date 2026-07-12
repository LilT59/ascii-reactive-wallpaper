#pragma once

#include <QColor>
#include <QImage>
#include <QQuickItem>
#include <QTimer>
#include <QUrl>
#include <atomic>
#include <vector>

class QQuickWindow;

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
    Q_PROPERTY(qreal brightness READ brightness WRITE setBrightness NOTIFY brightnessChanged)
    Q_PROPERTY(qreal contrast READ contrast WRITE setContrast NOTIFY contrastChanged)
    Q_PROPERTY(qreal gamma READ gamma WRITE setGamma NOTIFY gammaChanged)
    Q_PROPERTY(qreal characterSpacing READ characterSpacing WRITE setCharacterSpacing NOTIFY characterSpacingChanged)
    Q_PROPERTY(bool reverseRamp READ reverseRamp WRITE setReverseRamp NOTIFY reverseRampChanged)
    Q_PROPERTY(bool imageDithering READ imageDithering WRITE setImageDithering NOTIFY imageDitheringChanged)
    Q_PROPERTY(qreal edgeEnhancement READ edgeEnhancement WRITE setEdgeEnhancement NOTIFY edgeEnhancementChanged)
    Q_PROPERTY(QString fontFamily READ fontFamily WRITE setFontFamily NOTIFY fontFamilyChanged)
    Q_PROPERTY(qreal foregroundOpacity READ foregroundOpacity WRITE setForegroundOpacity NOTIFY foregroundOpacityChanged)
    Q_PROPERTY(qreal glowStrength READ glowStrength WRITE setGlowStrength NOTIFY glowStrengthChanged)
    Q_PROPERTY(qreal proceduralScale READ proceduralScale WRITE setProceduralScale NOTIFY proceduralScaleChanged)
    Q_PROPERTY(qreal proceduralIntensity READ proceduralIntensity WRITE setProceduralIntensity NOTIFY proceduralIntensityChanged)
    Q_PROPERTY(bool reactiveEnabled READ reactiveEnabled WRITE setReactiveEnabled NOTIFY reactiveEnabledChanged)
    Q_PROPERTY(bool pointerMovement MEMBER m_pointerMovement NOTIFY pointerMovementChanged)
    Q_PROPERTY(bool clickRipple MEMBER m_clickRipple NOTIFY clickRippleChanged)
    Q_PROPERTY(int effectRadius MEMBER m_effectRadius NOTIFY effectRadiusChanged)
    Q_PROPERTY(qreal effectStrength MEMBER m_effectStrength NOTIFY effectStrengthChanged)
    Q_PROPERTY(qreal waveSpeed READ waveSpeed WRITE setWaveSpeed NOTIFY waveSpeedChanged)
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
    qreal brightness() const { return m_brightness; }
    qreal contrast() const { return m_contrast; }
    qreal gamma() const { return m_gamma; }
    qreal characterSpacing() const { return m_characterSpacing; }
    bool reverseRamp() const { return m_reverseRamp; }
    bool imageDithering() const { return m_imageDithering; }
    qreal edgeEnhancement() const { return m_edgeEnhancement; }
    QString fontFamily() const { return m_fontFamily; }
    qreal foregroundOpacity() const { return m_foregroundOpacity; }
    qreal glowStrength() const { return m_glowStrength; }
    qreal proceduralScale() const { return m_proceduralScale; }
    qreal proceduralIntensity() const { return m_proceduralIntensity; }
    qreal waveSpeed() const { return m_waveSpeed; }
    bool reactiveEnabled() const { return m_reactiveEnabled; }

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
    void setBrightness(qreal value);
    void setContrast(qreal value);
    void setGamma(qreal value);
    void setCharacterSpacing(qreal value);
    void setReverseRamp(bool value);
    void setImageDithering(bool value);
    void setEdgeEnhancement(qreal value);
    void setFontFamily(const QString &value);
    void setForegroundOpacity(qreal value);
    void setGlowStrength(qreal value);
    void setProceduralScale(qreal value);
    void setProceduralIntensity(qreal value);
    void setWaveSpeed(qreal value);
    void setReactiveEnabled(bool value);

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
    void brightnessChanged();
    void contrastChanged();
    void gammaChanged();
    void characterSpacingChanged();
    void reverseRampChanged();
    void imageDitheringChanged();
    void edgeEnhancementChanged();
    void fontFamilyChanged();
    void foregroundOpacityChanged();
    void glowStrengthChanged();
    void proceduralScaleChanged();
    void proceduralIntensityChanged();
    void reactiveEnabledChanged();
    void pointerMovementChanged();
    void clickRippleChanged();
    void effectRadiusChanged();
    void effectStrengthChanged();
    void waveSpeedChanged();
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
    void handleWindowChanged(QQuickWindow *window);
    void updateLifecycleState();
    void updateSimulationTimer();
    bool shouldRunSimulation() const;
    void reportProfile();
    static void recordDuration(std::atomic<quint64> &total, std::atomic<quint64> &maximum, quint64 elapsed);
    static qreal hash(int x, int y);

    struct ProfileCounters {
        std::atomic<quint64> characterFrames{0};
        std::atomic<quint64> characterNs{0};
        std::atomic<quint64> characterMaxNs{0};
        std::atomic<quint64> simulationSteps{0};
        std::atomic<quint64> simulationNs{0};
        std::atomic<quint64> simulationMaxNs{0};
        std::atomic<quint64> renderFrames{0};
        std::atomic<quint64> renderNs{0};
        std::atomic<quint64> renderMaxNs{0};
        std::atomic<quint64> atlasBuilds{0};
        std::atomic<quint64> atlasNs{0};
        std::atomic<quint64> glyphs{0};
        std::atomic<quint64> batches{0};
    };

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
    qreal m_waveSpeed = 1.5;
    qreal m_tension = 0.18;
    qreal m_damping = 0.65;
    qreal m_brightness = 0.05;
    qreal m_contrast = 1;
    qreal m_gamma = 1;
    qreal m_characterSpacing = 1;
    bool m_reverseRamp = false;
    bool m_imageDithering = true;
    qreal m_edgeEnhancement = 0.25;
    QString m_fontFamily = QStringLiteral("DejaVu Sans Mono");
    qreal m_foregroundOpacity = 1.0;
    qreal m_glowStrength = 0.0;
    qreal m_proceduralScale = 1.0;
    qreal m_proceduralIntensity = 1.0;
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
    std::vector<qreal> m_nextHeights;
    std::vector<qreal> m_nextVelocities;
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
    int m_mediaFrame = 0;
    bool m_animatedSource = false;
    QTimer m_simulationTimer;
    QTimer m_profileTimer;
    ProfileCounters m_profile;
    bool m_profilingEnabled = false;
    bool m_renderable = false;
    QMetaObject::Connection m_windowVisibilityConnection;
};
