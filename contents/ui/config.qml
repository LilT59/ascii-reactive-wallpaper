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
    property alias cfg_ReactiveEnabled: reactiveCheck.checked
    property alias cfg_PointerMovement: movementCheck.checked
    property alias cfg_ClickRipple: clickCheck.checked
    property alias cfg_EffectRadius: radiusSlider.value
    property alias cfg_EffectStrength: strengthSlider.value
    property alias cfg_Tension: tensionSlider.value
    property alias cfg_Damping: dampingSlider.value
    property alias formLayout: root

    QQC2.ComboBox {
        id: modeBox
        Kirigami.FormData.label: i18n("Animation:")
        model: [i18n("Starfield"), i18n("Matrix rain"), i18n("Plasma"), i18n("Fire"), i18n("Aurora"), i18n("Nebula")]
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

    QQC2.SpinBox {
        id: depthSpin
        Kirigami.FormData.label: i18n("Color depth:")
        from: 4
        to: 64
        editable: true
        textFromValue: value => value + " colors"
        valueFromText: text => parseInt(text)
    }

    QQC2.Slider {
        id: speedSlider
        Kirigami.FormData.label: i18n("Speed:")
        from: 0.1
        to: 3.0
        stepSize: 0.1
    }

    QQC2.Label {
        text: Number(speedSlider.value).toFixed(1) + "x"
    }

    QQC2.SpinBox {
        id: fpsSpin
        Kirigami.FormData.label: i18n("Frame rate:")
        from: 5
        to: 60
        editable: true
        textFromValue: value => value + " FPS"
        valueFromText: text => parseInt(text)
    }

    KQuickControls.ColorButton {
        id: colorButton
        Kirigami.FormData.label: i18n("Color:")
        dialogTitle: i18n("Select ASCII color")
    }

    QQC2.CheckBox {
        id: customAnimationColorCheck
        text: i18n("Use selected color for procedural animations")
    }

    QQC2.ComboBox {
        id: sourceBox
        Kirigami.FormData.label: i18n("Source:")
        model: [i18n("Procedural"), i18n("Image")]
    }

    QQC2.TextField {
        id: imagePath
        Kirigami.FormData.label: i18n("Image file:")
        enabled: sourceBox.currentIndex === 1
        placeholderText: i18n("/home/user/Pictures/image.png")
    }

    QQC2.Button {
        text: i18n("Browse...")
        enabled: sourceBox.currentIndex === 1
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
        enabled: sourceBox.currentIndex === 1
        model: [i18n("Stretch"), i18n("Fit"), i18n("Crop")]
    }

    QQC2.CheckBox {
        id: sourceColorCheck
        Kirigami.FormData.label: i18n("ASCII color:")
        text: i18n("Use source colors")
    }

    QQC2.Label {
        visible: sourceBox.currentIndex === 1 && imagePath.text.length === 0
        text: i18n("Select a readable local image file.")
        color: Kirigami.Theme.negativeTextColor
        wrapMode: Text.Wrap
    }

    QQC2.TextField {
        id: rampField
        Kirigami.FormData.label: i18n("Character ramp:")
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

    QQC2.Slider {
        id: strengthSlider
        Kirigami.FormData.label: i18n("Effect strength:")
        from: 0.1
        to: 5.0
        stepSize: 0.1
        enabled: reactiveCheck.checked
    }

    QQC2.Slider {
        id: tensionSlider
        Kirigami.FormData.label: i18n("Tension:")
        from: 0.01
        to: 0.5
        stepSize: 0.01
        enabled: reactiveCheck.checked
    }

    QQC2.Slider {
        id: dampingSlider
        Kirigami.FormData.label: i18n("Damping:")
        from: 0.5
        to: 0.99
        stepSize: 0.01
        enabled: reactiveCheck.checked
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
            reactiveCheck.checked = true
            movementCheck.checked = true
            clickCheck.checked = true
            radiusSlider.value = 6
            strengthSlider.value = 1.5
            tensionSlider.value = 0.18
            dampingSlider.value = 0.92
        }
    }
}
