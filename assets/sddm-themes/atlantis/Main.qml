import QtQuick
import "../shared"

Rectangle {
    id: root
    width: 1920; height: 1080
    color: "#04131c"
    readonly property color accent: config.accent || "#66d9cf"
    readonly property bool animationsEnabled: String(config.animations).toLowerCase() !== "false"
    property real ambientPhase: 0
    NumberAnimation on ambientPhase {
        from: 0; to: 6.283185; duration: 16000; loops: Animation.Infinite
        running: root.animationsEnabled && root.visible
    }
    Image { anchors.fill: parent; source: config.background; fillMode: Image.PreserveAspectCrop }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "#d504131c" }
            GradientStop { position: 0.6; color: "#3004131c" }
            GradientStop { position: 1; color: "#1004131c" }
        }
    }
    // Fine horizontal glints suggest moonlight moving across the water.
    Item {
        x: root.width * 0.42; y: root.height * 0.70
        width: root.width * 0.49; height: root.height * 0.18
        visible: root.animationsEnabled
        Repeater {
            model: 12
            Rectangle {
                required property int index
                x: parent.width * ((index * 0.173) % 0.75) + Math.sin(root.ambientPhase + index) * 8
                y: parent.height * index / 12
                width: parent.width * (0.04 + (index % 3) * 0.025)
                height: 1; radius: 0.5
                color: "#9ddbe6"
                opacity: 0.035 + (1 + Math.sin(root.ambientPhase + index * 0.8)) * 0.035
            }
        }
    }
    Rectangle { x: 28; y: 28; width: 3; height: parent.height - 56; color: root.accent; opacity: 0.6 }
    Text {
        anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 48
        text: "ATLANTIS\nPEGASUS EXPEDITION"
        color: "#b8e6ec"; font.family: "monospace"; font.pixelSize: 20; font.letterSpacing: 4
        horizontalAlignment: Text.AlignRight; visible: root.width > 1000
    }
    LoginPanel {
        id: panel
        width: implicitWidth; height: implicitHeight
        x: Math.max(48, root.width * 0.06); y: (root.height - height) / 2
        scale: Math.min(1, (root.height - 48) / height, (root.width - 96) / width)
        transformOrigin: Item.Left
        accent: root.accent; surface: "#de061e2a"
        heading: "ATLANTIS / EXPEDITION ACCESS"; actionLabel: "ENTER ATLANTIS"
        radius: 16
        animationsEnabled: root.animationsEnabled
    }
}
