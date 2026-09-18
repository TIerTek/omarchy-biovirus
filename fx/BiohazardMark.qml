// BioVirus — the biohazard trefoil, as a badge.
//
// Nerd Font U+F00A7 (nf-md-biohazard) drawn from the system JetBrainsMono NF,
// so it is vector-true at any size and needs no image file (the SDDM greeter
// cannot read ~/.config, and a PNG here would be a second blob to keep in sync).
// The codepoint is a \u escape on purpose — a literal PUA glyph does not
// reliably survive an editor round-trip (see the fastfetch notes).
import QtQuick 2.0

Item {
  id: root
  property color tint:   "#4bffa5"
  property color dim:    "#2e8f63"
  property color alarm:  "#ff4d5e"
  property bool breached: false
  property bool active:   true
  property string fontFamily: "JetBrainsMono Nerd Font"

  width: 150
  height: 150

  readonly property color ink: breached ? alarm : tint
  readonly property string glyph: "󰂧"

  // Soft bloom: the same glyph, larger and faint, breathing behind the mark.
  Text {
    id: halo
    anchors.centerIn: parent
    text: root.glyph
    color: root.ink
    font.family: root.fontFamily
    font.pixelSize: root.height * 0.78
    opacity: 0.22
    scale: 1.08
    SequentialAnimation on opacity {
      running: root.active && root.height > 0
      loops: Animation.Infinite
      NumberAnimation { to: 0.32; duration: 2600; easing.type: Easing.InOutSine }
      NumberAnimation { to: 0.18; duration: 2600; easing.type: Easing.InOutSine }
    }
  }

  // Containment ring with a slow, ticking bezel.
  Rectangle {
    id: ring
    anchors.centerIn: parent
    width: root.width
    height: root.height
    radius: width / 2
    color: "transparent"
    border.color: root.dim
    border.width: 2
    opacity: 0.7

    Repeater {
      model: 36
      Rectangle {
        required property int index
        width: 2
        height: index % 3 === 0 ? 10 : 5
        color: root.dim
        x: ring.width / 2 - width / 2
        y: 0
        transformOrigin: Item.Center
        transform: Rotation {
          origin.x: 1
          origin.y: ring.height / 2
          angle: index * 10
        }
      }
    }

    RotationAnimation on rotation {
      running: root.active && root.height > 0
      loops: Animation.Infinite
      from: 0; to: 360
      duration: 90000
    }
  }

  Text {
    anchors.centerIn: parent
    text: root.glyph
    color: root.ink
    font.family: root.fontFamily
    font.pixelSize: root.height * 0.66
  }
}
