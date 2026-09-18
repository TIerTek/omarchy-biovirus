// BioVirus — CRT scanlines plus a slow travelling sweep.
import QtQuick

Item {
  id: root

  property bool active: true
  property real intensity: 1.0
  property color tint: "#4bffa5"
  property int lineSpacing: 3
  // The travelling sweep, OFF since 2026-09-07 — Charles found the soft band
  // crossing the desktop distracting once the animated backgrounds landed. The
  // static CRT grid below is unaffected. Flip this to true to bring it back.
  property bool sweepEnabled: false

  readonly property real k: Math.max(0, Math.min(1, intensity))

  // One painted canvas rather than a Repeater of Rectangles: at this panel's
  // height a 3px grid is ~600 QQuickItems, all of them static.
  Canvas {
    id: grid
    anchors.fill: parent
    visible: root.active && root.k > 0
    opacity: 0.5 * root.k
    renderStrategy: Canvas.Cooperative

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      ctx.fillStyle = "rgba(0,0,0,0.24)"
      for (var y = 0; y < height; y += root.lineSpacing)
        ctx.fillRect(0, y, width, 1)
    }

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    Connections {
      target: root
      function onLineSpacingChanged() { grid.requestPaint() }
    }
  }

  // Travelling sweep. Written to make the grid feel alive rather than printed,
  // and disabled by default — see `sweepEnabled` above. Gated on that flag in
  // BOTH places: `visible` alone would leave the animation running invisibly.
  Rectangle {
    id: sweep
    width: parent.width
    height: Math.max(80, parent.height * 0.14)
    visible: root.sweepEnabled && root.active && root.k > 0
    gradient: Gradient {
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop { position: 0.5; color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.05 * root.k) }
      GradientStop { position: 1.0; color: "transparent" }
    }

    SequentialAnimation on y {
      running: root.sweepEnabled && root.active && root.k > 0
      loops: Animation.Infinite
      NumberAnimation {
        from: -sweep.height
        to: root.height
        duration: Math.round(7000 / Math.max(0.15, root.k))
        easing.type: Easing.InOutSine
      }
      PauseAnimation { duration: 2600 }
    }
  }
}
