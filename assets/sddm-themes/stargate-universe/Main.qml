import QtQuick
import "../shared"

Rectangle {
    id: root
    width: 1920; height: 1080
    color: "#07090c"
    readonly property color accent: config.accent || "#c4a679"
    readonly property bool animationsEnabled: String(config.animations).toLowerCase() !== "false"
    property real ambientPhase: 0
    NumberAnimation on ambientPhase {
        from: 0; to: 1; duration: 45000; loops: Animation.Infinite
        running: root.animationsEnabled && root.visible
    }
    Image { anchors.fill: parent; source: config.background; fillMode: Image.PreserveAspectCrop }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "#10000000" }
            GradientStop { position: 0.55; color: "#40000000" }
            GradientStop { position: 1; color: "#e607090c" }
        }
    }
    // Slow starlight drifts only across the window, leaving the hull stationary.
    Item {
        x: root.width * 0.12; y: root.height * 0.20
        width: root.width * 0.51; height: root.height * 0.42
        clip: true; visible: root.animationsEnabled
        Repeater {
            model: 18
            Rectangle {
                required property int index
                x: parent.width * (1 - (root.ambientPhase + index * 0.061) % 1)
                y: parent.height * ((index * 0.237) % 1)
                width: 2 + index % 3; height: 1; radius: 0.5
                color: "#d5eaff"; opacity: 0.12 + (index % 4) * 0.04
            }
        }
    }
    // Structural ribs frame the view from Destiny without covering the galaxy.
    Rectangle { width: parent.width; height: 8; color: root.accent; opacity: 0.45 }
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 8; color: root.accent; opacity: 0.45 }
    Text {
        x: 48; y: 40
        text: "DESTINY / OBSERVATION DECK"
        color: root.accent; font.family: "monospace"; font.pixelSize: 16; font.letterSpacing: 3
        visible: root.width > 1000
    }
    LoginPanel {
        id: panel
        width: implicitWidth; height: implicitHeight
        x: root.width - width - Math.max(24, root.width * 0.06); y: (root.height - height) / 2
        scale: Math.min(1, (root.height - 48) / height, (root.width - 48) / width)
        transformOrigin: Item.Right
        accent: root.accent; heading: "DESTINY / CREW ACCESS"; actionLabel: "BOARD DESTINY"
        animationsEnabled: root.animationsEnabled
    }
}
