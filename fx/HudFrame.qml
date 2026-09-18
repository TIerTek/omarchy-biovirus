// BioVirus — containment HUD: corner brackets, status header, telemetry feet.
import QtQuick

Item {
  id: root

  property bool active: true
  property real intensity: 1.0
  property color tint: "#4bffa5"
  property color dim: "#2e8f63"
  property color alarm: "#ff4d5e"
  property string fontFamily: "JetBrainsMono Nerd Font"
  property int baseFontSize: 13
  property real margin: 34
  // Flipped by the consumer on auth failure; turns the HUD red and rewrites
  // the status line.
  property bool breached: false

  readonly property real k: Math.max(0, Math.min(1, intensity))
  readonly property color live: breached ? alarm : tint
  readonly property int bracket: 26
  readonly property int stroke: 2

  // Slow breathing applied to the whole frame. Held at full opacity when the
  // animation is throttled off, so the HUD never simply disappears.
  property real breathe: 1.0
  SequentialAnimation on breathe {
    running: root.active && root.k > 0 && !root.breached
    loops: Animation.Infinite
    NumberAnimation { from: 0.62; to: 1.0; duration: 2400; easing.type: Easing.InOutSine }
    NumberAnimation { from: 1.0; to: 0.62; duration: 2400; easing.type: Easing.InOutSine }
  }
  onActiveChanged: if (!active) breathe = 1.0
  onBreachedChanged: if (breached) breathe = 1.0

  component Bracket: Item {
    property color color: root.live
    property bool flipH: false
    property bool flipV: false
    width: root.bracket
    height: root.bracket
    Rectangle {
      width: parent.width; height: root.stroke; color: parent.color
      anchors.left: parent.flipH ? undefined : parent.left
      anchors.right: parent.flipH ? parent.right : undefined
      anchors.top: parent.flipV ? undefined : parent.top
      anchors.bottom: parent.flipV ? parent.bottom : undefined
    }
    Rectangle {
      width: root.stroke; height: parent.height; color: parent.color
      anchors.left: parent.flipH ? undefined : parent.left
      anchors.right: parent.flipH ? parent.right : undefined
      anchors.top: parent.flipV ? undefined : parent.top
      anchors.bottom: parent.flipV ? parent.bottom : undefined
    }
  }

  Item {
    id: frame
    anchors.fill: parent
    anchors.margins: root.margin
    opacity: 0.42 + 0.48 * root.breathe

    Bracket { anchors.left: parent.left;  anchors.top: parent.top }
    Bracket { anchors.right: parent.right; anchors.top: parent.top; flipH: true }
    Bracket { anchors.left: parent.left;  anchors.bottom: parent.bottom; flipV: true }
    Bracket { anchors.right: parent.right; anchors.bottom: parent.bottom; flipH: true; flipV: true }

    // ── header ────────────────────────────────────────────────────────────
    Row {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.leftMargin: root.bracket + 14
      anchors.topMargin: -2
      spacing: 10

      Text {
        text: "⬢"
        color: root.live
        font.family: root.fontFamily
        font.pixelSize: root.baseFontSize + 2
      }
      Text {
        text: root.breached ? "CONTAINMENT  BREACH" : "BIOHAZARD   LVL-4   CONTAINED"
        color: root.live
        font.family: root.fontFamily
        font.pixelSize: root.baseFontSize
        font.letterSpacing: 2
        font.bold: root.breached
      }
    }

    // ── telemetry ─────────────────────────────────────────────────────────
    Column {
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      anchors.leftMargin: root.bracket + 14
      anchors.bottomMargin: 2
      spacing: 5

      Text {
        text: "> strain......biovirus/4bffa5"
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: root.baseFontSize - 1
      }

      Row {
        spacing: 8
        Text {
          text: "> integrity..."
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: root.baseFontSize - 1
          anchors.verticalCenter: parent.verticalCenter
        }
        Rectangle {
          width: 168; height: 7
          color: "transparent"
          border.color: root.dim
          border.width: 1
          anchors.verticalCenter: parent.verticalCenter
          Rectangle {
            id: bar
            anchors.left: parent.left
            anchors.leftMargin: 1
            anchors.verticalCenter: parent.verticalCenter
            height: 3
            width: (parent.width - 2) * (root.breached ? 0.17 : 0.87)
            color: root.live
            Behavior on width { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
          }
        }
        Text {
          text: (root.breached ? "17" : "87") + "%"
          color: root.live
          font.family: root.fontFamily
          font.pixelSize: root.baseFontSize - 1
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }

    // ── clock, right foot ─────────────────────────────────────────────────
    Text {
      id: stamp
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.rightMargin: root.bracket + 14
      anchors.bottomMargin: 2
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: root.baseFontSize - 1
      text: Qt.formatDateTime(new Date(), "yyyy-MM-dd  hh:mm:ss")

      Timer {
        interval: 1000
        running: root.active
        repeat: true
        onTriggered: stamp.text = Qt.formatDateTime(new Date(), "yyyy-MM-dd  hh:mm:ss")
      }
    }
  }
}
