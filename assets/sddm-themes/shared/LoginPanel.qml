import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

// Authentication is shared; each theme owns its layout and visual decoration.
Rectangle {
    id: panel
    objectName: "loginPanel"
    property color accent: "#7fd4ff"
    property color ink: "#e6edf5"
    property color surface: "#ed10151c"
    property string heading: "AUTHORISATION"
    property string actionLabel: "SIGN IN"
    property bool busy: false
    property bool animationsEnabled: true
    property bool accepted: false
    property bool rejected: false
    property real introProgress: 1
    property real activityPhase: 0
    property real failureFlash: 0
    property string status: "READY"
    readonly property string clockText: Qt.formatTime(now, "HH:mm")
    property date now: new Date()
    signal authenticated()
    implicitWidth: 380
    implicitHeight: form.implicitHeight + 48
    color: surface
    border.color: rejected ? "#df776a" : Qt.rgba(accent.r, accent.g, accent.b, 0.5)
    radius: 8
    clip: true
    opacity: animationsEnabled ? introProgress : 1
    NumberAnimation on introProgress {
        from: 0; to: 1; duration: 550
        running: panel.animationsEnabled
    }
    NumberAnimation on activityPhase {
        from: 0; to: 1; duration: 1500; loops: Animation.Infinite
        running: panel.animationsEnabled && panel.busy && !panel.accepted
    }
    NumberAnimation {
        id: deniedAnimation
        target: panel; property: "failureFlash"
        from: 1; to: 0; duration: 900
    }
    Behavior on border.color { enabled: panel.animationsEnabled; ColorAnimation { duration: 220 } }

    function submit() {
        if (busy || users.currentIndex < 0 || sessions.currentIndex < 0) return
        busy = true
        accepted = false
        rejected = false
        status = "AUTHENTICATING"
        sddm.login(users.currentText, password.text, sessions.currentIndex)
    }
    Component.onCompleted: password.forceActiveFocus()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: panel.now = new Date() }
    Connections {
        target: sddm
        function onLoginFailed() {
            panel.busy = false
            panel.rejected = true
            panel.accepted = false
            if (panel.animationsEnabled) deniedAnimation.restart()
            panel.status = "ACCESS DENIED — TRY AGAIN"
            password.clear()
            password.forceActiveFocus()
        }
        function onLoginSucceeded() {
            password.clear()
            panel.accepted = true
            panel.status = "ACCESS GRANTED"
            panel.authenticated()
        }
    }
    component Caption: Text {
        color: panel.accent
        font.family: "monospace"
        font.pixelSize: 11
        font.letterSpacing: 2
        Layout.fillWidth: true
        elide: Text.ElideRight
    }
    component Choice: ComboBox {
        id: choice
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        textRole: "name"
        enabled: !panel.busy
        font.pixelSize: 15
        palette.text: panel.ink
        palette.buttonText: panel.ink
        palette.button: "#16212b"
        palette.base: "#16212b"
        palette.highlight: panel.accent
        palette.highlightedText: "#060910"
        contentItem: Text {
            text: choice.displayText
            color: panel.ink
            leftPadding: 12; rightPadding: 28
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            font.pixelSize: 15
        }
        indicator: Text {
            text: "⌄"; color: panel.accent; font.pixelSize: 18
            x: choice.width - width - 12; y: (choice.height - height) / 2
        }
        background: Rectangle {
            color: "#16212b"
            border.color: choice.activeFocus ? panel.accent : "#51606d"
            radius: 3
        }
    }
    component PowerAction: Button {
        id: power
        Layout.preferredHeight: 32
        font.pixelSize: 10
        contentItem: Text {
            text: power.text; color: panel.accent
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            font: power.font
        }
        background: Rectangle {
            color: power.hovered ? "#26323d" : "transparent"
            Behavior on color { enabled: panel.animationsEnabled; ColorAnimation { duration: 160 } }
            border.color: Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.4)
            radius: 3
        }
    }
    ColumnLayout {
        id: form
        anchors.fill: parent
        anchors.margins: 24
        spacing: 10
        Caption { text: panel.heading; font.pixelSize: 14 }
        Text { text: panel.clockText; color: panel.ink; font.pixelSize: 48; font.weight: Font.Light }
        Caption { text: Qt.formatDate(panel.now, "ddd, d MMM yyyy").toUpperCase() }
        Caption { text: sddm.hostName.toUpperCase(); Layout.bottomMargin: 8 }
        Caption { text: "USER" }
        Choice { id: users; model: userModel; currentIndex: userModel.lastIndex }
        Caption { text: "PASSWORD" }
        TextField {
            id: password
            objectName: "passwordField"
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            enabled: !panel.busy
            echoMode: TextInput.Password
            color: panel.ink
            selectByMouse: true
            font.pixelSize: 15
            background: Rectangle {
                color: "#16212b"
                radius: 3
                border.color: password.activeFocus ? panel.accent : "#51606d"
            }
            onAccepted: panel.submit()
        }
        Caption { text: "DESKTOP SESSION" }
        Choice { id: sessions; model: sessionModel; currentIndex: sessionModel.lastIndex }
        Button {
            id: loginButton
            text: panel.actionLabel
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            Layout.topMargin: 8
            enabled: !panel.busy && users.currentIndex >= 0 && sessions.currentIndex >= 0
            onClicked: panel.submit()
            contentItem: Text {
                text: loginButton.text
                color: "#05070b"
                font.bold: true
                font.letterSpacing: 2
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: panel.accent; radius: 4; opacity: loginButton.enabled ? 1 : 0.45
                Behavior on opacity { enabled: panel.animationsEnabled; NumberAnimation { duration: 160 } }
            }
        }
        Caption { text: panel.status; font.letterSpacing: 0; wrapMode: Text.WordWrap; elide: Text.ElideNone }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8
            PowerAction { text: "SUSPEND"; visible: sddm.canSuspend; enabled: !panel.busy; onClicked: sddm.suspend() }
            PowerAction { text: "REBOOT"; visible: sddm.canReboot; enabled: !panel.busy; onClicked: sddm.reboot() }
            PowerAction { text: "POWER OFF"; visible: sddm.canPowerOff; enabled: !panel.busy; onClicked: sddm.powerOff() }
        }
    }
    Rectangle {
        anchors.fill: parent
        color: panel.rejected ? "#df776a" : panel.accent
        opacity: panel.accepted ? 0.08 : (panel.animationsEnabled ? panel.failureFlash * 0.08 : 0)
        radius: panel.radius
        Behavior on opacity { enabled: panel.animationsEnabled && panel.accepted; NumberAnimation { duration: 400 } }
    }
    Rectangle {
        anchors.bottom: parent.bottom
        width: panel.animationsEnabled && !panel.accepted ? parent.width * 0.2 : parent.width
        height: 3
        x: panel.animationsEnabled && !panel.accepted ? (panel.activityPhase * 1.2 - 0.2) * parent.width : 0
        color: panel.accent
        visible: panel.busy
        opacity: 0.8
    }
}
