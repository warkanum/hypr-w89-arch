import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#05070b"

    readonly property color accent: config.accent ? config.accent : "#7fd4ff"
    readonly property color horizonTint: config.horizon ? config.horizon : "#5fb3ff"
    readonly property color text: "#e6edf5"
    readonly property color dim: "#7d8b9c"
    readonly property color field: "#10151c"
    readonly property color line: "#3a4452"
    readonly property int chevronsNeeded: 7

    property bool dialing: false
    property string status: "AWAITING AUTHORISATION"

    function submit() {
        if (dialing)
            return
        dialing = true
        gate.dial()
    }

    Component.onCompleted: password.forceActiveFocus()

    // Preview keys for test mode (visual only, they never log in):
    // Ctrl+Shift+O toggles the open gate and splash, Ctrl+Shift+F plays the failure sequence
    Shortcut {
        sequence: "Ctrl+Shift+O"
        onActivated: {
            gate.opened = !gate.opened
            root.status = gate.opened ? "WORMHOLE ESTABLISHED" : "AWAITING AUTHORISATION"
        }
    }
    Shortcut {
        sequence: "Ctrl+Shift+F"
        onActivated: {
            gate.opened = false
            gate.failed = true
            root.status = "DIALLING FAILED - ACCESS DENIED"
            resetTimer.start()
        }
    }

    // Background; the animated gate is drawn over the gate in the artwork
    Image {
        id: bg
        anchors.fill: parent
        source: config.background ? config.background : "stargate-space.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.3
    }

    // Gate position in artwork pixels (1672x941), mapped through the crop
    readonly property real artScale: Math.max(width / 1672, height / 941)
    readonly property real artX: (width - 1672 * artScale) / 2
    readonly property real artY: (height - 941 * artScale) / 2

    Gate {
        id: gate
        width: 800 * root.artScale
        height: width
        x: root.artX + 828 * root.artScale - width / 2
        y: root.artY + 455 * root.artScale - height / 2
        chevronColor: root.accent
        horizonColor: root.horizonTint
    }

    // Dialling sequence runs in Gate; authenticate once the last chevron engages
    Connections {
        target: gate
        function onLitChanged() {
            if (gate.lit > 0 && gate.lit < root.chevronsNeeded)
                root.status = "CHEVRON " + gate.lit + " ENCODED"
        }
        function onDialed() {
            root.status = "CHEVRON " + gate.lit + " LOCKED"
            authTimer.start()
        }
    }
    Timer {
        id: authTimer
        interval: 400
        onTriggered: sddm.login(userBox.currentText, password.text, sessionBox.currentIndex)
    }
    Timer {
        id: resetTimer
        interval: 1600
        onTriggered: {
            gate.reset()
            gate.failed = false
            root.dialing = false
            root.status = "AWAITING AUTHORISATION"
            password.text = ""
            password.forceActiveFocus()
        }
    }
    Connections {
        target: sddm
        function onLoginSucceeded() {
            gate.opened = true
            root.status = "WORMHOLE ESTABLISHED"
        }
        function onLoginFailed() {
            gate.failed = true
            root.status = "DIALLING FAILED - ACCESS DENIED"
            resetTimer.start()
        }
    }

    // Clock
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var d = new Date()
            clock.text = Qt.formatTime(d, "HH:mm")
            date.text = Qt.formatDate(d, "dddd, d MMMM yyyy").toUpperCase()
        }
    }

    component Label: Text {
        color: root.dim
        font.family: "monospace"
        font.pixelSize: 12
        font.letterSpacing: 2
    }

    component StyledCombo: ComboBox {
        id: combo
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        font.family: "monospace"
        font.pixelSize: 15

        contentItem: Text {
            leftPadding: 12
            text: combo.displayText
            color: root.text
            font: combo.font
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        indicator: Text {
            x: combo.width - width - 12
            y: (combo.height - height) / 2
            text: "v"
            color: root.accent
            font: combo.font
        }
        background: Rectangle {
            color: root.field
            border.color: combo.activeFocus ? root.accent : root.line
            border.width: 1
            radius: 2
        }
        delegate: ItemDelegate {
            id: del
            required property var model
            required property int index
            width: combo.width
            highlighted: combo.highlightedIndex === index
            contentItem: Text {
                text: del.model.name
                color: root.text
                font: combo.font
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: del.highlighted ? "#1d2733" : root.field
            }
        }
        popup: Popup {
            y: combo.height
            width: combo.width
            implicitHeight: Math.min(contentItem.implicitHeight, 240)
            padding: 1
            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: combo.popup.visible ? combo.delegateModel : null
                currentIndex: combo.highlightedIndex
            }
            background: Rectangle {
                color: root.field
                border.color: root.line
            }
        }
    }

    component PowerButton: Button {
        id: pb
        flat: true
        font.family: "monospace"
        font.pixelSize: 11
        contentItem: Text {
            text: pb.text
            color: pb.hovered ? root.accent : root.dim
            font: pb.font
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Item {}
    }

    // Login panel
    Rectangle {
        id: panel
        width: Math.min(400, root.width * 0.3)
        height: column.implicitHeight + 64
        x: Math.min(root.width * 0.76, root.width - width - 24)
        y: (root.height - height) / 2
        color: "#d00a0f16"
        border.color: root.line
        border.width: 1
        radius: 2

        ColumnLayout {
            id: column
            anchors.fill: parent
            anchors.margins: 32
            spacing: 10

            Label {
                text: "STARGATE COMMAND"
                color: root.accent
                font.pixelSize: 13
            }
            Label { text: sddm.hostName.toUpperCase() }

            Text {
                id: clock
                color: root.text
                font.family: "monospace"
                font.pixelSize: 54
                font.weight: Font.Light
            }
            Label {
                id: date
                Layout.bottomMargin: 14
            }

            Label { text: "OPERATIVE" }
            StyledCombo {
                id: userBox
                model: userModel
                textRole: "name"
                currentIndex: userModel.lastIndex
                enabled: !root.dialing
            }

            Label {
                text: "PASSPHRASE"
                Layout.topMargin: 4
            }
            TextField {
                id: password
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                echoMode: TextInput.Password
                passwordCharacter: "•"
                color: root.text
                font.family: "monospace"
                font.pixelSize: 15
                leftPadding: 12
                enabled: !root.dialing
                selectByMouse: true
                background: Rectangle {
                    color: root.field
                    border.color: password.activeFocus ? root.accent : root.line
                    border.width: 1
                    radius: 2
                }
                onAccepted: root.submit()
            }

            Label {
                text: "SESSION"
                Layout.topMargin: 4
            }
            StyledCombo {
                id: sessionBox
                model: sessionModel
                textRole: "name"
                currentIndex: sessionModel.lastIndex
                enabled: !root.dialing
            }

            Button {
                id: dial
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                Layout.topMargin: 12
                text: "DIAL"
                enabled: !root.dialing
                font.family: "monospace"
                font.pixelSize: 15
                font.bold: true
                font.letterSpacing: 4
                contentItem: Text {
                    text: dial.text
                    color: dial.hovered ? "#05070b" : root.accent
                    font: dial.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: dial.hovered ? root.accent : "transparent"
                    border.color: root.accent
                    border.width: 1
                    radius: 2
                    opacity: dial.enabled ? 1 : 0.4
                }
                onClicked: root.submit()
            }

            Label {
                text: root.status
                color: gate.failed ? "#e03a2c" : (gate.opened ? root.horizonTint : root.dim)
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 16
                PowerButton {
                    text: "SUSPEND"
                    visible: sddm.canSuspend
                    onClicked: sddm.suspend()
                }
                PowerButton {
                    text: "REBOOT"
                    visible: sddm.canReboot
                    onClicked: sddm.reboot()
                }
                PowerButton {
                    text: "SHUTDOWN"
                    visible: sddm.canPowerOff
                    onClicked: sddm.powerOff()
                }
            }
        }
    }

    // Final stage: blue splash blooms out of the gate and floods the screen
    Item {
        id: splash
        width: 1024
        height: 1024
        x: gate.x + gate.width / 2 - width / 2
        y: gate.y + gate.height / 2 - height / 2
        readonly property real full: 2.4 * Math.max(root.width, root.height) / width
        scale: gate.opened ? full : 0.1
        opacity: gate.opened ? 0.55 : 0
        Behavior on scale { NumberAnimation { duration: 750; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 300 } }

        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                var c = width / 2
                var t = root.horizonTint
                var g = ctx.createRadialGradient(c, c, 0, c, c, c)
                g.addColorStop(0, "#ffffff")
                g.addColorStop(0.15, "#d8f2ff")
                g.addColorStop(0.45, Qt.rgba(t.r, t.g, t.b, 0.92))
                g.addColorStop(0.75, Qt.rgba(t.r * 0.5, t.g * 0.5, t.b * 0.8, 0.85))
                g.addColorStop(1, Qt.rgba(t.r * 0.4, t.g * 0.4, t.b * 0.7, 0.8))
                ctx.fillStyle = g
                ctx.fillRect(0, 0, width, height)
            }
        }
    }
    Text {
        anchors.centerIn: parent
        text: "WORMHOLE ESTABLISHED"
        color: "#0b2a52"
        font.family: "monospace"
        font.pixelSize: 22
        font.letterSpacing: 6
        opacity: gate.opened ? 1 : 0
        Behavior on opacity { SequentialAnimation { PauseAnimation { duration: 450 } NumberAnimation { duration: 400 } } }
    }
}
