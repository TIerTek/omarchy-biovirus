// BioVirus — containment breach, for biovirus-outbreak.png.
// The plate draws the facility grid and cold nodes; this lights them up:
// ring pulses, packets running the vectors, and the HUD in its alarm state.
// Node fractions match plate_outbreak() so the pulses sit on the printed marks.
// Pure QtQuick plus the sibling HudFrame, so it would also run in SDDM.
import QtQuick
import ".."

Item {
  id: root

  property bool active: true
  property real intensity: 1.0
  property color tint: "#4bffa5"
  property color alarm: "#ff4d5e"
  property color warn: "#ff8f4d"
  // The desktop background has no HUD of its own, so this scene supplies one.
  // The LOCK SCREEN already draws a HudFrame — leaving this on there stacks two
  // frames and the header text renders on top of itself, unreadable. Consumers
  // that own a frame set this false.
  property bool hudEnabled: true

  readonly property real k: Math.max(0, Math.min(1, intensity))
  readonly property var nodes: [
    { fx: 0.24, fy: 0.34 }, { fx: 0.47, fy: 0.58 }, { fx: 0.68, fy: 0.28 },
    { fx: 0.79, fy: 0.66 }, { fx: 0.38, fy: 0.78 }
  ]
  readonly property int indexCase: 1

  // Declared at document root: inline components cannot live inside a
  // delegate. Everything it needs is a property, nothing reaches upward.
  component Pulse: Rectangle {
    id: ring

    property bool run: false
    property int delay: 0
    property real baseSize: 110
    property real maxScale: 2.4
    property int period: 5200
    property real peak: 0.35
    property color hue: "#4bffa5"

    anchors.centerIn: parent
    width: baseSize
    height: baseSize
    radius: baseSize / 2
    color: "transparent"
    border.width: 2
    border.color: hue
    opacity: 0
    scale: 0.25

    SequentialAnimation {
      running: ring.run
      loops: Animation.Infinite
      PauseAnimation { duration: ring.delay }
      ParallelAnimation {
        NumberAnimation {
          target: ring; property: "scale"; from: 0.25; to: ring.maxScale
          duration: ring.period; easing.type: Easing.OutCubic
        }
        SequentialAnimation {
          NumberAnimation { target: ring; property: "opacity"; to: ring.peak; duration: 500 }
          NumberAnimation {
            target: ring; property: "opacity"; to: 0
            duration: Math.max(300, ring.period - 500)
          }
        }
      }
    }
  }

  // ── packets running the vectors ────────────────────────────────────────
  Repeater {
    model: root.nodes.length - 1

    Rectangle {
      id: packet
      required property int index

      readonly property var a: root.nodes[index]
      readonly property var b: root.nodes[index + 1]
      readonly property bool hot: index === root.indexCase || index + 1 === root.indexCase

      width: 7; height: 7; radius: 3.5
      color: hot ? root.alarm : root.tint
      opacity: root.k * 0.85
      visible: root.active && root.k > 0

      PathAnimation {
        running: root.active && root.k > 0
        loops: Animation.Infinite
        target: packet
        duration: 7000 + packet.index * 1900
        easing.type: Easing.InOutSine
        path: Path {
          startX: packet.a.fx * root.width - packet.width / 2
          startY: packet.a.fy * root.height - packet.height / 2
          PathLine {
            x: packet.b.fx * root.width - packet.width / 2
            y: packet.b.fy * root.height - packet.height / 2
          }
        }
      }
    }
  }

  // ── node pulses ────────────────────────────────────────────────────────
  Repeater {
    model: root.nodes.length

    Item {
      id: node
      required property int index

      readonly property bool hot: index === root.indexCase
      readonly property color hue: hot ? root.alarm : root.tint

      x: root.nodes[index].fx * root.width
      y: root.nodes[index].fy * root.height
      visible: root.active && root.k > 0

      // Two rings per site, offset in time, so it never goes quiet.
      Pulse {
        run: root.active && root.k > 0
        hue: node.hue
        delay: node.index * 640
        baseSize: node.hot ? 150 : 110
        maxScale: node.hot ? 3.2 : 2.4
        period: node.hot ? 3600 : 5200
        peak: (node.hot ? 0.6 : 0.35) * root.k
      }
      Pulse {
        run: root.active && root.k > 0
        hue: node.hue
        delay: node.index * 640 + (node.hot ? 1800 : 2600)
        baseSize: node.hot ? 150 : 110
        maxScale: node.hot ? 3.2 : 2.4
        period: node.hot ? 3600 : 5200
        peak: (node.hot ? 0.6 : 0.35) * root.k
      }

      // Core, breathing. The index case runs hotter and faster.
      Rectangle {
        anchors.centerIn: parent
        width: node.hot ? 15 : 11; height: width; radius: width / 2
        color: node.hue

        SequentialAnimation on opacity {
          running: root.active && root.k > 0
          loops: Animation.Infinite
          NumberAnimation { to: root.k * 0.95; duration: node.hot ? 620 : 1900 }
          NumberAnimation { to: root.k * 0.35; duration: node.hot ? 620 : 1900 }
        }
      }
    }
  }

  // ── contamination front ────────────────────────────────────────────────
  // A slow warm wash crossing the map. Deliberately horizontal: it was written
  // when Scanlines still ran a vertical sweep over the top, and a second one
  // would have read as a duplicate. That sweep is off as of 2026-09-07
  // (`Scanlines.sweepEnabled`), so this is now the only travelling element —
  // keep it horizontal anyway if the sweep is ever switched back on.
  Rectangle {
    id: front
    width: root.width * 0.36
    height: root.height
    visible: root.active && root.k > 0
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop {
        position: 0.5
        color: Qt.rgba(root.warn.r, root.warn.g, root.warn.b, 0.035 * root.k)
      }
      GradientStop { position: 1.0; color: "transparent" }
    }

    SequentialAnimation on x {
      running: root.active && root.k > 0
      loops: Animation.Infinite
      NumberAnimation {
        from: -front.width; to: root.width
        duration: 26000; easing.type: Easing.InOutSine
      }
      PauseAnimation { duration: 5000 }
    }
  }

  // The lock screen's HUD, reused in its alarm state.
  HudFrame {
    anchors.fill: parent
    visible: root.hudEnabled
    active: root.active && root.hudEnabled
    intensity: root.intensity * 0.85
    tint: root.tint
    alarm: root.alarm
    breached: true
  }
}
