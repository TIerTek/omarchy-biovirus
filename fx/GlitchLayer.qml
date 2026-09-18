// BioVirus — failure glitch: horizontal tear bands, chromatic wash, shake.
//
// Deliberately does NOT sample its backdrop. An RGB-split via
// ShaderEffectSource would need a live texture of whatever sits behind it,
// which on the lock screen is the wallpaper *and* the password card — capturing
// that every frame is exactly the wrong thing to do in a component that only
// runs for 500ms. Slab tears read as a glitch and cost nothing when idle.
import QtQuick

Item {
  id: root

  property color tint: "#4bffa5"
  property color alarm: "#ff4d5e"
  property color chroma: "#4be0ff"
  // Optional: an Item to jolt sideways while the glitch runs.
  property Item shakeTarget: null

  property bool running: false
  readonly property int bands: 7

  visible: running
  // Never eat clicks — the password field sits underneath.
  enabled: false

  signal finished()

  function fire() {
    if (running) burst.stop()
    for (var i = 0; i < bandRepeater.count; i++) {
      var b = bandRepeater.itemAt(i)
      if (!b) continue
      b.y = Math.random() * Math.max(1, root.height)
      b.height = 3 + Math.random() * 26
      b.shift = (Math.random() * 2 - 1) * 42
    }
    running = true
    burst.restart()
  }

  Repeater {
    id: bandRepeater
    model: root.bands

    Rectangle {
      property real shift: 0
      x: shift
      width: root.width
      height: 12
      color: index % 3 === 0 ? root.alarm : (index % 3 === 1 ? root.chroma : root.tint)
      opacity: 0.0

      SequentialAnimation on opacity {
        running: root.running
        loops: 2
        NumberAnimation { to: 0.30; duration: 55 }
        NumberAnimation { to: 0.0;  duration: 90 }
      }
    }
  }

  // Red containment wash over the whole surface.
  Rectangle {
    id: wash
    anchors.fill: parent
    color: root.alarm
    opacity: 0.0
    SequentialAnimation on opacity {
      running: root.running
      NumberAnimation { to: 0.14; duration: 70 }
      NumberAnimation { to: 0.0;  duration: 380; easing.type: Easing.OutCubic }
    }
  }

  SequentialAnimation {
    id: burst

    ParallelAnimation {
      SequentialAnimation {
        // Sideways jolt, only if the consumer handed us something to shake.
        NumberAnimation {
          target: root.shakeTarget; property: "x"
          to: (root.shakeTarget ? root.shakeTarget.x : 0) + 9
          duration: 45; easing.type: Easing.OutQuad
        }
        NumberAnimation {
          target: root.shakeTarget; property: "x"
          to: (root.shakeTarget ? root.shakeTarget.x : 0) - 7
          duration: 55; easing.type: Easing.InOutQuad
        }
        NumberAnimation {
          target: root.shakeTarget; property: "x"
          to: (root.shakeTarget ? root.shakeTarget.x : 0)
          duration: 70; easing.type: Easing.OutBack
        }
      }
      PauseAnimation { duration: 470 }
    }

    ScriptAction {
      script: {
        root.running = false
        root.finished()
      }
    }
  }
}
