import QtQuick

Item {
    id: root
    clip: true

    property real time: 0.0
    property int mode: 0
    property int detail: 1
    property color primaryColor: "#7fdbff"
    property int sourceType: 0
    property url imageSource
    property string characterRamp: " .:-=+*#%@"
    property bool reactiveEnabled: true
    property bool pointerMovement: true
    property bool clickRipple: true
    property int effectRadius: 6
    property real effectStrength: 1.5
    property real tension: 0.18
    property real damping: 0.92

    readonly property int safeDetail: Math.max(0, Math.min(2, detail))
    readonly property int charWidth: [8, 11, 16][safeDetail]
    readonly property int charHeight: [14, 19, 28][safeDetail]
    readonly property string characters: characterRamp.length > 1 ? characterRamp : " .:-=+*#%@"
    readonly property int columns: Math.ceil(width / charWidth) + 1
    readonly property int rows: Math.ceil(height / charHeight) + 1
    property var heights: []
    property var velocities: []
    property var imageBrightness: []
    property real lastPointerX: -1
    property real lastPointerY: -1
    property bool simulationActive: false
    property int frameRevision: 0

    function resetGrid() {
        const size = columns * rows;
        heights = new Array(size).fill(0);
        velocities = new Array(size).fill(0);
        simulationActive = false;
        if (sourceType === 1)
            imageCanvas.requestPaint();
        ++frameRevision;
    }

    function addImpulse(pixelX, pixelY, strength) {
        const centerX = pixelX / charWidth;
        const centerY = pixelY / charHeight;
        for (let y = Math.max(1, Math.floor(centerY - effectRadius));
             y < Math.min(rows - 1, Math.ceil(centerY + effectRadius)); ++y) {
            for (let x = Math.max(1, Math.floor(centerX - effectRadius));
                 x < Math.min(columns - 1, Math.ceil(centerX + effectRadius)); ++x) {
                const distance = Math.hypot(x - centerX, y - centerY);
                if (distance < effectRadius)
                    velocities[y * columns + x] += strength * (1 - distance / effectRadius);
            }
        }
        simulationActive = true;
    }

    function movePointer(x, y) {
        if (pointerMovement && lastPointerX >= 0) {
            const speed = Math.min(3, Math.hypot(x - lastPointerX, y - lastPointerY) / charWidth);
            if (speed > 0.15)
                addImpulse(x, y, effectStrength * speed * 0.12);
        }
        lastPointerX = x;
        lastPointerY = y;
    }

    function resetPointer() {
        lastPointerX = -1;
        lastPointerY = -1;
    }

    function clickPointer(x, y) {
        if (clickRipple)
            addImpulse(x, y, effectStrength);
    }

    function stepSimulation() {
        if (!simulationActive || heights.length !== columns * rows)
            return;
        const nextVelocity = velocities.slice();
        const nextHeight = heights.slice();
        let energy = 0;
        for (let y = 1; y < rows - 1; ++y) {
            for (let x = 1; x < columns - 1; ++x) {
                const i = y * columns + x;
                const acceleration = heights[i - 1] + heights[i + 1]
                                   + heights[i - columns] + heights[i + columns]
                                   - 4 * heights[i];
                nextVelocity[i] = (velocities[i] + acceleration * tension) * damping;
                nextHeight[i] = heights[i] + nextVelocity[i];
                energy += Math.abs(nextVelocity[i]) + Math.abs(nextHeight[i]) * 0.01;
            }
        }
        velocities = nextVelocity;
        heights = nextHeight;
        simulationActive = energy > 0.02;
        ++frameRevision;
    }

    function hash(x, y) {
        const value = Math.sin(x * 127.1 + y * 311.7) * 43758.5453;
        return value - Math.floor(value);
    }

    function brightnessAt(column, row) {
        const x = Math.max(0, Math.min(columns - 1, column));
        const y = Math.max(0, Math.min(rows - 1, row));
        if (sourceType === 1)
            return imageBrightness[y * columns + x] || 0;
        if (mode === 0) {
            const seed = hash(x, y);
            if (seed > 0.06)
                return 0;
            return 0.15 + (0.5 + 0.5 * Math.sin(time * (1.5 + seed * 4) + seed * 30)) * 0.85;
        }
        if (mode === 1) {
            const seed = hash(x, 7);
            const period = 18 + Math.floor(seed * 15);
            const head = (time * (4 + seed * 9) + seed * 80) % period;
            let distance = head - y;
            if (distance < 0)
                distance += period;
            return Math.max(0, Math.min(1, 1 - distance / 10));
        }
        const px = x * 0.12;
        const py = y * 0.12;
        const value = Math.sin(px + time) + Math.sin(py * 1.3 - time * 0.7)
                    + Math.sin((px + py) * 0.7 + time * 0.5);
        return Math.max(0, Math.min(1, value / 6 + 0.5));
    }

    function line(row) {
        const revision = frameRevision;
        let output = "";
        for (let column = 0; column < columns; ++column) {
            const i = row * columns + column;
            const left = column > 0 ? heights[i - 1] : 0;
            const right = column < columns - 1 ? heights[i + 1] : 0;
            const up = row > 0 ? heights[i - columns] : 0;
            const down = row < rows - 1 ? heights[i + columns] : 0;
            const sampleX = Math.round(column - (right - left) * 0.5);
            const sampleY = Math.round(row - (down - up) * 0.5);
            const brightness = brightnessAt(sampleX, sampleY);
            const index = Math.max(0, Math.min(characters.length - 1,
                                               Math.floor(brightness * characters.length)));
            output += characters.charAt(index);
        }
        return output;
    }

    onColumnsChanged: resetGrid()
    onRowsChanged: resetGrid()
    onImageSourceChanged: imageCanvas.requestPaint()
    onSourceTypeChanged: imageCanvas.requestPaint()
    Component.onCompleted: resetGrid()

    Image {
        id: sourceImage
        visible: false
        source: root.imageSource
        asynchronous: true
        onStatusChanged: if (status === Image.Ready) imageCanvas.requestPaint()
    }

    Canvas {
        id: imageCanvas
        visible: false
        width: root.columns
        height: root.rows
        renderTarget: Canvas.Image
        onPaint: {
            if (root.sourceType !== 1 || sourceImage.status !== Image.Ready)
                return;
            const context = getContext("2d");
            context.clearRect(0, 0, width, height);
            context.drawImage(sourceImage, 0, 0, width, height);
            const pixels = context.getImageData(0, 0, width, height).data;
            const values = new Array(width * height);
            for (let i = 0; i < values.length; ++i) {
                const p = i * 4;
                values[i] = (0.2126 * pixels[p] + 0.7152 * pixels[p + 1]
                           + 0.0722 * pixels[p + 2]) / 255;
            }
            root.imageBrightness = values;
            ++root.frameRevision;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#020307"
    }

    Repeater {
        model: root.rows
        delegate: Text {
            required property int index
            y: index * root.charHeight
            color: root.primaryColor
            text: {
                root.time;
                root.frameRevision;
                return root.line(index);
            }
            font.family: "DejaVu Sans Mono"
            font.pixelSize: root.charHeight
            font.hintingPreference: Font.PreferNoHinting
            renderType: Text.QtRendering
        }
    }

    Timer {
        interval: 100
        repeat: true
        running: root.visible && root.reactiveEnabled && root.simulationActive
        onTriggered: root.stepSimulation()
    }
}
