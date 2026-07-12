#include "asciirenderer.h"

#include <QFont>
#include <QFontMetrics>
#include <QPainter>
#include <QFileInfo>
#include <QElapsedTimer>
#include <QQuickWindow>
#include <QWindow>
#include <QDebug>
#include <QSGGeometryNode>
#include <QSGRendererInterface>
#include <QSGTextureMaterial>
#include <algorithm>
#include <cmath>
#include <limits>

namespace {
constexpr int MaxGlyphsPerBatch = 10000;
constexpr int VerticesPerGlyph = 6;

struct BatchNode : QSGGeometryNode {
    QSGGeometry geometry{QSGGeometry::defaultAttributes_TexturedPoint2D(), MaxGlyphsPerBatch * VerticesPerGlyph};
    QSGTextureMaterial material;
    QSGTexture *texture = nullptr;

    BatchNode()
    {
        geometry.setDrawingMode(QSGGeometry::DrawTriangles);
        geometry.setVertexDataPattern(QSGGeometry::DynamicPattern);
        geometry.setVertexCount(0);
        setGeometry(&geometry);
        setMaterial(&material);
        material.setFlag(QSGMaterial::Blending);
        material.setFiltering(QSGTexture::Linear);
    }

    void setTexture(QSGTexture *value)
    {
        if (texture == value) return;
        texture = value;
        material.setTexture(value);
        markDirty(QSGNode::DirtyMaterial);
    }

    void setGlyphCount(int count)
    {
        geometry.setVertexCount(count * VerticesPerGlyph);
        markDirty(QSGNode::DirtyGeometry);
    }

};

struct RenderRoot : QSGNode {
    QSGTexture *texture = nullptr;
    QSGTexture *glowTexture = nullptr;
    QVector<BatchNode *> batches;
    QVector<BatchNode *> glowBatches;
    ~RenderRoot() override
    {
        while (QSGNode *child = firstChild()) {
            removeChildNode(child);
            delete child;
        }
        delete texture;
        delete glowTexture;
    }

    BatchNode *batchAt(int index, bool glow)
    {
        auto &nodes = glow ? glowBatches : batches;
        if (index < nodes.size()) return nodes[index];
        auto *batch = new BatchNode;
        batch->setTexture(glow ? glowTexture : texture);
        if (glow) prependChildNode(batch); else appendChildNode(batch);
        nodes.append(batch);
        return batch;
    }

    void setBatchTextures(QSGTexture *value, bool glow)
    {
        const auto &nodes = glow ? glowBatches : batches;
        for (BatchNode *node : nodes) node->setTexture(value);
    }

    void hideBatchesFrom(int firstUnused, bool glow)
    {
        const auto &nodes = glow ? glowBatches : batches;
        for (int index = firstUnused; index < nodes.size(); ++index) nodes[index]->setGlyphCount(0);
    }
};
}

AsciiRenderer::AsciiRenderer(QQuickItem *parent) : QQuickItem(parent)
{
    setFlag(ItemHasContents, true);
    m_simulationTimer.setInterval(qRound(1000.0 / (30.0 * m_waveSpeed)));
    connect(&m_simulationTimer, &QTimer::timeout, this, &AsciiRenderer::stepSimulation);
    connect(this, &QQuickItem::visibleChanged, this, &AsciiRenderer::updateLifecycleState);
    connect(this, &QQuickItem::windowChanged, this, &AsciiRenderer::handleWindowChanged);
    m_profilingEnabled = qEnvironmentVariableIntValue("ASCII_WALLPAPER_PROFILE") != 0;
    if (m_profilingEnabled) {
        m_profileTimer.setInterval(5000);
        connect(&m_profileTimer, &QTimer::timeout, this, &AsciiRenderer::reportProfile);
        m_profileTimer.start();
    }
    m_palette = {m_color, QColor("#ff5555"), QColor("#ffb86c"), QColor("#f1fa8c"), QColor("#50fa7b"), QColor("#8be9fd"), QColor("#bd93f9"), QColor("#ff79c6"), QColor("#0b3d1b"), QColor("#147a35"), QColor("#27c95a"), QColor("#b8ffd0")};
}

void AsciiRenderer::setTime(qreal value)
{
    if (m_time == value) return;
    const qreal delta = std::clamp(value - m_time, 0.0, 0.25);
    m_time = value;
    emit timeChanged();
    // Static and decoded media frames update themselves; the QML clock is only
    // a source of procedural animation and must not rebuild static geometry.
    if (m_sourceType == 0 && m_mode == 1)
        updateMatrix(delta);
    if (m_sourceType == 0 && m_mode == 7)
        updateMatrix3D(delta);
    if (m_sourceType == 0)
        regenerateCharacters();
}
void AsciiRenderer::setMode(int value) { if (m_mode == value) return; m_mode = value; if (m_mode == 1 || m_mode == 7) { std::fill(m_matrixBrightness.begin(), m_matrixBrightness.end(), 0); std::fill(m_matrixCharacters.begin(), m_matrixCharacters.end(), 1); std::fill(m_cellDepth.begin(), m_cellDepth.end(), 0.1); m_lastMatrixTime = m_time; } emit modeChanged(); regenerateCharacters(); }
void AsciiRenderer::setPrimaryColor(const QColor &value) { if (m_color == value) return; m_color = value; if (m_sourceType == 0 || !m_sourceColor) m_palette[0] = value; m_atlasDirty = true; emit primaryColorChanged(); update(); }
void AsciiRenderer::setSourceType(int value) { if (m_sourceType == value) return; m_sourceType = value; emit sourceTypeChanged(); rebuildImage(); regenerateCharacters(); }
void AsciiRenderer::setImageSource(const QUrl &value) { if (m_imageSource == value) return; m_imageSource = value; emit imageSourceChanged(); rebuildImage(); regenerateCharacters(); }
void AsciiRenderer::setCharacterRamp(const QString &value) { const QString ramp = value.size() > 1 ? value : QStringLiteral(" .:-=+*#%@"); if (m_ramp == ramp) return; m_ramp = ramp; m_atlasDirty = true; emit characterRampChanged(); regenerateCharacters(); }
void AsciiRenderer::setImageFit(int value) { value = std::clamp(value, 0, 2); if (m_imageFit == value) return; m_imageFit = value; emit imageFitChanged(); rebuildImage(); }
void AsciiRenderer::setSourceColor(bool value) { if (m_sourceColor == value) return; m_sourceColor = value; if (value && m_sourceType == 1) updateAdaptivePalette(m_animatedSource); emit sourceColorChanged(); regenerateCharacters(); }
void AsciiRenderer::setCustomAnimationColor(bool value) { if (m_customAnimationColor == value) return; m_customAnimationColor = value; emit customAnimationColorChanged(); regenerateCharacters(); }
void AsciiRenderer::setBrightness(qreal value) { value = std::clamp(value, -1.0, 1.0); if (qFuzzyCompare(m_brightness, value)) return; m_brightness = value; emit brightnessChanged(); regenerateCharacters(); }
void AsciiRenderer::setContrast(qreal value) { value = std::clamp(value, 0.0, 2.0); if (qFuzzyCompare(m_contrast, value)) return; m_contrast = value; emit contrastChanged(); regenerateCharacters(); }
void AsciiRenderer::setGamma(qreal value) { value = std::clamp(value, 0.1, 3.0); if (qFuzzyCompare(m_gamma, value)) return; m_gamma = value; emit gammaChanged(); regenerateCharacters(); }
void AsciiRenderer::setReverseRamp(bool value) { if (m_reverseRamp == value) return; m_reverseRamp = value; emit reverseRampChanged(); regenerateCharacters(); }
void AsciiRenderer::setImageDithering(bool value) { if (m_imageDithering == value) return; m_imageDithering = value; emit imageDitheringChanged(); rebuildImage(); }
void AsciiRenderer::setEdgeEnhancement(qreal value) { value = std::clamp(value, 0.0, 1.0); if (qFuzzyCompare(m_edgeEnhancement, value)) return; m_edgeEnhancement = value; emit edgeEnhancementChanged(); rebuildImage(); }
void AsciiRenderer::setFontFamily(const QString &value) { const QString family = value.trimmed().isEmpty() ? QStringLiteral("DejaVu Sans Mono") : value; if (m_fontFamily == family) return; m_fontFamily = family; m_atlasDirty = true; emit fontFamilyChanged(); update(); }
void AsciiRenderer::setForegroundOpacity(qreal value) { value = std::clamp(value, 0.1, 1.0); if (qFuzzyCompare(m_foregroundOpacity, value)) return; m_foregroundOpacity = value; m_atlasDirty = true; emit foregroundOpacityChanged(); update(); }
void AsciiRenderer::setGlowStrength(qreal value) { value = std::clamp(value, 0.0, 1.0); if (qFuzzyCompare(m_glowStrength, value)) return; m_glowStrength = value; m_atlasDirty = true; emit glowStrengthChanged(); update(); }
void AsciiRenderer::setProceduralScale(qreal value) { value = std::clamp(value, 0.5, 2.0); if (qFuzzyCompare(m_proceduralScale, value)) return; m_proceduralScale = value; emit proceduralScaleChanged(); regenerateCharacters(); }
void AsciiRenderer::setProceduralIntensity(qreal value) { value = std::clamp(value, 0.25, 2.0); if (qFuzzyCompare(m_proceduralIntensity, value)) return; m_proceduralIntensity = value; emit proceduralIntensityChanged(); regenerateCharacters(); }
void AsciiRenderer::setWaveSpeed(qreal value)
{
    value = std::clamp(value, 0.5, 2.0);
    if (qFuzzyCompare(m_waveSpeed, value)) return;
    m_waveSpeed = value;
    m_simulationTimer.setInterval(qRound(1000.0 / (30.0 * m_waveSpeed)));
    emit waveSpeedChanged();
}
void AsciiRenderer::setReactiveEnabled(bool value)
{
    if (m_reactiveEnabled == value) return;
    m_reactiveEnabled = value;
    if (!value) {
        m_simulationActive = false;
        resetPointer();
        std::fill(m_heights.begin(), m_heights.end(), 0);
        std::fill(m_velocities.begin(), m_velocities.end(), 0);
        std::fill(m_nextHeights.begin(), m_nextHeights.end(), 0);
        std::fill(m_nextVelocities.begin(), m_nextVelocities.end(), 0);
        regenerateCharacters();
    }
    updateSimulationTimer();
    emit reactiveEnabledChanged();
}
void AsciiRenderer::setCharacterSpacing(qreal value)
{
    value = std::clamp(value, 0.5, 2.0);
    if (qFuzzyCompare(m_characterSpacing, value)) return;
    m_characterSpacing = value;
    m_charWidth = std::max(4, qRound(m_charHeight * 0.58 * m_characterSpacing));
    m_atlasDirty = true;
    emit characterSpacingChanged();
    rebuildGrid();
}
void AsciiRenderer::setColorDepth(int value) { value = std::clamp(value, 4, 64); if (m_colorDepth == value) return; m_colorDepth = value; if (m_sourceColor && m_sourceType == 1) updateAdaptivePalette(m_animatedSource); emit colorDepthChanged(); regenerateCharacters(); }
void AsciiRenderer::setFrameRate(int value) { value = std::clamp(value, 5, 60); if (m_frameRate == value) return; m_frameRate = value; emit frameRateChanged(); }

void AsciiRenderer::setCharacterSize(int value)
{
    value = std::clamp(value, 8, 48);
    if (m_charHeight == value) return;
    m_charHeight = value;
    m_charWidth = std::max(4, qRound(value * 0.58 * m_characterSpacing));
    m_atlasDirty = true;
    emit characterSizeChanged();
    rebuildGrid();
}
void AsciiRenderer::setSourceError(const QString &error) { if (m_sourceError == error) return; m_sourceError = error; emit sourceErrorChanged(); }

void AsciiRenderer::setDetail(int value)
{
    value = std::clamp(value, 0, 2);
    if (m_detail == value) return;
    m_detail = value;
    const int widths[] = {8, 11, 16};
    const int heights[] = {14, 19, 28};
    m_charWidth = widths[value];
    m_charHeight = heights[value];
    m_atlasDirty = true;
    emit detailChanged();
    rebuildGrid();
}

void AsciiRenderer::geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry)
{
    QQuickItem::geometryChange(newGeometry, oldGeometry);
    resetPointer();
    updateLifecycleState();
    if (newGeometry.size() == oldGeometry.size()) return;
    if (newGeometry.width() <= 0 || newGeometry.height() <= 0) {
        m_columns = m_rows = 0;
        m_heights.clear(); m_velocities.clear();
        m_nextHeights.clear(); m_nextVelocities.clear();
        m_characters.clear(); m_colorIndices.clear(); m_cellDepth.clear();
        m_matrixBrightness.clear(); m_matrixCharacters.clear();
        m_simulationActive = false;
        updateSimulationTimer();
        update();
        return;
    }
    rebuildGrid();
}

void AsciiRenderer::rebuildGrid()
{
    m_columns = std::max(1, int(std::ceil(width() / m_charWidth)) + 1);
    m_rows = std::max(1, int(std::ceil(height() / m_charHeight)) + 1);
    const size_t size = size_t(m_columns * m_rows);
    m_heights.assign(size, 0);
    m_velocities.assign(size, 0);
    m_nextHeights.assign(size, 0);
    m_nextVelocities.assign(size, 0);
    m_characters.assign(size, 0);
    m_colorIndices.assign(size, 0);
    m_cellDepth.assign(size, 0.1);
    m_matrixBrightness.assign(size, 0);
    m_matrixCharacters.assign(size, 1);
    m_simulationActive = false;
    updateSimulationTimer();
    rebuildImage();
    if (m_sourceType == 0 && m_mode == 7)
        updateMatrix3D(1.0 / std::max(5, m_frameRate));
    regenerateCharacters();
}

void AsciiRenderer::rebuildImage()
{
    m_animatedSource = false;
    m_mediaFrame = 0;
    m_imageBrightness.clear();
    m_imageColors.clear();
    m_imageColorIndices.clear();
    if (m_sourceType != 1) {
        m_palette = {m_color, QColor("#ff5555"), QColor("#ffb86c"), QColor("#f1fa8c"), QColor("#50fa7b"), QColor("#8be9fd"), QColor("#bd93f9"), QColor("#ff79c6"), QColor("#0b3d1b"), QColor("#147a35"), QColor("#27c95a"), QColor("#b8ffd0")};
        m_atlasDirty = true;
        return;
    }
    if (m_columns <= 0) return;
    const QString path = m_imageSource.isLocalFile() ? m_imageSource.toLocalFile() : m_imageSource.toString();
    if (!QFileInfo::exists(path)) { setSourceError(tr("File does not exist: %1").arg(path)); return; }
    const QString suffix = QFileInfo(path).suffix().toLower();
    if (suffix == "mp4" || suffix == "webm" || suffix == "mkv" || suffix == "mov" || suffix == "avi" || suffix == "gif") {
        setSourceError(tr("Media playback not supported in this build."));
        return;
    }
    // Static image loading
    {
    }
    QImage image(path);
    if (image.isNull()) {
        qWarning() << "ASCII renderer could not load image" << path;
        setSourceError(tr("Could not decode: %1").arg(path));
        return;
    }
    setSourceError({});
    processImage(image);
}

void AsciiRenderer::processImage(const QImage &input)
{
    if (input.isNull() || m_columns <= 0) return;

    QImage image = input;
    const auto aspect = m_imageFit == 0 ? Qt::IgnoreAspectRatio : (m_imageFit == 1 ? Qt::KeepAspectRatio : Qt::KeepAspectRatioByExpanding);
    image = image.scaled(m_columns, m_rows, aspect, Qt::SmoothTransformation).convertToFormat(QImage::Format_RGBA8888);
    if (image.size() != QSize(m_columns, m_rows)) {
        QImage canvas(m_columns, m_rows, QImage::Format_RGBA8888);
        canvas.fill(Qt::black);
        QPainter painter(&canvas);
        painter.drawImage((m_columns - image.width()) / 2, (m_rows - image.height()) / 2, image);
        image = canvas;
    }
    m_imageBrightness.resize(size_t(m_columns * m_rows));
    m_imageColors.resize(size_t(m_columns * m_rows));
    for (int y = 0; y < m_rows; ++y) {
        for (int x = 0; x < m_columns; ++x) {
            const QColor c = image.pixelColor(x, y);
            m_imageBrightness[size_t(y * m_columns + x)] = (0.2126 * c.red() + 0.7152 * c.green() + 0.0722 * c.blue()) / 255.0;
            m_imageColors[size_t(y * m_columns + x)] = c;
        }
    }
    const std::vector<qreal> baseBrightness = m_imageBrightness;
    static constexpr int bayer[4][4] = {
        {0, 8, 2, 10}, {12, 4, 14, 6}, {3, 11, 1, 9}, {15, 7, 13, 5}
    };
    const qreal rampStep = 1.0 / std::max(2, int(m_ramp.size()));
    for (int y = 0; y < m_rows; ++y) {
        for (int x = 0; x < m_columns; ++x) {
            const size_t index = size_t(y * m_columns + x);
            qreal luminance = baseBrightness[index];
            if (m_edgeEnhancement > 0 && x > 0 && x + 1 < m_columns && y > 0 && y + 1 < m_rows) {
                const qreal neighbors = baseBrightness[index - 1] + baseBrightness[index + 1]
                    + baseBrightness[index - size_t(m_columns)] + baseBrightness[index + size_t(m_columns)];
                luminance += (luminance * 4 - neighbors) * m_edgeEnhancement * 0.35;
            }
            if (m_imageDithering)
                luminance += ((bayer[y & 3][x & 3] + 0.5) / 16.0 - 0.5) * rampStep;
            m_imageBrightness[index] = std::clamp(luminance, 0.0, 1.0);
        }
    }
    ++m_mediaFrame;
    if (m_sourceColor && (!m_animatedSource || m_mediaFrame == 1 || m_mediaFrame % 30 == 0))
        updateAdaptivePalette(m_animatedSource);
    else if (m_sourceColor)
        rebuildImageColorIndices();
    regenerateCharacters();
}

void AsciiRenderer::updateAdaptivePalette(bool animated)
{
    if (m_imageColors.empty()) return;
    const int wanted = std::min<int>(animated ? std::min(m_colorDepth, 32) : m_colorDepth, m_imageColors.size());
    QVector<QColor> centers;
    centers.reserve(wanted);
    for (int i = 0; i < wanted; ++i)
        centers.append(m_imageColors[size_t((qint64(i) * m_imageColors.size()) / wanted)]);

    // A few iterations over the small character grid are enough for stable media palettes.
    for (int iteration = 0; iteration < 5; ++iteration) {
        QVector<qint64> red(wanted), green(wanted), blue(wanted), count(wanted);
        for (const QColor &color : m_imageColors) {
            int best = 0;
            qreal bestDistance = std::numeric_limits<qreal>::max();
            for (int i = 0; i < centers.size(); ++i) {
                const qreal dr = (color.redF() - centers[i].redF()) * 0.55;
                const qreal dg = (color.greenF() - centers[i].greenF()) * 0.75;
                const qreal db = (color.blueF() - centers[i].blueF()) * 0.45;
                const qreal distance = dr * dr + dg * dg + db * db;
                if (distance < bestDistance) { bestDistance = distance; best = i; }
            }
            red[best] += color.red(); green[best] += color.green(); blue[best] += color.blue(); ++count[best];
        }
        for (int i = 0; i < centers.size(); ++i)
            if (count[i]) centers[i] = QColor(int(red[i] / count[i]), int(green[i] / count[i]), int(blue[i] / count[i]));
    }
    m_palette = centers;
    m_atlasDirty = true;
    rebuildImageColorIndices();
}

int AsciiRenderer::nearestPaletteColor(const QColor &color) const
{
    int best = 0;
    qreal bestDistance = std::numeric_limits<qreal>::max();
    for (int i = 0; i < m_palette.size(); ++i) {
        const qreal dr = (color.redF() - m_palette[i].redF()) * 0.55;
        const qreal dg = (color.greenF() - m_palette[i].greenF()) * 0.75;
        const qreal db = (color.blueF() - m_palette[i].blueF()) * 0.45;
        const qreal distance = dr * dr + dg * dg + db * db;
        if (distance < bestDistance) { bestDistance = distance; best = i; }
    }
    return best;
}

void AsciiRenderer::rebuildImageColorIndices()
{
    m_imageColorIndices.resize(m_imageColors.size());
    for (size_t i = 0; i < m_imageColors.size(); ++i)
        m_imageColorIndices[i] = nearestPaletteColor(m_imageColors[i]);
}

qreal AsciiRenderer::hash(int x, int y)
{
    const qreal value = std::sin(x * 127.1 + y * 311.7) * 43758.5453;
    return value - std::floor(value);
}

qreal AsciiRenderer::brightnessAt(int x, int y) const
{
    x = std::clamp(x, 0, m_columns - 1);
    y = std::clamp(y, 0, m_rows - 1);
    if (m_sourceType == 1)
        return m_imageBrightness.size() == m_characters.size() ? m_imageBrightness[size_t(y * m_columns + x)] : 0;
    if (m_mode == 0) {
        const qreal seed = hash(x, y);
        return seed > 0.06 ? 0 : 0.15 + (0.5 + 0.5 * std::sin(m_time * (1.5 + seed * 4) + seed * 30)) * 0.85;
    }
    if (m_mode == 1) {
        return m_matrixBrightness.empty() ? 0 : m_matrixBrightness[size_t(y * m_columns + x)];
    }
    if (m_mode == 7) {
        return m_matrixBrightness.empty() ? 0 : m_matrixBrightness[size_t(y * m_columns + x)];
    }
    const qreal scaledX = x * m_proceduralScale;
    const qreal scaledY = y * m_proceduralScale;
    if (m_mode == 3) {
        const qreal nx = scaledX * 0.19, rise = (m_rows - 1 - scaledY) / qreal(std::max(1, m_rows));
        const qreal flame = std::sin(nx + m_time * 2.1) * 0.18 + std::sin(nx * 0.43 - m_time * 3.2) * 0.14;
        return std::clamp(1.15 - rise * 1.3 + flame + hash(x, int(y + m_time * 8)) * 0.16, 0.0, 1.0);
    }
    if (m_mode == 4) {
        const qreal band = std::sin(scaledX * 0.075 + m_time * 0.7) * 5 + std::sin(scaledX * 0.021 - m_time) * 4;
        const qreal distance = std::abs(scaledY - m_rows * 0.48 - band);
        return std::clamp(1.0 - distance / 10.0, 0.0, 1.0) * (0.65 + 0.35 * std::sin(scaledX * 0.09 + m_time));
    }
    if (m_mode == 5) {
        const qreal nx = scaledX * 0.08, ny = scaledY * 0.1;
        const qreal cloud = std::sin(nx + std::sin(ny + m_time * 0.2)) + std::sin(ny * 1.4 - m_time * 0.25) + std::sin((nx + ny) * 0.55);
        return std::clamp(cloud / 5.0 + 0.48, 0.0, 1.0);
    }
    if (m_mode == 6) {
        const qreal swell = std::sin(scaledX * 0.075 + m_time * 0.8) * 2.8
            + std::sin(scaledX * 0.031 - m_time * 0.45) * 2.0;
        const qreal bands = std::sin(scaledY * 0.42 + swell + m_time * 1.1);
        const qreal shimmer = std::sin(scaledX * 0.17 - scaledY * 0.09 + m_time * 1.7) * 0.18;
        return std::clamp((bands + 1.0) * 0.34 + shimmer, 0.0, 1.0);
    }
    const qreal px = scaledX * 0.12, py = scaledY * 0.12;
    const qreal value = std::sin(px + m_time) + std::sin(py * 1.3 - m_time * 0.7) + std::sin((px + py) * 0.7 + m_time * 0.5);
    return std::clamp(value / 6 + 0.5, 0.0, 1.0);
}

void AsciiRenderer::regenerateCharacters()
{
    if (m_characters.empty()) return;
    QElapsedTimer profileTimer;
    if (m_profilingEnabled) profileTimer.start();
    const qreal cellArea = qreal(m_charWidth * m_charHeight);
    const qreal displacementXScale = cellArea / (m_charWidth * m_charWidth);
    const qreal displacementYScale = cellArea / (m_charHeight * m_charHeight);
    for (int y = 0; y < m_rows; ++y) for (int x = 0; x < m_columns; ++x) {
        const int i = y * m_columns + x;
        const qreal left = x ? m_heights[size_t(i - 1)] : 0;
        const qreal right = x + 1 < m_columns ? m_heights[size_t(i + 1)] : 0;
        const qreal up = y ? m_heights[size_t(i - m_columns)] : 0;
        const qreal down = y + 1 < m_rows ? m_heights[size_t(i + m_columns)] : 0;
        const int sx = qRound(x - (right - left) * displacementXScale * 0.5);
        const int sy = qRound(y - (down - up) * displacementYScale * 0.5);
        const int sampleX = std::clamp(sx, 0, m_columns - 1);
        const int sampleY = std::clamp(sy, 0, m_rows - 1);
        const size_t sampleIndex = size_t(sampleY * m_columns + sampleX);
        qreal brightness = brightnessAt(sx, sy);
        const qreal depth = m_mode == 7 && m_cellDepth.size() == m_characters.size() ? m_cellDepth[sampleIndex] : 1;
        if (m_sourceType == 0 && brightness > 0)
            brightness = std::clamp(brightness * m_proceduralIntensity, 0.0, 1.0);
        const bool preserveProceduralBackground = m_sourceType == 0 && brightness <= 0;
        if (!preserveProceduralBackground && (!qFuzzyIsNull(m_brightness) || !qFuzzyCompare(m_contrast, 1.0) || !qFuzzyCompare(m_gamma, 1.0))) {
            brightness = std::clamp(brightness, 0.0, 1.0);
            brightness = std::pow(brightness, 1.0 / m_gamma);
            brightness = std::clamp((brightness - 0.5) * m_contrast + 0.5 + m_brightness, 0.0, 1.0);
        }
        if (m_sourceType == 0 && m_mode == 1 && brightness > 0) {
            const int sample = std::clamp(sy, 0, m_rows - 1) * m_columns + std::clamp(sx, 0, m_columns - 1);
            m_characters[size_t(i)] = m_matrixCharacters[size_t(sample)];
        } else if (m_sourceType == 0 && m_mode == 7 && brightness > 0) {
            m_characters[size_t(i)] = m_matrixCharacters[sampleIndex];
        } else {
            int character = std::clamp(int(brightness * m_ramp.size()), 0, int(m_ramp.size()) - 1);
            if (m_reverseRamp && character > 0)
                character = int(m_ramp.size()) - character;
            m_characters[size_t(i)] = character;
        }
        int paletteIndex = 0;
        if (m_sourceColor && m_sourceType == 1) {
            if (m_sourceType == 1 && m_imageColorIndices.size() == m_characters.size()) {
                paletteIndex = m_imageColorIndices[size_t(std::clamp(sy, 0, m_rows - 1) * m_columns + std::clamp(sx, 0, m_columns - 1))];
            }
        } else if (m_sourceType == 0 && (m_mode == 1 || m_mode == 7) && !m_customAnimationColor) {
            if (m_mode == 7)
                paletteIndex = brightness > 0.9 ? 11 : depth > 0.76 ? 10 : depth > 0.42 ? 9 : 8;
            else
                paletteIndex = brightness > 0.82 ? 11 : brightness > 0.5 ? 10 : brightness > 0.24 ? 9 : 8;
        } else if (m_sourceType == 0 && !m_customAnimationColor) {
            const int modeColors[] = {5, 4, 6, 2, 4, 6, 5, 4};
            paletteIndex = std::min(modeColors[std::clamp(m_mode, 0, 7)], int(m_palette.size()) - 1);
        }
        m_colorIndices[size_t(i)] = paletteIndex;
    }
    update();
    if (m_profilingEnabled) {
        const quint64 elapsed = quint64(profileTimer.nsecsElapsed());
        m_profile.characterFrames.fetch_add(1, std::memory_order_relaxed);
        recordDuration(m_profile.characterNs, m_profile.characterMaxNs, elapsed);
    }
}

void AsciiRenderer::updateMatrix(qreal deltaTime)
{
    if (m_matrixBrightness.size() != size_t(m_columns * m_rows) || deltaTime <= 0)
        return;
    const int glyphCount = std::max(1, int(m_ramp.size()) - 1);
    const qreal decay = std::pow(0.42, deltaTime);
    const int tick = int(m_time * 10);
    for (int y = 0; y < m_rows; ++y) for (int x = 0; x < m_columns; ++x) {
        const size_t i = size_t(y * m_columns + x);
        if (m_matrixBrightness[i] <= 0) continue;
        m_matrixBrightness[i] *= decay;
        if (m_matrixBrightness[i] < 0.025) { m_matrixBrightness[i] = 0; continue; }
        if (hash(x * 19 + tick, y * 23) < deltaTime * (0.35 + hash(x, y) * 1.4))
            m_matrixCharacters[i] = 1 + int(hash(x + tick * 7, y + tick * 13) * glyphCount) % glyphCount;
    }
    for (int x = 0; x < m_columns; ++x) {
        const qreal seed = hash(x, 7);
        const int gap = 5 + int(seed * 14);
        const int period = m_rows + gap;
        const qreal rawHead = m_time * (4 + seed * 9) + seed * period;
        const int head = int(std::fmod(rawHead, period));
        if (head < 0 || head >= m_rows) continue;
        const size_t i = size_t(head * m_columns + x);
        m_matrixBrightness[i] = 1.0;
        const int generation = int(std::floor(rawHead / period));
        m_matrixCharacters[i] = 1 + int(hash(x + generation * 31, head + tick * 3) * glyphCount) % glyphCount;
    }
}

void AsciiRenderer::updateMatrix3D(qreal deltaTime)
{
    const size_t expected = size_t(m_columns * m_rows);
    if (m_matrixBrightness.size() != expected || m_matrixCharacters.size() != expected
        || m_cellDepth.size() != expected || deltaTime <= 0)
        return;

    const int glyphCount = std::max(1, int(m_ramp.size()) - 1);
    const int tick = int(m_time * 11.0);
    const bool hadActiveState = std::any_of(m_matrixBrightness.cbegin(), m_matrixBrightness.cend(),
        [](qreal brightness) { return brightness > 0.018; });

    // Deposited symbols remain fixed in screen space, cycle independently, and fade by age.
    for (int y = 0; y < m_rows; ++y) for (int x = 0; x < m_columns; ++x) {
        const size_t index = size_t(y * m_columns + x);
        qreal &brightness = m_matrixBrightness[index];
        if (brightness <= 0) continue;
        const qreal depth = m_cellDepth[index];
        brightness *= std::pow(0.22 + depth * 0.24, deltaTime);
        if (brightness < 0.018) {
            brightness = 0;
            m_cellDepth[index] = 0.1;
            continue;
        }
        if (hash(x * 29 + tick, y * 37 + int(depth * 100)) < deltaTime * (0.45 + depth * 2.1))
            m_matrixCharacters[index] = 1 + int(hash(x + tick * 5, y + tick * 13) * glyphCount) % glyphCount;
    }

    const qreal centerX = (m_columns - 1) * 0.5;
    const qreal horizon = m_rows * 0.06;
    for (int layer = 0; layer < 4; ++layer) {
        const qreal depth = 0.16 + layer * 0.27;
        const qreal spacing = (7.2 - layer * 1.28) / m_proceduralScale;
        const int firstLane = int(std::floor(-m_columns * 0.35 / spacing));
        const int lastLane = int(std::ceil(m_columns * 1.35 / spacing));
        for (int lane = firstLane; lane <= lastLane; ++lane) {
            const qreal seed = hash(lane * 17 + layer * 101, layer * 37 + 11);
            if (seed > 0.72 + depth * 0.16) continue;

            const qreal gap = 9 + seed * 24 + (1.0 - depth) * 16;
            const qreal period = m_rows + gap;
            const qreal speed = (4.2 + seed * 12.5) * (0.36 + depth * 1.12);
            const qreal phase = seed * period * 1.9 + layer * 23.0;
            const qreal currentHead = std::fmod(m_time * speed + phase, period);
            const qreal previousHead = std::fmod((m_time - deltaTime) * speed + phase, period);
            if (currentHead < 0 || currentHead >= m_rows) continue;

            int firstY = qRound(currentHead);
            int lastY = firstY;
            const qreal seededTrailLength = (10 + seed * 22) * (0.5 + depth * 0.95);
            if (!hadActiveState) {
                firstY = std::max(0, int(std::floor(currentHead - seededTrailLength)));
                lastY = std::min(m_rows - 1, int(std::ceil(currentHead)));
            } else if (previousHead >= 0 && previousHead < m_rows && previousHead <= currentHead) {
                firstY = std::max(0, int(std::floor(previousHead)));
                lastY = std::min(m_rows - 1, int(std::ceil(currentHead)));
            }
            for (int screenY = firstY; screenY <= lastY; ++screenY) {
                const qreal screenDepth = std::clamp((screenY - horizon) / qreal(std::max(1, m_rows) - horizon), 0.0, 1.0);
                const qreal perspective = 0.2 + screenDepth * (0.42 + depth * 0.46);
                const qreal curve = std::sin(m_time * (0.09 + depth * 0.08) + screenY * 0.018 + layer * 1.9)
                    * (1.8 - depth * 1.15);
                const qreal laneX = lane * spacing;
                const int screenX = qRound(centerX + (laneX - centerX) * perspective + curve * perspective);
                if (screenX < 0 || screenX >= m_columns) continue;

                const size_t index = size_t(screenY * m_columns + screenX);
                const int generation = int(std::floor((m_time * speed + phase) / period));
                const qreal seededBrightness = hadActiveState ? 1.0
                    : std::clamp(1.0 - (currentHead - screenY) / seededTrailLength, 0.0, 1.0)
                        * (0.3 + depth * 0.7);
                if (depth >= m_cellDepth[index] || m_matrixBrightness[index] < 0.7) {
                    m_matrixBrightness[index] = std::max(m_matrixBrightness[index], seededBrightness);
                    m_cellDepth[index] = depth;
                    m_matrixCharacters[index] = 1 + int(hash(lane + generation * 31, screenY + layer * 43) * glyphCount) % glyphCount;
                }

            }
        }
    }
}

void AsciiRenderer::addImpulse(qreal px, qreal py, qreal strength)
{
    if (!m_reactiveEnabled || !m_renderable || m_columns <= 2 || m_rows <= 2) return;
    const qreal cx = px / m_charWidth, cy = py / m_charHeight;
    const qreal unit = std::sqrt(qreal(m_charWidth * m_charHeight));
    const qreal radiusX = m_effectRadius * unit / m_charWidth;
    const qreal radiusY = m_effectRadius * unit / m_charHeight;
    for (int y = std::max(1, int(std::floor(cy - radiusY))); y < std::min(m_rows - 1, int(std::ceil(cy + radiusY))); ++y)
        for (int x = std::max(1, int(std::floor(cx - radiusX))); x < std::min(m_columns - 1, int(std::ceil(cx + radiusX))); ++x) {
            const qreal distance = std::hypot((x - cx) * m_charWidth / unit, (y - cy) * m_charHeight / unit);
            if (distance < m_effectRadius) m_velocities[size_t(y * m_columns + x)] += strength * (1 - distance / m_effectRadius);
        }
    m_simulationActive = true;
    updateSimulationTimer();
}

void AsciiRenderer::movePointer(qreal x, qreal y)
{
    if (m_pointerMovement && m_lastX >= 0) {
        const qreal cellScale = std::sqrt(qreal(m_charWidth * m_charHeight));
        const qreal speed = std::min(3.0, std::hypot(x - m_lastX, y - m_lastY) / cellScale);
        if (speed > 0.15) addImpulse(x, y, m_effectStrength * speed * 0.12);
    }
    m_lastX = x; m_lastY = y;
}

void AsciiRenderer::clickPointer(qreal x, qreal y) { if (m_clickRipple) addImpulse(x, y, m_effectStrength); }
void AsciiRenderer::resetPointer() { m_lastX = m_lastY = -1; }

void AsciiRenderer::stepSimulation()
{
    if (!shouldRunSimulation()) { updateSimulationTimer(); return; }
    const size_t expected = size_t(m_columns * m_rows);
    if (m_heights.size() != expected || m_velocities.size() != expected
        || m_nextHeights.size() != expected || m_nextVelocities.size() != expected) {
        m_simulationActive = false;
        updateSimulationTimer();
        return;
    }
    QElapsedTimer profileTimer;
    if (m_profilingEnabled) profileTimer.start();
    auto &nextV = m_nextVelocities;
    auto &nextH = m_nextHeights;
    qreal energy = 0;
    const qreal inverseWidth = 1.0 / (m_charWidth * m_charWidth);
    const qreal inverseHeight = 1.0 / (m_charHeight * m_charHeight);
    const qreal normalization = 2.0 / (inverseWidth + inverseHeight);
    const qreal horizontalWeight = inverseWidth * normalization;
    const qreal verticalWeight = inverseHeight * normalization;
    const qreal effectiveDamping = 0.82 + std::clamp(m_damping, 0.0, 1.0) * 0.175;
    for (int y = 1; y < m_rows - 1; ++y) for (int x = 1; x < m_columns - 1; ++x) {
        const int i = y * m_columns + x;
        const qreal center = m_heights[size_t(i)];
        const qreal acceleration = horizontalWeight * (m_heights[size_t(i - 1)] + m_heights[size_t(i + 1)] - 2 * center)
            + verticalWeight * (m_heights[size_t(i - m_columns)] + m_heights[size_t(i + m_columns)] - 2 * center);
        nextV[size_t(i)] = (m_velocities[size_t(i)] + acceleration * m_tension) * effectiveDamping;
        nextH[size_t(i)] = m_heights[size_t(i)] + nextV[size_t(i)];
        energy += std::abs(nextV[size_t(i)]) + std::abs(nextH[size_t(i)]) * 0.01;
    }
    m_velocities.swap(m_nextVelocities); m_heights.swap(m_nextHeights);
    m_simulationActive = energy > 0.02;
    if (!m_simulationActive) {
        std::fill(m_velocities.begin(), m_velocities.end(), 0);
        std::fill(m_heights.begin(), m_heights.end(), 0);
        std::fill(m_nextVelocities.begin(), m_nextVelocities.end(), 0);
        std::fill(m_nextHeights.begin(), m_nextHeights.end(), 0);
    }
    updateSimulationTimer();
    if (m_profilingEnabled) {
        const quint64 elapsed = quint64(profileTimer.nsecsElapsed());
        m_profile.simulationSteps.fetch_add(1, std::memory_order_relaxed);
        recordDuration(m_profile.simulationNs, m_profile.simulationMaxNs, elapsed);
    }
    regenerateCharacters();
}

void AsciiRenderer::handleWindowChanged(QQuickWindow *newWindow)
{
    if (m_windowVisibilityConnection) disconnect(m_windowVisibilityConnection);
    resetPointer();
    if (newWindow) {
        m_windowVisibilityConnection = connect(newWindow, &QWindow::visibilityChanged,
            this, &AsciiRenderer::updateLifecycleState);
    }
    updateLifecycleState();
}

void AsciiRenderer::updateLifecycleState()
{
    QQuickWindow *itemWindow = window();
    const bool renderable = isVisible() && width() > 0 && height() > 0 && itemWindow
        && itemWindow->visibility() != QWindow::Hidden
        && itemWindow->visibility() != QWindow::Minimized;
    if (m_renderable == renderable) return;
    m_renderable = renderable;
    if (!renderable) resetPointer();
    updateSimulationTimer();
    if (renderable) update();
}

bool AsciiRenderer::shouldRunSimulation() const
{
    return m_simulationActive && m_reactiveEnabled && m_renderable && m_columns > 2 && m_rows > 2;
}

void AsciiRenderer::updateSimulationTimer()
{
    if (shouldRunSimulation()) {
        if (!m_simulationTimer.isActive()) m_simulationTimer.start();
    } else {
        m_simulationTimer.stop();
    }
}

void AsciiRenderer::recordDuration(std::atomic<quint64> &total, std::atomic<quint64> &maximum, quint64 elapsed)
{
    total.fetch_add(elapsed, std::memory_order_relaxed);
    quint64 previous = maximum.load(std::memory_order_relaxed);
    while (previous < elapsed && !maximum.compare_exchange_weak(previous, elapsed, std::memory_order_relaxed)) {}
}

void AsciiRenderer::reportProfile()
{
    const auto take = [](std::atomic<quint64> &value) { return value.exchange(0, std::memory_order_relaxed); };
    const quint64 characterFrames = take(m_profile.characterFrames);
    const quint64 characterNs = take(m_profile.characterNs);
    const quint64 characterMaxNs = take(m_profile.characterMaxNs);
    const quint64 simulationSteps = take(m_profile.simulationSteps);
    const quint64 simulationNs = take(m_profile.simulationNs);
    const quint64 simulationMaxNs = take(m_profile.simulationMaxNs);
    const quint64 renderFrames = take(m_profile.renderFrames);
    const quint64 renderNs = take(m_profile.renderNs);
    const quint64 renderMaxNs = take(m_profile.renderMaxNs);
    const quint64 atlasBuilds = take(m_profile.atlasBuilds);
    const quint64 atlasNs = take(m_profile.atlasNs);
    const quint64 glyphs = take(m_profile.glyphs);
    const quint64 batches = take(m_profile.batches);
    const auto averageMs = [](quint64 ns, quint64 count) { return count ? double(ns) / count / 1000000.0 : 0.0; };
    qInfo().nospace() << "ASCII profile grid=" << m_columns << 'x' << m_rows
        << " chars=" << characterFrames << " avg/max=" << averageMs(characterNs, characterFrames) << '/' << characterMaxNs / 1000000.0 << "ms"
        << " sim=" << simulationSteps << " avg/max=" << averageMs(simulationNs, simulationSteps) << '/' << simulationMaxNs / 1000000.0 << "ms"
        << " render=" << renderFrames << " avg/max=" << averageMs(renderNs, renderFrames) << '/' << renderMaxNs / 1000000.0 << "ms"
        << " glyphs=" << (renderFrames ? glyphs / renderFrames : 0) << " batches=" << (renderFrames ? batches / renderFrames : 0)
        << " atlases=" << atlasBuilds << " atlasAvg=" << averageMs(atlasNs, atlasBuilds) << "ms";
}

QSGNode *AsciiRenderer::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *)
{
    QElapsedTimer renderTimer;
    if (m_profilingEnabled) renderTimer.start();
    // Guard against null window (systemsettings preview, teardown, etc.)
    if (!window()) {
        delete oldNode;
        return nullptr;
    }
    auto *rootNode = static_cast<RenderRoot *>(oldNode);
    if (!rootNode) rootNode = new RenderRoot;
    const size_t expected = size_t(std::max(0, m_columns) * std::max(0, m_rows));
    if (!expected || m_characters.size() != expected || m_colorIndices.size() != expected) {
        rootNode->hideBatchesFrom(0, false);
        rootNode->hideBatchesFrom(0, true);
        return rootNode;
    }
    if (m_atlasDirty || !rootNode->texture) {
        QElapsedTimer atlasTimer;
        if (m_profilingEnabled) atlasTimer.start();
        QImage atlas(m_charWidth * m_ramp.size(), m_charHeight * m_palette.size(), QImage::Format_ARGB32_Premultiplied);
        QImage glowAtlas(atlas.size(), QImage::Format_ARGB32_Premultiplied);
        atlas.fill(Qt::transparent);
        glowAtlas.fill(Qt::transparent);
        QPainter painter(&atlas);
        QPainter glowPainter(&glowAtlas);
        QFont font(m_fontFamily); font.setStyleHint(QFont::Monospace); font.setPixelSize(std::max(6, int(m_charHeight * 0.8)));
        painter.setFont(font);
        glowPainter.setFont(font);
        for (int p = 0; p < m_palette.size(); ++p) {
            QColor foreground = m_palette[p];
            foreground.setAlphaF(foreground.alphaF() * m_foregroundOpacity);
            for (int i = 0; i < m_ramp.size(); ++i) {
                const QRect cell(i * m_charWidth, p * m_charHeight, m_charWidth, m_charHeight);
                painter.setPen(foreground);
                painter.drawText(cell, Qt::AlignCenter, m_ramp.mid(i, 1));
                QColor glow = foreground;
                glow.setAlphaF(std::min(1.0, m_glowStrength * m_foregroundOpacity * 0.5));
                glowPainter.setPen(glow);
                glowPainter.drawText(cell, Qt::AlignCenter, m_ramp.mid(i, 1));
            }
        }
        painter.end();
        glowPainter.end();
        QSGTexture *newTexture = window()->createTextureFromImage(atlas);
        QSGTexture *newGlowTexture = window()->createTextureFromImage(glowAtlas);
        if (!newTexture || !newGlowTexture) {
            delete newTexture;
            delete newGlowTexture;
            qWarning() << "ASCII renderer failed to create glyph atlas texture" << atlas.size() << window()->rendererInterface()->graphicsApi();
            return rootNode;
        }
        QSGTexture *oldTexture = rootNode->texture;
        QSGTexture *oldGlowTexture = rootNode->glowTexture;
        rootNode->texture = newTexture;
        rootNode->glowTexture = newGlowTexture;
        rootNode->setBatchTextures(newTexture, false);
        rootNode->setBatchTextures(newGlowTexture, true);
        delete oldTexture;
        delete oldGlowTexture;
        qInfo() << "ASCII renderer created glyph atlas" << atlas.size() << "grid" << m_columns << m_rows;
        m_atlasDirty = false;
        if (m_profilingEnabled) {
            m_profile.atlasBuilds.fetch_add(1, std::memory_order_relaxed);
            m_profile.atlasNs.fetch_add(quint64(atlasTimer.nsecsElapsed()), std::memory_order_relaxed);
        }
    }

    quint64 visibleGlyphs = 0;
    const auto emitBatches = [&](bool glow) {
        BatchNode *batch = nullptr;
        QSGGeometry::TexturedPoint2D *vertices = nullptr;
        int batchGlyphs = 0;
        int batchIndex = 0;
        const auto finishBatch = [&]() { if (batch) batch->setGlyphCount(batchGlyphs); };
        const float expansion = glow ? float(m_glowStrength * std::min(m_charWidth, m_charHeight) * 0.38) : 0.0f;
        for (int y = 0; y < m_rows; ++y) for (int x = 0; x < m_columns; ++x) {
            const size_t cellIndex = size_t(y * m_columns + x);
            const int c = m_characters[cellIndex]; if (c <= 0) continue;
            if (!batch || batchGlyphs == MaxGlyphsPerBatch) {
                finishBatch();
                batch = rootNode->batchAt(batchIndex++, glow);
                batch->setTexture(glow ? rootNode->glowTexture : rootNode->texture);
                vertices = batch->geometry.vertexDataAsTexturedPoint2D();
                batchGlyphs = 0;
            }
            const int n = batchGlyphs * 6;
            const float depthScale = m_mode == 7 && m_cellDepth.size() == m_characters.size()
                ? float(std::min(1.0, 0.48 + m_cellDepth[cellIndex] * 0.47
                    + (qreal(y) / std::max(1, m_rows - 1)) * 0.06))
                : 1.0f;
            const float halfWidth = m_charWidth * depthScale * 0.5f + expansion;
            const float halfHeight = m_charHeight * depthScale * 0.5f + expansion;
            const float centerX = (x + 0.5f) * m_charWidth;
            const float centerY = (y + 0.5f) * m_charHeight;
            const float x0 = centerX - halfWidth, y0 = centerY - halfHeight;
            const float x1 = centerX + halfWidth, y1 = centerY + halfHeight;
            const float u0 = float(c) / m_ramp.size(), u1 = float(c + 1) / m_ramp.size();
            const int paletteIndex = m_colorIndices[cellIndex];
            const float v0 = float(paletteIndex) / m_palette.size(), v1 = float(paletteIndex + 1) / m_palette.size();
            vertices[n].set(x0,y0,u0,v0); vertices[n+1].set(x1,y0,u1,v0); vertices[n+2].set(x0,y1,u0,v1);
            vertices[n+3].set(x0,y1,u0,v1); vertices[n+4].set(x1,y0,u1,v0); vertices[n+5].set(x1,y1,u1,v1);
            ++batchGlyphs;
            if (!glow) ++visibleGlyphs;
        }
        finishBatch();
        rootNode->hideBatchesFrom(batchIndex, glow);
        return batchIndex;
    };
    const int glowBatchCount = m_glowStrength > 0 ? emitBatches(true) : 0;
    if (m_glowStrength <= 0) rootNode->hideBatchesFrom(0, true);
    const int batchIndex = emitBatches(false);
    if (m_profilingEnabled) {
        const quint64 elapsed = quint64(renderTimer.nsecsElapsed());
        m_profile.renderFrames.fetch_add(1, std::memory_order_relaxed);
        m_profile.glyphs.fetch_add(visibleGlyphs, std::memory_order_relaxed);
        m_profile.batches.fetch_add(quint64(batchIndex + glowBatchCount), std::memory_order_relaxed);
        recordDuration(m_profile.renderNs, m_profile.renderMaxNs, elapsed);
    }
    return rootNode;
}
