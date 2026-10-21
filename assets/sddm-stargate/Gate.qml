import QtQuick

// Pegasus (Atlantis) style gate: fixed ring, 36 glyphs that light up in a
// sweep to each address symbol, 9 chevrons that engage, blue event horizon.
Item {
    id: gate

    property bool opened: false
    property bool failed: false
    property bool failureLit: true
    property int lit: 0
    property int chase: -1
    property var locked: []
    property color chevronColor: "#7fd4ff"
    property color horizonColor: "#5fb3ff"

    readonly property int glyphCount: 36
    readonly property int symbolCount: 7
    readonly property color glyphDim: "#2c3b4d"
    readonly property color glyphLocked: "#bfeaff"
    readonly property color glyphChase: "#4aa8ff"

    // Chevrons engaged in dialling order; index 0 is the top (engages last)
    readonly property var litOrder: [1, 2, 3, 6, 7, 8, 0, 4, 5]

    signal dialed()

    onFailedChanged: {
        failureLit = true
        if (failed) {
            sweep.stop()
            engage.stop()
            chase = -1
        }
    }

    // Flash every glyph and chevron red until the failure state is reset.
    Timer {
        interval: 200
        running: gate.failed
        repeat: true
        onTriggered: gate.failureLit = !gate.failureLit
    }

    // Dialling state
    property int pos: 0
    property int dir: 1
    property int target: 0
    property int step: 0
    property var targets: []

    function reset() {
        failed = false
        sweep.stop()
        engage.stop()
        chase = -1
        locked = []
        lit = 0
        pos = 0
        step = 0
    }

    function dial() {
        reset()
        failed = false
        // Pick symbols near the previous one so the sweep stays short; the last is the point of origin
        var t = [], p = 0, s = 1
        for (var i = 0; i < symbolCount - 1; i++) {
            var next
            do {
                next = (p + s * (5 + Math.floor(Math.random() * 9)) + glyphCount) % glyphCount
                s = -s
            } while (next === 0 || t.indexOf(next) >= 0)
            t.push(next)
            p = next
        }
        t.push(0)
        targets = t
        nextSymbol()
    }

    function nextSymbol() {
        target = targets[step]
        var cw = (target - pos + glyphCount) % glyphCount
        dir = cw <= glyphCount / 2 ? 1 : -1
        sweep.start()
    }

    // Light chases around the ring to the next address symbol
    Timer {
        id: sweep
        interval: 12
        repeat: true
        onTriggered: {
            gate.pos = (gate.pos + gate.dir + gate.glyphCount) % gate.glyphCount
            gate.chase = gate.pos
            if (gate.pos === gate.target) {
                stop()
                gate.locked = gate.locked.concat([gate.target])
                gate.chase = -1
                engage.start()
            }
        }
    }

    // Symbol held, then its chevron engages
    Timer {
        id: engage
        interval: 170
        onTriggered: {
            gate.lit++
            gate.step++
            if (gate.step >= gate.symbolCount)
                gate.dialed()
            else
                gate.nextSymbol()
        }
    }

    // Wormhole glow
    Canvas {
        anchors.centerIn: parent
        width: gate.width * 1.5
        height: width
        opacity: gate.opened ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 700 } }
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var c = width / 2
            var g = ctx.createRadialGradient(c, c, width * 0.2, c, c, c)
            g.addColorStop(0, Qt.rgba(gate.horizonColor.r, gate.horizonColor.g, gate.horizonColor.b, 0.35))
            g.addColorStop(1, Qt.rgba(gate.horizonColor.r, gate.horizonColor.g, gate.horizonColor.b, 0))
            ctx.fillStyle = g
            ctx.fillRect(0, 0, width, height)
        }
    }

    // Outer ring
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "#4a5360"
        border.color: "#8d9aab"
        border.width: 3
    }
    Rectangle {
        anchors.centerIn: parent
        width: gate.width * 0.83
        height: width
        radius: width / 2
        color: "transparent"
        border.color: "#1b2027"
        border.width: 2
    }

    // Glyph ring plates (static)
    Canvas {
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var c = width / 2
            var R = width / 2
            var n = gate.glyphCount
            var rIn = R * 0.60
            var rOut = R * 0.82

            ctx.fillStyle = "#171d26"
            ctx.beginPath()
            ctx.arc(c, c, rOut, 0, Math.PI * 2)
            ctx.moveTo(c + rIn, c)
            ctx.arc(c, c, rIn, 0, Math.PI * 2, true)
            ctx.fill()

            ctx.strokeStyle = "#0a0d12"
            ctx.lineWidth = 2
            for (var i = 0; i < n; i++) {
                ctx.save()
                ctx.translate(c, c)
                ctx.rotate((i + 0.5) * 2 * Math.PI / n)
                ctx.beginPath()
                ctx.moveTo(0, -rIn)
                ctx.lineTo(0, -rOut)
                ctx.stroke()
                ctx.restore()
            }
        }
    }

    // Glyphs
    Repeater {
        model: gate.glyphCount
        delegate: Item {
            id: plate
            required property int index
            anchors.fill: parent
            rotation: index * 360 / gate.glyphCount

            readonly property bool isLocked: gate.locked.indexOf(index) >= 0
            readonly property bool isChase: gate.chase === index

            Canvas {
                id: glyph
                readonly property real pad: 6
                readonly property real pw: gate.width * 0.028
                readonly property real ph: gate.width * 0.062
                width: pw + pad * 2
                height: ph + pad * 2
                anchors.horizontalCenter: parent.horizontalCenter
                y: gate.width * (0.5 - 0.355) - height / 2

                property color tint: gate.failed ? (gate.failureLit ? "#e03a2c" : gate.glyphDim)
                                                : (plate.isLocked ? gate.glyphLocked
                                                                  : (plate.isChase ? gate.glyphChase : gate.glyphDim))
                readonly property bool glowing: gate.failed ? gate.failureLit : (plate.isLocked || plate.isChase)
                Behavior on tint { ColorAnimation { duration: gate.failed ? 60 : (plate.isChase ? 40 : 260) } }
                onTintChanged: requestPaint()
                onGlowingChanged: requestPaint()

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    var px = [], py = []
                    var s = (plate.index + 3) * 7919
                    for (var k = 0; k < 4; k++) {
                        s = (s * 48271) % 2147483647
                        px.push(pad + (s % 3) * pw / 2)
                        s = (s * 48271) % 2147483647
                        py.push(pad + (s % 3) * ph / 2)
                    }
                    ctx.strokeStyle = tint
                    ctx.fillStyle = tint
                    ctx.lineWidth = Math.max(1.6, gate.width * 0.0045)
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    if (glowing) {
                        ctx.shadowColor = tint
                        ctx.shadowBlur = 10
                    }
                    ctx.beginPath()
                    ctx.moveTo(px[0], py[0])
                    for (var j = 1; j < 4; j++)
                        ctx.lineTo(px[j], py[j])
                    ctx.stroke()
                    ctx.beginPath()
                    ctx.arc(px[3], py[3], ctx.lineWidth * 1.2, 0, Math.PI * 2)
                    ctx.fill()
                }
            }
        }
    }

    // Inner bezel
    Rectangle {
        anchors.centerIn: parent
        width: gate.width * 0.60
        height: width
        radius: width / 2
        color: "#1b2027"
        border.color: "#7a8696"
        border.width: 2
    }

    // Event horizon
    Item {
        id: horizon
        anchors.centerIn: parent
        width: gate.width * 0.56
        height: width

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "#07090c"
        }

        // Kawoosh: bright burst that blooms past the rim, then settles
        Rectangle {
            id: burst
            anchors.centerIn: parent
            width: parent.width
            height: width
            radius: width / 2
            color: "#eaf8ff"
            opacity: 0
            scale: 0.1
            SequentialAnimation {
                running: gate.opened
                ParallelAnimation {
                    NumberAnimation { target: burst; property: "scale"; to: 1.18; duration: 420; easing.type: Easing.OutCubic }
                    NumberAnimation { target: burst; property: "opacity"; to: 1; duration: 200 }
                }
                ParallelAnimation {
                    NumberAnimation { target: burst; property: "scale"; to: 1.0; duration: 500; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: burst; property: "opacity"; to: 0; duration: 700 }
                }
            }
        }

        Item {
            id: water
            anchors.fill: parent
            scale: gate.opened ? 1 : 0
            opacity: gate.opened ? 1 : 0
            Behavior on scale {
                NumberAnimation { duration: 900; easing.type: Easing.OutBack; easing.overshoot: 2.2 }
            }
            Behavior on opacity { NumberAnimation { duration: 300 } }

            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    var c = width / 2
                    var g = ctx.createRadialGradient(c, c, 0, c, c, c)
                    g.addColorStop(0, "#f2fbff")
                    g.addColorStop(0.45, Qt.lighter(gate.horizonColor, 1.1))
                    g.addColorStop(1, Qt.darker(gate.horizonColor, 2.2))
                    ctx.fillStyle = g
                    ctx.beginPath()
                    ctx.arc(c, c, c, 0, Math.PI * 2)
                    ctx.fill()
                }
                SequentialAnimation on opacity {
                    running: gate.opened
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.8; duration: 1100; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 1100; easing.type: Easing.InOutSine }
                }
            }

            Repeater {
                model: 3
                delegate: Rectangle {
                    id: ripple
                    required property int index
                    anchors.centerIn: parent
                    width: parent.width
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.color: "#d8f0ff"
                    border.width: 2
                    opacity: 0

                    SequentialAnimation {
                        running: gate.opened
                        PauseAnimation { duration: ripple.index * 870 }
                        ParallelAnimation {
                            loops: Animation.Infinite
                            NumberAnimation { target: ripple; property: "scale"; from: 0.1; to: 1; duration: 2600; easing.type: Easing.OutQuad }
                            NumberAnimation { target: ripple; property: "opacity"; from: 0.8; to: 0; duration: 2600 }
                        }
                    }
                }
            }
        }
    }

    // Chevrons
    Repeater {
        model: 9
        delegate: Item {
            id: chev
            required property int index
            anchors.fill: parent
            rotation: index * 40
            readonly property bool on: gate.lit > gate.litOrder.indexOf(index)

            Canvas {
                id: shape
                readonly property real pad: 8
                readonly property real cw: gate.width * 0.12
                readonly property real ch: gate.width * 0.085
                width: cw + pad * 2
                height: ch + pad * 2
                anchors.horizontalCenter: parent.horizontalCenter
                // engaged chevrons seat slightly inward
                y: gate.width * 0.012 - pad + (chev.on ? gate.width * 0.008 : 0)
                Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }

                property color tint: gate.failed ? (gate.failureLit ? "#e03a2c" : "#56606e")
                                                : (chev.on ? gate.chevronColor : "#56606e")
                readonly property bool glowing: gate.failed ? gate.failureLit : chev.on
                Behavior on tint { ColorAnimation { duration: gate.failed ? 60 : 150 } }
                onTintChanged: requestPaint()
                onGlowingChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    var w = cw, h = ch
                    ctx.translate(pad, pad)
                    if (glowing) {
                        ctx.shadowColor = tint
                        ctx.shadowBlur = 14
                    }
                    ctx.fillStyle = tint
                    ctx.strokeStyle = "#0f1217"
                    ctx.lineWidth = 2
                    ctx.beginPath()
                    ctx.moveTo(w * 0.04, 0)
                    ctx.lineTo(w * 0.96, 0)
                    ctx.lineTo(w * 0.76, h)
                    ctx.lineTo(w * 0.50, h * 0.55)
                    ctx.lineTo(w * 0.24, h)
                    ctx.closePath()
                    ctx.fill()
                    ctx.shadowBlur = 0
                    ctx.stroke()
                }
            }
        }
    }
}
