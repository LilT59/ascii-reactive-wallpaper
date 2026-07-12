import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQuickControls
import QtQuick.Dialogs

Kirigami.FormLayout {
    id: root

    twinFormLayouts: parentLayout

    property var configDialog
    property var wallpaperConfiguration
    property alias cfg_Mode: modeBox.currentIndex
    property alias cfg_CharacterSize: sizeSpin.value
    property alias cfg_ColorDepth: depthSpin.value
    property alias cfg_Speed: speedSlider.value
    property alias cfg_FrameRate: fpsSpin.value
    property alias cfg_Color: colorButton.color
    property alias cfg_SourceType: sourceBox.currentIndex
    property alias cfg_ImagePath: imagePath.text
    property alias cfg_ImageFit: fitBox.currentIndex
    property alias cfg_SourceColor: sourceColorCheck.checked
    property alias cfg_CustomAnimationColor: customAnimationColorCheck.checked
    property alias cfg_CharacterRamp: rampField.text
    property alias cfg_RampPreset: rampPresetBox.currentIndex
    property alias cfg_BackgroundColor: backgroundColorButton.color
    property alias cfg_Brightness: brightnessSlider.value
    property alias cfg_Contrast: contrastSlider.value
    property alias cfg_Gamma: gammaSlider.value
    property alias cfg_CharacterSpacing: spacingSlider.value
    property alias cfg_ReverseRamp: reverseRampCheck.checked
    property alias cfg_ReactiveEnabled: reactiveCheck.checked
    property alias cfg_PointerMovement: movementCheck.checked
    property alias cfg_ClickRipple: clickCheck.checked
    property alias cfg_EffectRadius: radiusSlider.value
    property alias cfg_EffectStrength: strengthSlider.value
    property alias cfg_WaveSpeed: waveSpeedSlider.value
    property alias cfg_Tension: tensionSlider.value
    property alias cfg_Damping: dampingSlider.value
    property alias formLayout: root

    Kirigami.Heading {
        Kirigami.FormData.isSection: true
        level: 2
        text: i18n("Source")
    }

    QQC2.ComboBox {
        id: sourceBox
        Kirigami.FormData.label: i18n("Source:")
        model: [i18n("Procedural"), i18n("Image")]
    }

    QQC2.ComboBox {
        id: modeBox
        Kirigami.FormData.label: i18n("Animation:")
        model: [i18n("Starfield"), i18n("Matrix rain"), i18n("Plasma"), i18n("Fire"), i18n("Aurora"), i18n("Nebula"), i18n("Ocean waves")]
        visible: sourceBox.currentIndex === 0
    }

    QQC2.TextField {
        id: imagePath
        Kirigami.FormData.label: i18n("Image file:")
        visible: sourceBox.currentIndex === 1
        placeholderText: i18n("/home/user/Pictures/image.png")
    }

    QQC2.Button {
        text: i18n("Browse...")
        visible: sourceBox.currentIndex === 1
        onClicked: imageDialog.open()
    }

    FileDialog {
        id: imageDialog
        title: i18n("Select image")
        nameFilters: [i18n("Images (*.png *.jpg *.jpeg *.webp *.bmp)"), i18n("All files (*)")]
        onAccepted: imagePath.text = selectedFile
    }

    QQC2.ComboBox {
        id: fitBox
        Kirigami.FormData.label: i18n("Image fit:")
        visible: sourceBox.currentIndex === 1
        model: [i18n("Stretch"), i18n("Fit"), i18n("Crop")]
    }

    QQC2.CheckBox {
        id: sourceColorCheck
        Kirigami.FormData.label: i18n("ASCII color:")
        text: i18n("Use source colors")
        visible: sourceBox.currentIndex === 1
    }

    QQC2.Label {
        visible: sourceBox.currentIndex === 1 && imagePath.text.length === 0
        text: i18n("Select a readable local image file.")
        color: Kirigami.Theme.negativeTextColor
        wrapMode: Text.Wrap
    }

    Kirigami.Heading {
        Kirigami.FormData.isSection: true
        level: 2
        text: i18n("Appearance")
    }

    QQC2.SpinBox {
        id: sizeSpin
        Kirigami.FormData.label: i18n("Character size:")
        from: 8
        to: 48
        editable: true
        textFromValue: value => value + " px"
        valueFromText: text => parseInt(text)
    }

    QQC2.Slider {
        id: spacingSlider
        Kirigami.FormData.label: i18n("Horizontal spacing:")
        from: 0.5
        to: 2.0
        stepSize: 0.05
    }

    QQC2.Label { text: Number(spacingSlider.value).toFixed(2) + "x" }

    QQC2.ComboBox {
        id: rampPresetBox
        Kirigami.FormData.label: i18n("Ramp preset:")
        model: [i18n("Custom"), i18n("Classic"), i18n("Blocks"), i18n("Compact"), i18n("Detailed"), i18n("Vertical blocks"), i18n("Braille density"), i18n("Circles"), i18n("Binary")]
    }

    QQC2.TextField {
        id: rampField
        Kirigami.FormData.label: i18n("Custom ramp:")
        maximumLength: 64
        enabled: rampPresetBox.currentIndex === 0
        placeholderText: i18n("Start with a space, then light to dense")
    }

    QQC2.TextField {
        Kirigami.FormData.label: i18n("Preset characters:")
        visible: rampPresetBox.currentIndex > 0
        text: ["", " .:-=+*#%@", " ░▒▓█", " .oO@", " .'`^\",:;Il!i><~+_-?][}{1)(|\\/*tfjrxnuvczXYUJCLQ0OZmwqpdbkhao*#MW&8%B@$", " ▁▂▃▄▅▆▇█", " ⠁⠃⠇⡇⣇⣧⣷⣿", " ·◦○◉●", " 01"][rampPresetBox.currentIndex]
        readOnly: true
        selectByMouse: true
    }

    QQC2.CheckBox {
        id: reverseRampCheck
        text: i18n("Reverse non-blank character order")
    }

    QQC2.ComboBox {
        Kirigami.FormData.label: i18n("Color preset:")
        model: [i18n("Custom"), i18n("Cyan"), i18n("Amber"), i18n("Matrix green"), i18n("White")]
        onActivated: index => {
            const colors = [colorButton.color, "#7fdbff", "#ffb347", "#50fa7b", "#f8f8f2"]
            if (index > 0) {
                colorButton.color = colors[index]
                customAnimationColorCheck.checked = true
            }
        }
    }

    KQuickControls.ColorButton {
        id: colorButton
        Kirigami.FormData.label: i18n("ASCII color:")
        dialogTitle: i18n("Select ASCII color")
    }

    KQuickControls.ColorButton {
        id: backgroundColorButton
        Kirigami.FormData.label: i18n("Background:")
        dialogTitle: i18n("Select background color")
    }

    QQC2.CheckBox {
        id: customAnimationColorCheck
        text: i18n("Use selected color for procedural animations")
        visible: sourceBox.currentIndex === 0
    }

    QQC2.SpinBox {
        id: depthSpin
        Kirigami.FormData.label: i18n("Color depth:")
        from: 4
        to: 64
        editable: true
        visible: sourceBox.currentIndex === 1 && sourceColorCheck.checked
        textFromValue: value => value + " colors"
        valueFromText: text => parseInt(text)
    }

    QQC2.Slider {
        id: brightnessSlider
        Kirigami.FormData.label: i18n("Brightness:")
        from: -1.0
        to: 1.0
        stepSize: 0.05
    }

    QQC2.Label { text: Number(brightnessSlider.value).toFixed(2) }

    QQC2.Slider {
        id: contrastSlider
        Kirigami.FormData.label: i18n("Contrast:")
        from: 0.0
        to: 2.0
        stepSize: 0.05
    }

    QQC2.Label { text: Number(contrastSlider.value).toFixed(2) }

    QQC2.Slider {
        id: gammaSlider
        Kirigami.FormData.label: i18n("Gamma:")
        from: 0.1
        to: 3.0
        stepSize: 0.05
    }

    QQC2.Label { text: Number(gammaSlider.value).toFixed(2) }

    Kirigami.Heading {
        Kirigami.FormData.isSection: true
        level: 2
        text: i18n("Animation")
    }

    QQC2.Slider {
        id: speedSlider
        Kirigami.FormData.label: i18n("Speed:")
        from: 0.1
        to: 3.0
        stepSize: 0.1
        enabled: sourceBox.currentIndex === 0
    }

    QQC2.Label { text: Number(speedSlider.value).toFixed(1) + "x" }

    QQC2.SpinBox {
        id: fpsSpin
        Kirigami.FormData.label: i18n("Frame rate:")
        from: 5
        to: 60
        editable: true
        textFromValue: value => value + " FPS"
        valueFromText: text => parseInt(text)
    }

    Kirigami.Heading {
        Kirigami.FormData.isSection: true
        level: 2
        text: i18n("Reactivity")
    }

    QQC2.CheckBox {
        id: reactiveCheck
        Kirigami.FormData.label: i18n("Reactivity:")
        text: i18n("Enabled")
    }

    QQC2.CheckBox {
        id: movementCheck
        text: i18n("Pointer movement")
        enabled: reactiveCheck.checked
    }

    QQC2.CheckBox {
        id: clickCheck
        text: i18n("Click ripples")
        enabled: reactiveCheck.checked
    }

    QQC2.Slider {
        id: radiusSlider
        Kirigami.FormData.label: i18n("Effect radius:")
        from: 2
        to: 20
        stepSize: 1
        enabled: reactiveCheck.checked
    }

    QQC2.Label { text: radiusSlider.value + " cells"; enabled: reactiveCheck.checked }

    QQC2.Slider {
        id: strengthSlider
        Kirigami.FormData.label: i18n("Effect strength:")
        from: 0.1
        to: 5.0
        stepSize: 0.1
        enabled: reactiveCheck.checked
    }

    QQC2.Label { text: Number(strengthSlider.value).toFixed(1); enabled: reactiveCheck.checked }

    QQC2.Slider {
        id: waveSpeedSlider
        Kirigami.FormData.label: i18n("Wave speed:")
        from: 0.5
        to: 2.0
        stepSize: 0.1
        enabled: reactiveCheck.checked
    }

    QQC2.Label { text: Number(waveSpeedSlider.value).toFixed(1) + "x"; enabled: reactiveCheck.checked }

    QQC2.Slider {
        id: tensionSlider
        Kirigami.FormData.label: i18n("Tension:")
        from: 0.01
        to: 0.5
        stepSize: 0.01
        enabled: reactiveCheck.checked
    }

    QQC2.Label { text: Number(tensionSlider.value).toFixed(2); enabled: reactiveCheck.checked }

    QQC2.Slider {
        id: dampingSlider
        Kirigami.FormData.label: i18n("Wave persistence:")
        from: 0.0
        to: 1.0
        stepSize: 0.05
        enabled: reactiveCheck.checked
    }

    QQC2.Label { text: Math.round(dampingSlider.value * 100) + "%"; enabled: reactiveCheck.checked }

    Kirigami.Heading {
        Kirigami.FormData.isSection: true
        level: 2
        text: i18n("Defaults")
    }

    QQC2.Button {
        Kirigami.FormData.label: i18n("Settings:")
        text: i18n("Reset to defaults")
        onClicked: {
            modeBox.currentIndex = 0
            sizeSpin.value = 19
            depthSpin.value = 32
            speedSlider.value = 1.0
            fpsSpin.value = 24
            colorButton.color = "#7fdbff"
            sourceBox.currentIndex = 0
            imagePath.text = ""
            fitBox.currentIndex = 1
            sourceColorCheck.checked = false
            customAnimationColorCheck.checked = false
            rampField.text = " .:-=+*#%@"
            rampPresetBox.currentIndex = 0
            backgroundColorButton.color = "#020307"
            brightnessSlider.value = 0.05
            contrastSlider.value = 1.0
            gammaSlider.value = 1.0
            spacingSlider.value = 1.0
            reverseRampCheck.checked = false
            reactiveCheck.checked = true
            movementCheck.checked = true
            clickCheck.checked = true
            radiusSlider.value = 6
            strengthSlider.value = 1.5
            waveSpeedSlider.value = 1.5
            tensionSlider.value = 0.18
            dampingSlider.value = 0.65
        }
    }
}
