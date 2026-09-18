import QtQuick
import QtQuick.Window
import "../fx"

Window {
  id: win
  width: 1440; height: 900
  visible: true
  title: "BioVirus FX harness"
  color: "#04080a"

  Image {
    anchors.fill: parent
    source: Qt.resolvedUrl("../theme/backgrounds/biovirus-containment.png")
    fillMode: Image.PreserveAspectCrop
    asynchronous: false
  }

  SporeField { anchors.fill: parent; intensity: 1.0 }
  Scanlines  { anchors.fill: parent; intensity: 1.0 }
  HudFrame   { id: hud; anchors.fill: parent; breached: win.breached }

  property bool breached: false

  // Mock password card, so the composition is judged as it will actually look.
  Rectangle {
    id: card
    width: 381; height: 67
    anchors.centerIn: parent
    color: "#04080a"
    opacity: 0.72
    radius: 6
    border.color: win.breached ? "#ff4d5e" : "#4bffa5"
    border.width: 3
    Text {
      anchors.centerIn: parent
      text: "●●●●●●●●"
      color: "#eafff5"
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 24
      font.letterSpacing: 6
    }
  }

  GlitchLayer { id: glitch; anchors.fill: parent; shakeTarget: card }

  // Fire the failure state on a timer so the harness exercises it unattended.
  Timer {
    interval: 3000; running: true; repeat: true
    property int n: 0
    onTriggered: {
      n++
      if (n % 2 === 1) { win.breached = true; glitch.fire() }
      else win.breached = false
    }
  }
}
