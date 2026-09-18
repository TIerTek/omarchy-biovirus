// BioVirus — a colony dividing, for biovirus-mitosis.png.
// Cells swell, pinch and split on long staggered loops, then the daughters
// fade out and the cell re-seeds somewhere else. Pure QtQuick, like the rest
// of fx/, so the file would also run inside the SDDM greeter.
import QtQuick

Item {
  id: root

  property bool active: true
  property real intensity: 1.0
  property color tint: "#4bffa5"
  property color cool: "#4be0ff"

  readonly property real k: Math.max(0, Math.min(1, intensity))
  readonly property int count: 7
  // One full swell → pinch → split → fade cycle. Deliberately slow: this is
  // wallpaper, and anything faster turns into a screensaver.
  readonly property int cycle: 46000

  function rnd(i, salt) {
    var x = Math.sin((i + 1) * 34.7891 + salt * 21.317) * 27183.315
    return x - Math.floor(x)
  }

  // Both daughters ride one mirrored `pinch` value — that is the whole trick,
  // no per-lobe bookkeeping. Declared at document root because inline
  // components cannot be nested inside a delegate.
  component Lobe: Item {
    id: lobe

    property real dir: 1
    property real cellR: 40
    property real pinch: 0
    property real swell: 1
    property color tint: "#4bffa5"
    property color cool: "#4be0ff"

    anchors.centerIn: parent
    anchors.horizontalCenterOffset: dir * pinch * cellR * 0.72
    width: cellR * 2 * swell
    height: width

    // Halo: three nested translucent discs instead of a blur pass.
    Rectangle {
      anchors.centerIn: parent
      width: parent.width * 1.5; height: width; radius: width / 2
      color: Qt.rgba(lobe.tint.r, lobe.tint.g, lobe.tint.b, 0.025)
    }
    Rectangle {
      anchors.centerIn: parent
      width: parent.width * 1.18; height: width; radius: width / 2
      color: Qt.rgba(lobe.tint.r, lobe.tint.g, lobe.tint.b, 0.035)
    }
    Rectangle {
      anchors.fill: parent
      radius: width / 2
      color: Qt.rgba(lobe.tint.r, lobe.tint.g, lobe.tint.b, 0.05)
      border.width: 2
      border.color: Qt.rgba(lobe.tint.r, lobe.tint.g, lobe.tint.b, 0.55)
    }
    // Nucleus, pulled toward the outside once the split is under way.
    Rectangle {
      anchors.centerIn: parent
      anchors.horizontalCenterOffset: lobe.dir * lobe.pinch * lobe.cellR * 0.16
      width: parent.width * 0.3; height: width; radius: width / 2
      color: Qt.rgba(lobe.cool.r, lobe.cool.g, lobe.cool.b, 0.30)
    }
  }

  Repeater {
    model: root.count

    Item {
      id: cell
      required property int index

      readonly property real r: 34 + root.rnd(index, 1) * 56
      // 0 = a single body, 1 = two fully separated daughters.
      property real pinch: 0
      property real swell: 0.62

      width: r * 2
      height: r * 2
      x: root.rnd(index, 2) * Math.max(1, root.width - width)
      y: root.rnd(index, 3) * Math.max(1, root.height - height)
      visible: root.active && root.k > 0
      opacity: 0

      Lobe {
        dir: -1
        cellR: cell.r; pinch: cell.pinch; swell: cell.swell
        tint: root.tint; cool: root.cool
      }
      Lobe {
        dir: 1
        cellR: cell.r; pinch: cell.pinch; swell: cell.swell
        tint: root.tint; cool: root.cool
      }

      // Cytoplasmic bridge: only there while the lobes are pulling apart.
      Rectangle {
        anchors.centerIn: parent
        width: Math.max(1, cell.pinch * cell.r * 1.44)
        height: Math.max(1, cell.r * 0.5 * (1 - cell.pinch))
        radius: height / 2
        visible: cell.pinch > 0.05 && cell.pinch < 0.9
        color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.16 * (1 - cell.pinch))
      }

      SequentialAnimation {
        running: root.active && root.k > 0
        loops: Animation.Infinite

        PauseAnimation { duration: cell.index * Math.round(root.cycle / root.count) }
        NumberAnimation { target: cell; property: "opacity"; to: 0.9; duration: 2600 }
        // Interphase: the cell just gets fatter.
        NumberAnimation {
          target: cell; property: "swell"; from: 0.62; to: 1.0
          duration: Math.round(root.cycle * 0.45); easing.type: Easing.InOutSine
        }
        // Cytokinesis.
        NumberAnimation {
          target: cell; property: "pinch"; from: 0; to: 1
          duration: Math.round(root.cycle * 0.24); easing.type: Easing.InOutCubic
        }
        PauseAnimation { duration: Math.round(root.cycle * 0.2) }
        NumberAnimation { target: cell; property: "opacity"; to: 0; duration: 3200 }
        // Re-seed elsewhere so the field never settles into a fixed pattern.
        ScriptAction {
          script: {
            cell.pinch = 0
            cell.swell = 0.62
            cell.x = Math.random() * Math.max(1, root.width - cell.width)
            cell.y = Math.random() * Math.max(1, root.height - cell.height)
          }
        }
      }

    }
  }

  // Replication burst: one expanding ring, occasionally, somewhere random.
  Rectangle {
    id: burst
    width: 220; height: 220; radius: width / 2
    color: "transparent"
    border.width: 2
    border.color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.5)
    opacity: 0
    scale: 0.2
    visible: root.active && root.k > 0
  }

  Timer {
    running: root.active && root.k > 0
    interval: 38000
    repeat: true
    onTriggered: {
      burst.x = Math.random() * Math.max(1, root.width - burst.width)
      burst.y = Math.random() * Math.max(1, root.height - burst.height)
      burstAnim.restart()
    }
  }

  ParallelAnimation {
    id: burstAnim
    NumberAnimation {
      target: burst; property: "scale"; from: 0.2; to: 3.4
      duration: 5200; easing.type: Easing.OutCubic
    }
    SequentialAnimation {
      NumberAnimation { target: burst; property: "opacity"; to: 0.55; duration: 700 }
      NumberAnimation { target: burst; property: "opacity"; to: 0; duration: 4500 }
    }
  }
}
