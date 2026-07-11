import QtQuick
import org.kde.plasma.plasmoid
import "native" as Native

WallpaperItem {
    id: root

    property real animationTime: 0.0

    Timer {
        interval: Math.round(1000 / Math.max(5, root.configuration.FrameRate))
        repeat: true
        running: root.visible
        onTriggered: root.animationTime += interval * 0.001 * root.configuration.Speed
    }

    Rectangle {
        anchors.fill: parent
        color: "#020307"
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
        characterRamp: root.configuration.CharacterRamp
        reactiveEnabled: root.configuration.ReactiveEnabled
        pointerMovement: root.configuration.PointerMovement
        clickRipple: root.configuration.ClickRipple
        effectRadius: root.configuration.EffectRadius
        effectStrength: root.configuration.EffectStrength
        tension: root.configuration.Tension
        damping: root.configuration.Damping
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
            if (!renderer.reactiveEnabled)
                return;
            const local = root.mapFromGlobal(Native.PointerTracker.globalPosition);
            if (local.x >= 0 && local.y >= 0 && local.x < root.width && local.y < root.height)
                renderer.movePointer(local.x, local.y);
            else
                renderer.resetPointer();
        }

        function onPressed(globalPosition, button) {
            if (!renderer.reactiveEnabled)
                return;
            const local = root.mapFromGlobal(globalPosition);
            if (local.x >= 0 && local.y >= 0 && local.x < root.width && local.y < root.height)
                renderer.clickPointer(local.x, local.y);
        }
    }

    Component.onCompleted: root.loading = false
}
