// BioVirus — a run in progress, for biovirus-sequencer.png.
// A double helix winds down the lane block while base calls type into the
// panel the plate leaves empty. Every position here is a fraction of the
// panel, matching the fractions make-plates.py draws with, so the live parts
// land inside the printed furniture.
// Pure QtQuick, like the rest of fx/, so it would also run in the SDDM greeter.
import QtQuick

Item {
  id: root

  property bool active: true
  property real intensity: 1.0
  property color tint: "#4bffa5"
  property color cool: "#4be0ff"
  property string fontFamily: "JetBrainsMono Nerd Font"

  readonly property real k: Math.max(0, Math.min(1, intensity))

  // Readout panel — mirrors plate_sequencer()'s panel rectangle.
  readonly property real px0: width * 0.06
  readonly property real py0: height * 0.115
  readonly property real px1: width * 0.44
  readonly property real bodyFont: height * 0.01667
  readonly property real headFont: height * 0.01333
  readonly property int lineCount: 11

  // Lane block the helix winds down — mirrors the plate's lane guides.
  readonly property real laneTop: height * 0.09
  readonly property real laneBottom: height * 0.62
  readonly property real laneCx: width * 0.73
  readonly property real laneAmp: width * 0.095
  // Dense enough that consecutive strand dots read as a curve rather than a
  // scatter: with too few pairs per turn the helix just looks like a ladder.
  // 40 is the point where the strands still read as curves; every extra
  // pair is three more items rebinding off `phase` on every frame, and this
  // scene was measurably the most expensive of the four at 56.
  readonly property int pairs: 40
  readonly property real turns: 1.6

  property var lines: []
  property int readCount: 0

  function pad(n, width) {
    var s = String(n)
    while (s.length < width) s = "0" + s
    return s
  }

  function call() {
    var bases = "ACGT"
    var out = ""
    for (var g = 0; g < 4; g++) {
      for (var i = 0; i < 4; i++)
        out += bases.charAt(Math.floor(Math.random() * 4))
      out += g === 0 ? "  " : " "
    }
    return out.replace(/\s+$/, "")
  }

  Timer {
    running: root.active && root.k > 0
    interval: 620
    repeat: true
    onTriggered: {
      var next = root.lines.slice(0, root.lineCount - 1)
      next.unshift(root.call())
      root.lines = next
      root.readCount += 4
    }
  }

  // ── base calls ─────────────────────────────────────────────────────────
  // Fixed delegate count, not `model: root.lines`: binding the model to the
  // array meant every tick destroyed and rebuilt all eleven Text items, which
  // measured as the most expensive thing in any of the four scenes. Now only
  // the strings change.
  Repeater {
    model: root.lineCount

    Text {
      required property int index

      x: root.px0 + root.width * 0.015
      y: root.py0 + root.height * 0.040 * (index + 1)
      text: root.lines[index] !== undefined ? root.lines[index] : ""
      font.family: root.fontFamily
      font.pixelSize: root.bodyFont
      color: root.tint
      // Newest line brightest: the ramp is what makes it read as a feed
      // rather than a static block of text.
      opacity: root.k * (0.85 - index * 0.062)
      visible: root.active && root.k > 0
    }
  }

  Text {
    x: root.px1 - root.width * 0.052
    y: root.py0 + root.height * 0.007
    text: "Q " + (36 + (root.readCount % 40) / 10).toFixed(1)
    font.family: root.fontFamily
    font.pixelSize: root.headFont
    color: root.cool
    opacity: root.k * 0.8
    visible: root.active && root.k > 0
  }

  Text {
    x: root.px0
    y: root.height * 0.645
    text: "READ " + root.pad(root.readCount, 7) + "  bp"
    font.family: root.fontFamily
    font.pixelSize: root.headFont
    color: root.tint
    opacity: root.k * 0.7
    visible: root.active && root.k > 0
  }

  // ── helix ──────────────────────────────────────────────────────────────
  property real phase: 0
  property real scroll: 0

  NumberAnimation on phase {
    running: root.active && root.k > 0
    loops: Animation.Infinite
    from: 0; to: Math.PI * 2
    duration: 17000
  }

  NumberAnimation on scroll {
    running: root.active && root.k > 0
    loops: Animation.Infinite
    from: 0; to: 1
    duration: 21000
  }

  Repeater {
    model: root.pairs

    Item {
      id: pair
      required property int index

      // Position along the lane block, wrapping as the run scrolls.
      readonly property real t: (index / root.pairs + root.scroll) % 1
      readonly property real angle: root.phase + t * root.turns * 2 * Math.PI
      readonly property real s: Math.sin(angle)
      readonly property real depth: Math.cos(angle)
      readonly property real xa: root.laneCx + root.laneAmp * s
      readonly property real xb: root.laneCx - root.laneAmp * s

      y: root.laneTop + t * (root.laneBottom - root.laneTop)
      visible: root.active && root.k > 0
      // Fade at both ends of the block so pairs do not pop in and out.
      opacity: root.k * (t < 0.07 ? t / 0.07 : t > 0.93 ? (1 - t) / 0.07 : 1)

      // Rung. Thin, and dimmest when the pair is edge-on to us.
      Rectangle {
        x: Math.min(pair.xa, pair.xb)
        y: -1
        width: Math.abs(pair.xa - pair.xb)
        height: 2
        color: root.tint
        opacity: 0.05 + 0.10 * Math.abs(pair.s)
      }

      // The two strands. The one in front is bigger and brighter — that is
      // the entire depth cue.
      Rectangle {
        x: pair.xa - width / 2
        y: -width / 2
        width: 4 + 4.5 * (pair.depth + 1) / 2
        height: width
        radius: width / 2
        color: root.tint
        opacity: 0.3 + 0.6 * (pair.depth + 1) / 2
      }

      Rectangle {
        x: pair.xb - width / 2
        y: -width / 2
        width: 4 + 4.5 * (1 - pair.depth) / 2
        height: width
        radius: width / 2
        color: root.cool
        opacity: 0.25 + 0.55 * (1 - pair.depth) / 2
      }
    }
  }

  // ── read head ──────────────────────────────────────────────────────────
  Rectangle {
    id: head
    x: root.width * 0.50
    width: root.width * 0.45
    height: Math.max(2, root.height * 0.0022)
    visible: root.active && root.k > 0
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop { position: 0.5; color: Qt.rgba(root.cool.r, root.cool.g, root.cool.b, 0.55 * root.k) }
      GradientStop { position: 1.0; color: "transparent" }
    }

    SequentialAnimation on y {
      running: root.active && root.k > 0
      loops: Animation.Infinite
      NumberAnimation {
        from: root.laneTop; to: root.laneBottom
        duration: 6400; easing.type: Easing.InOutSine
      }
      PauseAnimation { duration: 1800 }
    }
  }
}
