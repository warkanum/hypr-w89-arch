import QtQuick
import "../shared"

Rectangle {
    id: root
    width: 1920; height: 1080
    color: "#000000"
    readonly property color accent: config.accent || "#ffb870"
    readonly property color violet: "#b69cdd"
    readonly property bool animationsEnabled: String(config.animations).toLowerCase() !== "false"
    property real ambientPhase: 0
    NumberAnimation on ambientPhase {
        from: 0; to: 1; duration: 4200; loops: Animation.Infinite
        running: root.animationsEnabled && root.visible
    }
    Image { anchors.fill: parent; source: config.background; fillMode: Image.PreserveAspectCrop; opacity: 0.12 }
    Rectangle { x: 32; y: 32; width: Math.max(80, root.width * 0.12); height: root.height - 64; radius: 48; color: root.accent }
    Rectangle { x: 32; y: 100; width: root.width - 64; height: 30; radius: 15; color: root.violet }
    Rectangle { x: 32; y: root.height - 130; width: root.width - 64; height: 30; radius: 15; color: root.accent }
    Rectangle { x: root.width * 0.12 + 20; y: 145; width: 36; height: root.height - 290; color: "#000000" }
    Text {
        x: root.width * 0.21; y: root.height * 0.32
        text: "COMPUTER ACCESS\n\nLCARS\nTERMINAL ONLINE"
        color: root.violet; font.family: "monospace"; font.pixelSize: Math.min(26, root.width / 60)
        font.letterSpacing: 3; visible: root.width > 1100
    }
    // A low-contrast sweep across console segments; no invented telemetry.
    Item {
        x: root.width * 0.22; y: root.height * 0.62
        width: root.width * 0.34; height: 10
        visible: root.width > 1100
        Repeater {
            model: 16
            Rectangle {
                required property int index
                x: index * parent.width / 16; width: parent.width / 16 - 5
                height: 10; radius: 4
                color: index % 3 === 0 ? root.accent : root.violet
                opacity: root.animationsEnabled ? 0.18 + Math.pow(Math.max(0, Math.cos((root.ambientPhase - index / 16) * 6.283185)), 8) * 0.5 : 0.3
            }
        }
    }
    LoginPanel {
        id: panel
        width: implicitWidth; height: implicitHeight
        x: root.width - width - Math.max(48, root.width * 0.08); y: (root.height - height) / 2
        scale: Math.min(1, (root.height - 280) / height, (root.width * 0.74) / width)
        transformOrigin: Item.Right
        accent: root.accent; surface: "#fa000000"; border.width: 0
        heading: "LCARS / SECURITY ACCESS"; actionLabel: "AUTHORISE"
        radius: 0
        animationsEnabled: root.animationsEnabled
    }
}
