import QtQuick
import org.kde.plasma.plasmoid
import "native" as Native

WallpaperItem {
    id: root

    property real animationTime: 0.0
    property var previousSettings: null
    property var transitionRenderer: null
    property bool transitionReady: false
    property string previousTransitionSignature: ""
    readonly property bool batteryPaused: root.configuration.PauseOnBattery && Native.PointerTracker.onBattery
    readonly property var rampPresets: [" .:-=+*#%@", " ░▒▓█", " .oO@", " .'`^\",:;Il!i><~+_-?][}{1)(|\\/*tfjrxnuvczXYUJCLQ0OZmwqpdbkhao*#MW&8%B@$", " ▁▂▃▄▅▆▇█", " ⠁⠃⠇⡇⣇⣧⣷⣿", " ·◦○◉●", " 01"]
    readonly property string settingsKey: JSON.stringify(captureSettings())

    function transitionSignature(settings) {
        return JSON.stringify({
            mode: settings.mode, characterSize: settings.characterSize,
            sourceType: settings.sourceType, imageSource: settings.imageSource,
            imageFit: settings.imageFit, sourceColor: settings.sourceColor,
            characterRamp: settings.characterRamp, fontFamily: settings.fontFamily
        });
    }

    function captureSettings() {
        const c = root.configuration;
        return {
            mode: c.Mode, characterSize: c.CharacterSize, colorDepth: c.ColorDepth,
            frameRate: c.FrameRate, primaryColor: c.Color, sourceType: c.SourceType,
            imageSource: c.ImagePath, imageFit: c.ImageFit, sourceColor: c.SourceColor,
            customAnimationColor: c.CustomAnimationColor,
            characterRamp: c.RampPreset > 0 ? root.rampPresets[c.RampPreset - 1].slice(0, 64) : c.CharacterRamp,
            brightness: c.Brightness, contrast: c.Contrast, gamma: c.Gamma,
            characterSpacing: c.CharacterSpacing, reverseRamp: c.ReverseRamp,
            imageDithering: c.ImageDithering, edgeEnhancement: c.EdgeEnhancement,
            fontFamily: c.FontFamily, foregroundOpacity: c.ForegroundOpacity,
            glowStrength: c.GlowStrength, proceduralScale: c.ProceduralScale,
            proceduralIntensity: c.ProceduralIntensity, reactiveEnabled: false
        };
    }

    function startTransition(settings) {
        if (!settings || !root.visible || width <= 0 || height <= 0)
            return;
        if (transitionRenderer) {
            transitionRenderer.destroy();
            transitionRenderer = null;
        }
        const properties = Object.assign({}, settings, {
            width: root.width, height: root.height, time: root.animationTime,
            z: renderer.z + 1, opacity: 1.0
        });
        transitionRenderer = transitionComponent.createObject(root, properties);
        renderer.opacity = 0.0;
        rendererFade.restart();
        transitionFade.restart();
    }

    onSettingsKeyChanged: {
        const current = captureSettings();
        const signature = transitionSignature(current);
        if (transitionReady && signature !== previousTransitionSignature)
            startTransition(previousSettings);
        previousSettings = current;
        previousTransitionSignature = signature;
    }

    Timer {
        interval: Math.round(1000 / Math.max(5, root.configuration.FrameRate))
        repeat: true
        running: root.visible && !root.batteryPaused
        onTriggered: root.animationTime += interval * 0.001 * root.configuration.Speed
    }

    Rectangle {
        anchors.fill: parent
        color: root.configuration.BackgroundColor
    }

    Native.AsciiRenderer {
        id: renderer
        anchors.fill: parent
        time: root.animationTime
        mode: root.configuration.Mode
        characterSize: root.configuration.CharacterSize
        colorDepth: root.configuration.ColorDepth
        frameRate: root.configuration.FrameRate
        primaryColor: root.configuration.Color
        sourceType: root.configuration.SourceType
        imageSource: root.configuration.ImagePath
        imageFit: root.configuration.ImageFit
        sourceColor: root.configuration.SourceColor
        customAnimationColor: root.configuration.CustomAnimationColor
        characterRamp: root.configuration.RampPreset > 0
            ? root.rampPresets[root.configuration.RampPreset - 1].slice(0, 64)
            : root.configuration.CharacterRamp
        brightness: root.configuration.Brightness
        contrast: root.configuration.Contrast
        gamma: root.configuration.Gamma
        characterSpacing: root.configuration.CharacterSpacing
        reverseRamp: root.configuration.ReverseRamp
        imageDithering: root.configuration.ImageDithering
        edgeEnhancement: root.configuration.EdgeEnhancement
        fontFamily: root.configuration.FontFamily
        foregroundOpacity: root.configuration.ForegroundOpacity
        glowStrength: root.configuration.GlowStrength
        proceduralScale: root.configuration.ProceduralScale
        proceduralIntensity: root.configuration.ProceduralIntensity
        reactiveEnabled: root.configuration.ReactiveEnabled && !root.batteryPaused
        pointerMovement: root.configuration.PointerMovement
        clickRipple: root.configuration.ClickRipple
        effectRadius: root.configuration.EffectRadius
        effectStrength: root.configuration.EffectStrength
        waveSpeed: root.configuration.WaveSpeed
        tension: root.configuration.Tension
        damping: root.configuration.Damping
    }

    Component {
        id: transitionComponent
        Native.AsciiRenderer { }
    }

    NumberAnimation {
        id: rendererFade
        target: renderer
        property: "opacity"
        from: 0.0
        to: 1.0
        duration: 250
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: transitionFade
        target: root.transitionRenderer
        property: "opacity"
        from: 1.0
        to: 0.0
        duration: 250
        easing.type: Easing.OutCubic
        onFinished: {
            if (root.transitionRenderer) {
                root.transitionRenderer.destroy();
                root.transitionRenderer = null;
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: renderer.sourceError.length > 0
        text: renderer.sourceError
        color: "#ff6b6b"
        font.pixelSize: 16
        wrapMode: Text.Wrap
        width: Math.min(parent.width - 40, 720)
        horizontalAlignment: Text.AlignHCenter
    }

    Connections {
        target: Native.PointerTracker

        function onGlobalPositionChanged() {
            if (!renderer || !renderer.reactiveEnabled || root.batteryPaused)
                return;
            const local = root.mapFromGlobal(Native.PointerTracker.globalPosition);
            if (local.x >= 0 && local.y >= 0 && local.x < root.width && local.y < root.height)
                renderer.movePointer(local.x, local.y);
            else
                renderer.resetPointer();
        }

        function onPressed(x, y, button) {
            if (!renderer || !renderer.reactiveEnabled || root.batteryPaused)
                return;
            const local = root.mapFromGlobal(x, y);
            if (local.x >= 0 && local.y >= 0 && local.x < root.width && local.y < root.height)
                renderer.clickPointer(local.x, local.y);
        }
    }

    Component.onCompleted: {
        previousSettings = captureSettings();
        previousTransitionSignature = transitionSignature(previousSettings);
        transitionReady = true;
        root.loading = false;
    }
}
