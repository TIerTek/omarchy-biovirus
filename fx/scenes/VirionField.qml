// BioVirus — drifting virion field, for biovirus-virions.png.
// Pure QtQuick like the rest of fx/, so the file would also run inside the
// SDDM greeter, which cannot see Quickshell's qs.Commons / qs.Ui modules.
import QtQuick

Item {
  id: root

  property bool active: true
  property real intensity: 1.0
  property color tint: "#4bffa5"
  property color cool: "#4be0ff"

  readonly property real k: Math.max(0, Math.min(1, intensity))
  readonly property int count: 13
  readonly property int cols: 5
  readonly property int rows: 3

  // Deterministic jitter: a reload must not reshuffle the field, and seeding
  // off the index costs nothing.
  function rnd(i, salt) {
    var x = Math.sin((i + 1) * 12.9898 + salt * 78.233) * 43758.5453
    return x - Math.floor(x)
  }

  Repeater {
    model: root.count

    // Each virion is painted ONCE into its own small Canvas and then moved by
    // animations. Repainting one full-screen Canvas every frame would drag the
    // whole field onto the CPU; transforming a dozen cached textures does not.
    Item {
      id: virion
      required property int index

      // Three depth planes: the far ones are larger, dimmer and slower, which
      // is what sells depth without an actual blur pass.
      readonly property int band: index % 3
      readonly property real coreR: (30 + band * 24) * (0.8 + root.rnd(index, 7) * 0.55)
      readonly property real spikeLen: coreR * 0.22
      // Jittered grid rather than raw hash positions: 13 unconstrained random
      // points clump, and a clumped field looks like a mistake rather than a
      // specimen spread.
      readonly property real homeX: ((index % root.cols) + 0.15 + root.rnd(index, 1) * 0.7)
                                    * (root.width / root.cols) - width / 2
      readonly property real homeY: (Math.floor(index / root.cols) + 0.15 + root.rnd(index, 2) * 0.7)
                                    * (root.height / root.rows) - height / 2
      readonly property real driftX: (40 + root.rnd(index, 3) * 90) * (0.4 + root.k * 0.6)
      readonly property real driftY: (26 + root.rnd(index, 4) * 70) * (0.4 + root.k * 0.6)
      readonly property int periodX: 34000 + Math.round(root.rnd(index, 5) * 40000)
      readonly property int periodY: 27000 + Math.round(root.rnd(index, 6) * 46000)

      width: (coreR + spikeLen) * 2.4
      height: width
      x: homeX
      y: homeY
      visible: root.active && root.k > 0
      opacity: (0.13 + band * 0.10) * root.k

      Behavior on opacity { NumberAnimation { duration: 600 } }

      // The size guard is load-bearing. `SequentialAnimation on x` seizes the
      // property from its homeX binding the moment it starts, freezing whatever
      // width was known then — and under an asynchronous Loader (the lock
      // screen) the scene is built before the panel has a size, so every virion
      // computed from width 0 and piled into the top-left corner. It only
      // un-piled on the next loop, up to 74 s later.
      SequentialAnimation on x {
        running: root.active && root.k > 0 && root.width > 0 && root.height > 0
        loops: Animation.Infinite
        NumberAnimation {
          from: virion.homeX - virion.driftX; to: virion.homeX + virion.driftX
          duration: virion.periodX; easing.type: Easing.InOutSine
        }
        NumberAnimation {
          from: virion.homeX + virion.driftX; to: virion.homeX - virion.driftX
          duration: virion.periodX; easing.type: Easing.InOutSine
        }
      }

      SequentialAnimation on y {
        running: root.active && root.k > 0 && root.width > 0 && root.height > 0
        loops: Animation.Infinite
        NumberAnimation {
          from: virion.homeY + virion.driftY; to: virion.homeY - virion.driftY
          duration: virion.periodY; easing.type: Easing.InOutSine
        }
        NumberAnimation {
          from: virion.homeY - virion.driftY; to: virion.homeY + virion.driftY
          duration: virion.periodY; easing.type: Easing.InOutSine
        }
      }

      // Animator, not NumberAnimation: rotation runs on the render thread and
      // keeps turning even when the UI thread is busy.
      RotationAnimator on rotation {
        running: root.active && root.k > 0
        loops: Animation.Infinite
        from: 0
        to: virion.index % 2 === 0 ? 360 : -360
        duration: 120000 + virion.index * 9000
      }

      // Breathing capsid — slight, or it reads as a pulsing button.
      SequentialAnimation on scale {
        running: root.active && root.k > 0
        loops: Animation.Infinite
        NumberAnimation {
          from: 0.94; to: 1.06
          duration: 7000 + virion.index * 900; easing.type: Easing.InOutSine
        }
        NumberAnimation {
          from: 1.06; to: 0.94
          duration: 7000 + virion.index * 900; easing.type: Easing.InOutSine
        }
      }

      Canvas {
        id: art
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        property color capsid: virion.index % 4 === 0 ? root.cool : root.tint

        onPaint: {
          var ctx = getContext("2d")
          ctx.reset()
          var cx = width / 2
          var cy = height / 2
          var r = virion.coreR
          var c = capsid
          var spikes = 20 + virion.band * 8

          ctx.lineWidth = 2
          ctx.strokeStyle = Qt.rgba(c.r, c.g, c.b, 0.85)
          ctx.beginPath()
          ctx.arc(cx, cy, r, 0, Math.PI * 2)
          ctx.stroke()

          ctx.lineWidth = 1
          ctx.strokeStyle = Qt.rgba(c.r, c.g, c.b, 0.45)
          ctx.beginPath()
          ctx.arc(cx, cy, r * 0.62, 0, Math.PI * 2)
          ctx.stroke()

          // Nucleocapsid smudge, so the middle is not a hole.
          ctx.fillStyle = Qt.rgba(c.r, c.g, c.b, 0.12)
          ctx.beginPath()
          ctx.arc(cx, cy, r * 0.44, 0, Math.PI * 2)
          ctx.fill()

          for (var i = 0; i < spikes; i++) {
            var a = (Math.PI * 2 * i) / spikes
            var sx = cx + Math.cos(a) * r
            var sy = cy + Math.sin(a) * r
            var ex = cx + Math.cos(a) * (r + virion.spikeLen)
            var ey = cy + Math.sin(a) * (r + virion.spikeLen)
            ctx.lineWidth = 2
            ctx.strokeStyle = Qt.rgba(c.r, c.g, c.b, 0.7)
            ctx.beginPath()
            ctx.moveTo(sx, sy)
            ctx.lineTo(ex, ey)
            ctx.stroke()
            ctx.fillStyle = Qt.rgba(c.r, c.g, c.b, 0.8)
            ctx.beginPath()
            ctx.arc(ex, ey, Math.max(1.6, virion.spikeLen * 0.22), 0, Math.PI * 2)
            ctx.fill()
          }
        }

        onWidthChanged: requestPaint()
        onCapsidChanged: requestPaint()
      }
    }
  }
}
