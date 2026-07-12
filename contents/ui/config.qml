import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQuickControls
import QtQuick.Dialogs
import "native" as Native

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
    property alias cfg_ImageDithering: ditheringCheck.checked
    property alias cfg_EdgeEnhancement: edgeSlider.value
    property alias cfg_FontFamily: fontStorage.text
    property alias cfg_ForegroundOpacity: opacitySlider.value
    property alias cfg_GlowStrength: glowSlider.value
    property alias cfg_ProceduralScale: proceduralScaleSlider.value
    property alias cfg_ProceduralIntensity: proceduralIntensitySlider.value
    property alias cfg_PauseOnBattery: pauseOnBatteryCheck.checked
    property alias cfg_ReactiveEnabled: reactiveCheck.checked
    property alias cfg_PointerMovement: movementCheck.checked
    property alias cfg_ClickRipple: clickCheck.checked
    property alias cfg_EffectRadius: radiusSlider.value
    property alias cfg_EffectStrength: strengthSlider.value
    property alias cfg_WaveSpeed: waveSpeedSlider.value
    property alias cfg_Tension: tensionSlider.value
    property alias cfg_Damping: dampingSlider.value
    property alias cfg_SavedProfiles: profileStorage.text
    property alias cfg_ActiveProfileId: activeProfileStorage.text
    property alias formLayout: root

    property var savedProfiles: []
    property int profileNameMode: 0 // 0 creates, 1 renames.
    property real previewTime: 0

    function activeProfileIndex() {
        for (let index = 0; index < savedProfiles.length; ++index)
            if (savedProfiles[index].id === activeProfileStorage.text) return index;
        return -1;
    }

    function applyPerformancePreset(index) {
        if (index === 1) {
            sizeSpin.value = 28; fpsSpin.value = 15; depthSpin.value = 12;
            glowSlider.value = 0; edgeSlider.value = 0;
        } else if (index === 2) {
            sizeSpin.value = 19; fpsSpin.value = 24; depthSpin.value = 32;
            glowSlider.value = 0; edgeSlider.value = 0.25;
        } else if (index === 3) {
            sizeSpin.value = 12; fpsSpin.value = 45; depthSpin.value = 64;
            glowSlider.value = 0.35; edgeSlider.value = 0.4;
        }
    }

    function resetSource() {
        sourceBox.currentIndex = 0; modeBox.currentIndex = 0; imagePath.text = "";
        fitBox.currentIndex = 1; sourceColorCheck.checked = false;
        customAnimationColorCheck.checked = false;
    }

    function resetAppearance() {
        sizeSpin.value = 19; depthSpin.value = 32; colorButton.color = "#7fdbff";
        rampField.text = " .:-=+*#%@"; rampPresetBox.currentIndex = 0;
        backgroundColorButton.color = "#020307"; brightnessSlider.value = 0.05;
        contrastSlider.value = 1; gammaSlider.value = 1; spacingSlider.value = 1;
        reverseRampCheck.checked = false; ditheringCheck.checked = true;
        edgeSlider.value = 0.25; fontBox.currentIndex = 0; fontStorage.text = fontBox.currentText;
        opacitySlider.value = 1;
        glowSlider.value = 0;
    }

    function resetAnimation() {
        speedSlider.value = 1; fpsSpin.value = 24;
        proceduralScaleSlider.value = 1; proceduralIntensitySlider.value = 1;
        pauseOnBatteryCheck.checked = false;
    }

    function resetReactivity() {
        reactiveCheck.checked = true; movementCheck.checked = true; clickCheck.checked = true;
        radiusSlider.value = 6; strengthSlider.value = 1.5; waveSpeedSlider.value = 1.5;
        tensionSlider.value = 0.18; dampingSlider.value = 0.65;
    }

    function currentSettings() {
        return {
            sourceType: sourceBox.currentIndex, mode: modeBox.currentIndex,
            imagePath: imagePath.text, imageFit: fitBox.currentIndex,
            sourceColor: sourceColorCheck.checked, customAnimationColor: customAnimationColorCheck.checked,
            characterSize: sizeSpin.value, colorDepth: depthSpin.value,
            color: colorButton.color.toString(), characterRamp: rampField.text,
            rampPreset: rampPresetBox.currentIndex, backgroundColor: backgroundColorButton.color.toString(),
            brightness: brightnessSlider.value, contrast: contrastSlider.value, gamma: gammaSlider.value,
            characterSpacing: spacingSlider.value, reverseRamp: reverseRampCheck.checked,
            imageDithering: ditheringCheck.checked, edgeEnhancement: edgeSlider.value,
            fontFamily: fontBox.currentText, foregroundOpacity: opacitySlider.value,
            glowStrength: glowSlider.value,
            speed: speedSlider.value, frameRate: fpsSpin.value,
            proceduralScale: proceduralScaleSlider.value, proceduralIntensity: proceduralIntensitySlider.value,
            pauseOnBattery: pauseOnBatteryCheck.checked,
            reactiveEnabled: reactiveCheck.checked, pointerMovement: movementCheck.checked,
            clickRipple: clickCheck.checked, effectRadius: radiusSlider.value,
            effectStrength: strengthSlider.value, waveSpeed: waveSpeedSlider.value,
            tension: tensionSlider.value, damping: dampingSlider.value
        };
    }

    function persistProfiles() {
        profileStorage.text = JSON.stringify({version: 1, profiles: savedProfiles});
        profileBox.model = savedProfiles.map(profile => profile.name);
        const activeIndex = activeProfileIndex();
        profileBox.currentIndex = activeIndex >= 0 ? activeIndex : (savedProfiles.length ? 0 : -1);
    }

    function loadProfiles() {
        if (!profileStorage.text) {
            savedProfiles = [];
            profileBox.model = [];
            profileBox.currentIndex = -1;
            return;
        }
        try {
            const document = JSON.parse(profileStorage.text);
            savedProfiles = document.version === 1 && Array.isArray(document.profiles)
                ? document.profiles.filter(profile => profile && profile.name && profile.settings)
                : [];
            profileBox.model = savedProfiles.map(profile => profile.name);
            const activeIndex = activeProfileIndex();
            profileBox.currentIndex = activeIndex >= 0 ? activeIndex : (savedProfiles.length ? 0 : -1);
            profileError.text = "";
        } catch (error) {
            savedProfiles = [];
            profileBox.model = [];
            profileError.text = i18n("Saved profiles could not be read.");
        }
    }

    function applyProfile(settings) {
        if (!settings) return;
        sourceBox.currentIndex = settings.sourceType ?? sourceBox.currentIndex;
        modeBox.currentIndex = settings.mode ?? modeBox.currentIndex;
        imagePath.text = settings.imagePath ?? imagePath.text;
        fitBox.currentIndex = settings.imageFit ?? fitBox.currentIndex;
        sourceColorCheck.checked = settings.sourceColor ?? sourceColorCheck.checked;
        customAnimationColorCheck.checked = settings.customAnimationColor ?? customAnimationColorCheck.checked;
        sizeSpin.value = settings.characterSize ?? sizeSpin.value;
        depthSpin.value = settings.colorDepth ?? depthSpin.value;
        if (settings.color) colorButton.color = settings.color;
        rampField.text = settings.characterRamp ?? rampField.text;
        rampPresetBox.currentIndex = settings.rampPreset ?? rampPresetBox.currentIndex;
        if (settings.backgroundColor) backgroundColorButton.color = settings.backgroundColor;
        brightnessSlider.value = settings.brightness ?? brightnessSlider.value;
        contrastSlider.value = settings.contrast ?? contrastSlider.value;
        gammaSlider.value = settings.gamma ?? gammaSlider.value;
        spacingSlider.value = settings.characterSpacing ?? spacingSlider.value;
        reverseRampCheck.checked = settings.reverseRamp ?? reverseRampCheck.checked;
        ditheringCheck.checked = settings.imageDithering ?? ditheringCheck.checked;
        edgeSlider.value = settings.edgeEnhancement ?? edgeSlider.value;
        if (settings.fontFamily) {
            const fontIndex = fontBox.find(settings.fontFamily);
            fontBox.currentIndex = fontIndex >= 0 ? fontIndex : 0;
            fontStorage.text = fontBox.currentText;
        }
        opacitySlider.value = settings.foregroundOpacity ?? opacitySlider.value;
        glowSlider.value = settings.glowStrength ?? glowSlider.value;
        speedSlider.value = settings.speed ?? speedSlider.value;
        fpsSpin.value = settings.frameRate ?? fpsSpin.value;
        proceduralScaleSlider.value = settings.proceduralScale ?? proceduralScaleSlider.value;
        proceduralIntensitySlider.value = settings.proceduralIntensity ?? proceduralIntensitySlider.value;
        pauseOnBatteryCheck.checked = settings.pauseOnBattery ?? pauseOnBatteryCheck.checked;
        reactiveCheck.checked = settings.reactiveEnabled ?? reactiveCheck.checked;
        movementCheck.checked = settings.pointerMovement ?? movementCheck.checked;
        clickCheck.checked = settings.clickRipple ?? clickCheck.checked;
        radiusSlider.value = settings.effectRadius ?? radiusSlider.value;
        strengthSlider.value = settings.effectStrength ?? strengthSlider.value;
        waveSpeedSlider.value = settings.waveSpeed ?? waveSpeedSlider.value;
        tensionSlider.value = settings.tension ?? tensionSlider.value;
        dampingSlider.value = settings.damping ?? dampingSlider.value;
    }

    function commitConfiguration() {
        if (!configDialog || !configDialog.wallpaperConfiguration) return;
        configDialog.wallpaperConfiguration.keys().forEach(key => {
            const propertyName = "cfg_" + key;
            if (root[propertyName] !== undefined)
                configDialog.wallpaperConfiguration[key] = root[propertyName];
        });
        configDialog.applyWallpaper();
    }

    function applySelectedProfile() {
        const index = profileBox.currentIndex;
        if (index < 0 || index >= savedProfiles.length) return;
        applyProfile(savedProfiles[index].settings);
        activeProfileStorage.text = savedProfiles[index].id;
        Qt.callLater(commitConfiguration);
    }

    Component.onCompleted: loadProfiles()

    QQC2.TextField { id: profileStorage; visible: false }
    QQC2.TextField { id: activeProfileStorage; visible: false }
    QQC2.TextField {
        id: fontStorage
        visible: false
        onTextChanged: {
            const index = fontBox.find(text);
            if (index >= 0 && fontBox.currentIndex !== index) fontBox.currentIndex = index;
        }
    }

    Kirigami.Heading {
        Kirigami.FormData.isSection: true
        level: 2
        text: i18n("Profiles")
    }

    QQC2.ComboBox {
        id: profileBox
        Kirigami.FormData.label: i18n("Saved profile:")
        textRole: ""
    }

    Row {
        spacing: Kirigami.Units.smallSpacing

        QQC2.Button {
            text: i18n("Apply Profile")
            enabled: profileBox.currentIndex >= 0 && profileBox.currentIndex < savedProfiles.length
            onClicked: applySelectedProfile()
        }
        QQC2.Button {
            text: i18n("Save New...")
            onClicked: {
                profileNameMode = 0;
                profileNameDialog.open();
            }
        }
        QQC2.Button {
            text: i18n("Update")
            enabled: profileBox.currentIndex >= 0 && profileBox.currentIndex < savedProfiles.length
            onClicked: {
                savedProfiles[profileBox.currentIndex].settings = currentSettings();
                savedProfiles = savedProfiles.slice();
                persistProfiles();
            }
        }
        QQC2.Button {
            text: i18n("Rename")
            enabled: profileBox.currentIndex >= 0 && profileBox.currentIndex < savedProfiles.length
            onClicked: {
                profileNameMode = 1;
                profileNameDialog.open();
            }
        }
        QQC2.Button {
            text: i18n("Delete")
            enabled: profileBox.currentIndex >= 0 && profileBox.currentIndex < savedProfiles.length
            onClicked: deleteProfileDialog.open()
        }
    }

    QQC2.Label {
        id: profileError
        color: Kirigami.Theme.negativeTextColor
        visible: text.length > 0
    }

    QQC2.Dialog {
        id: profileNameDialog
        title: profileNameMode === 0 ? i18n("Save Profile") : i18n("Rename Profile")
        modal: true
        standardButtons: QQC2.Dialog.Save | QQC2.Dialog.Cancel
        onOpened: profileNameField.text = profileNameMode === 1 && profileBox.currentIndex >= 0
            ? savedProfiles[profileBox.currentIndex].name : ""
        onAccepted: {
            const name = profileNameField.text.trim();
            if (!name) return;
            if (profileNameMode === 1) {
                savedProfiles[profileBox.currentIndex].name = name.slice(0, 64);
            } else {
                savedProfiles.push({id: Date.now().toString(36) + "-" + Math.random().toString(36).slice(2), name: name.slice(0, 64), settings: currentSettings()});
            }
            savedProfiles = savedProfiles.slice();
            persistProfiles();
            if (profileNameMode === 0) profileBox.currentIndex = savedProfiles.length - 1;
        }
        QQC2.TextField {
            id: profileNameField
            width: 300
            placeholderText: i18n("Profile name")
            maximumLength: 64
        }
    }

    QQC2.Dialog {
        id: deleteProfileDialog
        title: i18n("Delete Profile")
        modal: true
        standardButtons: QQC2.Dialog.Yes | QQC2.Dialog.No
        QQC2.Label { text: i18n("Delete the selected profile?") }
        onAccepted: {
            const removedId = savedProfiles[profileBox.currentIndex].id;
            savedProfiles.splice(profileBox.currentIndex, 1);
            if (activeProfileStorage.text === removedId) activeProfileStorage.text = "";
            savedProfiles = savedProfiles.slice();
            persistProfiles();
        }
    }

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

    Timer {
        interval: 50
        repeat: true
        running: root.visible && sourceBox.currentIndex === 0
        onTriggered: {
            root.previewTime += 0.05 * speedSlider.value;
            livePreview.requestPaint();
            animationPreview.requestPaint();
        }
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

    QQC2.Button {
        text: i18n("Clear")
        visible: sourceBox.currentIndex === 1 && imagePath.text.length > 0
        onClicked: imagePath.text = ""
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

    QQC2.Button {
        text: i18n("Reset Source")
        onClicked: resetSource()
    }

    Kirigami.Heading {
        Kirigami.FormData.isSection: true
        level: 2
        text: i18n("Appearance")
    }

    Item {
        Kirigami.FormData.label: i18n("Live preview:")
        implicitWidth: 300
        implicitHeight: 120
        Layout.fillWidth: true
        Layout.minimumWidth: 160
        Layout.maximumWidth: 480
        visible: sourceBox.currentIndex === 0
        clip: true

        Canvas {
            id: livePreview
            anchors.fill: parent

            function noise(x, y) {
                const value = Math.sin(x * 127.1 + y * 311.7) * 43758.5453;
                return value - Math.floor(value);
            }

            function proceduralColor(mode) {
                if (customAnimationColorCheck.checked) return colorButton.color.toString();
                return ["#8be9fd", "#27c95a", "#bd93f9", "#ffb86c", "#50fa7b", "#bd93f9", "#8be9fd"][Math.max(0, Math.min(6, mode))];
            }

            function sampleBrightness(mode, x, y, columns, rows, time, scale) {
                const sx = x * scale;
                const sy = y * scale;
                if (mode === 0) {
                    const seed = noise(x, y);
                    return seed > 0.08 ? 0 : 0.15 + (0.5 + 0.5 * Math.sin(time * (1.5 + seed * 4) + seed * 30)) * 0.85;
                }
                if (mode === 1) {
                    const seed = noise(x, 7);
                    const period = rows + 5 + Math.floor(seed * 10);
                    const head = Math.floor((time * (4 + seed * 9) + seed * period) % period);
                    const distance = head - y;
                    return distance >= 0 && distance < 8 ? Math.max(0, 1 - distance / 8) : 0;
                }
                if (mode === 3) {
                    const rise = (rows - 1 - sy) / Math.max(1, rows);
                    const flame = Math.sin(sx * 0.19 + time * 2.1) * 0.18 + Math.sin(sx * 0.08 - time * 3.2) * 0.14;
                    return Math.max(0, Math.min(1, 1.15 - rise * 1.3 + flame));
                }
                if (mode === 4) {
                    const band = Math.sin(sx * 0.075 + time * 0.7) * 3 + Math.sin(sx * 0.021 - time) * 2;
                    return Math.max(0, Math.min(1, 1 - Math.abs(sy - rows * 0.48 - band) / 7));
                }
                if (mode === 5) {
                    const cloud = Math.sin(sx * 0.08 + Math.sin(sy * 0.1 + time * 0.2))
                        + Math.sin(sy * 0.14 - time * 0.25) + Math.sin((sx + sy) * 0.045);
                    return Math.max(0, Math.min(1, cloud / 5 + 0.48));
                }
                if (mode === 6) {
                    const swell = Math.sin(sx * 0.075 + time * 0.8) * 2.8;
                    return Math.max(0, Math.min(1, (Math.sin(sy * 0.42 + swell + time * 1.1) + 1) * 0.34));
                }
                const value = Math.sin(sx * 0.12 + time) + Math.sin(sy * 0.156 - time * 0.7)
                    + Math.sin((sx + sy) * 0.084 + time * 0.5);
                return Math.max(0, Math.min(1, value / 6 + 0.5));
            }

            function paintCanvas(canvas) {
                const context = canvas.getContext("2d");
                context.resetTransform();
                context.globalAlpha = 1;
                context.shadowBlur = 0;
                context.fillStyle = backgroundColorButton.color.toString();
                context.fillRect(0, 0, canvas.width, canvas.height);

                const ramp = rampPresetBox.currentIndex > 0
                    ? [" .:-=+*#%@", " ░▒▓█", " .oO@", " .'`^\",:;Il!i><~+_-?][}{1)(|\\/*tfjrxnuvczXYUJCLQ0OZmwqpdbkhao*#MW&8%B@$", " ▁▂▃▄▅▆▇█", " ⠁⠃⠇⡇⣇⣧⣷⣿", " ·◦○◉●", " 01"][rampPresetBox.currentIndex - 1]
                    : rampField.text;
                if (!ramp || ramp.length < 2) return;

                const cellHeight = Math.max(8, Math.min(20, sizeSpin.value * 0.75));
                const cellWidth = Math.max(4, cellHeight * 0.58 * spacingSlider.value);
                const columns = Math.ceil(canvas.width / cellWidth);
                const rows = Math.ceil(canvas.height / cellHeight);
                context.font = Math.max(6, cellHeight * 0.8) + "px '" + fontBox.currentText + "'";
                context.textAlign = "center";
                context.textBaseline = "middle";
                context.globalAlpha = opacitySlider.value;
                const previewColor = proceduralColor(modeBox.currentIndex);
                context.fillStyle = previewColor;
                context.shadowBlur = 0;

                for (let y = 0; y < rows; ++y) {
                    for (let x = 0; x < columns; ++x) {
                        let value = sampleBrightness(modeBox.currentIndex, x, y, columns, rows,
                            root.previewTime, proceduralScaleSlider.value) * proceduralIntensitySlider.value;
                        value = Math.pow(Math.max(0, Math.min(1, value)), 1 / gammaSlider.value);
                        value = Math.max(0, Math.min(1, (value - 0.5) * contrastSlider.value + 0.5 + brightnessSlider.value));
                        let index = Math.max(0, Math.min(ramp.length - 1, Math.floor(value * ramp.length)));
                        if (reverseRampCheck.checked && index > 0) index = ramp.length - index;
                        if (index > 0) {
                            const drawX = (x + 0.5) * cellWidth;
                            const drawY = (y + 0.5) * cellHeight;
                            if (glowSlider.value > 0) {
                                context.globalAlpha = opacitySlider.value * glowSlider.value * 0.35;
                                context.fillText(ramp[index], drawX + 1.5, drawY + 1.5);
                            }
                            context.globalAlpha = opacitySlider.value;
                            context.fillText(ramp[index], drawX, drawY);
                        }
                    }
                }
            }

            onPaint: paintCanvas(livePreview)
        }
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

    QQC2.ComboBox {
        id: fontBox
        Kirigami.FormData.label: i18n("Font:")
        model: ["DejaVu Sans Mono", "Liberation Mono", "Noto Sans Mono", "Ubuntu Mono", "Monospace"]
        Component.onCompleted: {
            const index = find(fontStorage.text);
            currentIndex = index >= 0 ? index : 0;
            fontStorage.text = currentText;
        }
        onActivated: fontStorage.text = currentText
    }

    QQC2.Slider {
        id: opacitySlider
        Kirigami.FormData.label: i18n("Foreground opacity:")
        from: 0.1
        to: 1.0
        stepSize: 0.05
    }

    QQC2.Label { text: Math.round(opacitySlider.value * 100) + "%" }

    QQC2.Slider {
        id: glowSlider
        Kirigami.FormData.label: i18n("Glow:")
        from: 0.0
        to: 1.0
        stepSize: 0.05
    }

    QQC2.Label { text: Math.round(glowSlider.value * 100) + "%" }

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
        implicitWidth: 240
        Layout.fillWidth: true
        Layout.minimumWidth: 140
        Layout.maximumWidth: 480
    }

    QQC2.Label {
        visible: rampPresetBox.currentIndex === 0 && (rampField.text.length < 2 || rampField.text[0] !== " ")
        text: i18n("The custom ramp must start with a space and contain at least one glyph.")
        color: Kirigami.Theme.negativeTextColor
        wrapMode: Text.Wrap
    }

    QQC2.TextField {
        Kirigami.FormData.label: i18n("Preset characters:")
        visible: rampPresetBox.currentIndex > 0
        text: ["", " .:-=+*#%@", " ░▒▓█", " .oO@", " .'`^\",:;Il!i><~+_-?][}{1)(|\\/*tfjrxnuvczXYUJCLQ0OZmwqpdbkhao*#MW&8%B@$", " ▁▂▃▄▅▆▇█", " ⠁⠃⠇⡇⣇⣧⣷⣿", " ·◦○◉●", " 01"][rampPresetBox.currentIndex]
        readOnly: true
        selectByMouse: true
        implicitWidth: 240
        Layout.fillWidth: true
        Layout.minimumWidth: 140
        Layout.maximumWidth: 480
    }

    QQC2.CheckBox {
        id: reverseRampCheck
        text: i18n("Reverse non-blank character order")
    }

    QQC2.CheckBox {
        id: ditheringCheck
        text: i18n("Dither image tones")
        visible: sourceBox.currentIndex === 1
    }

    QQC2.Slider {
        id: edgeSlider
        Kirigami.FormData.label: i18n("Edge enhancement:")
        from: 0.0
        to: 1.0
        stepSize: 0.05
        visible: sourceBox.currentIndex === 1
    }

    QQC2.Label {
        text: Math.round(edgeSlider.value * 100) + "%"
        visible: sourceBox.currentIndex === 1
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

    QQC2.Label {
        text: i18n("Smaller characters and higher frame rates increase rendering work. Color depth affects image palette generation only.")
        wrapMode: Text.Wrap
        color: Kirigami.Theme.disabledTextColor
        Layout.fillWidth: true
        Layout.minimumWidth: 140
        Layout.maximumWidth: 480
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

    QQC2.Button {
        text: i18n("Reset Appearance")
        onClicked: resetAppearance()
    }

    Kirigami.Heading {
        Kirigami.FormData.isSection: true
        level: 2
        text: i18n("Animation")
    }

    Item {
        Kirigami.FormData.label: i18n("Animation preview:")
        implicitWidth: 300
        implicitHeight: 120
        visible: sourceBox.currentIndex === 0
        clip: true
        Layout.fillWidth: true
        Layout.minimumWidth: 160
        Layout.maximumWidth: 480

        Canvas {
            id: animationPreview
            anchors.fill: parent
            onPaint: livePreview.paintCanvas(animationPreview)
        }
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

    QQC2.Slider {
        id: proceduralScaleSlider
        Kirigami.FormData.label: i18n("Pattern scale:")
        from: 0.5
        to: 2.0
        stepSize: 0.05
        visible: sourceBox.currentIndex === 0
    }

    QQC2.Label {
        text: Number(proceduralScaleSlider.value).toFixed(2) + "x"
        visible: sourceBox.currentIndex === 0
    }

    QQC2.Label {
        text: i18n("Pattern scale changes the spatial size of procedural features. Lower values make broader shapes; higher values pack in finer detail.")
        visible: sourceBox.currentIndex === 0
        wrapMode: Text.Wrap
        color: Kirigami.Theme.disabledTextColor
        Layout.fillWidth: true
        Layout.minimumWidth: 140
        Layout.maximumWidth: 480
    }

    QQC2.Slider {
        id: proceduralIntensitySlider
        Kirigami.FormData.label: i18n("Pattern intensity:")
        from: 0.25
        to: 2.0
        stepSize: 0.05
        visible: sourceBox.currentIndex === 0
    }

    QQC2.Label {
        text: Number(proceduralIntensitySlider.value).toFixed(2) + "x"
        visible: sourceBox.currentIndex === 0
    }

    QQC2.Label {
        text: i18n("Pattern intensity multiplies procedural brightness, changing how densely the character ramp is filled.")
        visible: sourceBox.currentIndex === 0
        wrapMode: Text.Wrap
        color: Kirigami.Theme.disabledTextColor
        Layout.fillWidth: true
        Layout.minimumWidth: 140
        Layout.maximumWidth: 480
    }

    QQC2.CheckBox {
        id: pauseOnBatteryCheck
        text: i18n("Pause animation and reactivity on battery power")
    }

    QQC2.Button {
        text: i18n("Reset Animation")
        onClicked: resetAnimation()
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

    QQC2.Button {
        text: i18n("Reset Reactivity")
        onClicked: resetReactivity()
    }

    Kirigami.Heading {
        Kirigami.FormData.isSection: true
        level: 2
        text: i18n("Defaults")
    }

    QQC2.ComboBox {
        Kirigami.FormData.label: i18n("Performance preset:")
        model: [i18n("Choose..."), i18n("Low power"), i18n("Balanced"), i18n("High detail")]
        onActivated: index => {
            applyPerformancePreset(index);
            currentIndex = 0;
        }
    }

    QQC2.Button {
        Kirigami.FormData.label: i18n("Settings:")
        text: i18n("Reset to defaults")
        onClicked: {
            resetSource(); resetAppearance(); resetAnimation(); resetReactivity();
        }
    }
}
