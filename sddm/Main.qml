// BioVirus — SDDM greeter.
//
// The authentication wiring (sddm.login, sessionIndex resolution, the
// onLoginFailed/onLoginSucceeded Connections) is upstream Omarchy's, unchanged.
// Only the surface around it is BioVirus. The greeter runs as the `sddm` user
// and cannot read ~/.config, so colours are literals and the FX components and
// wallpaper are copied into this directory by install.sh.
import QtQuick 2.0
import SddmComponents 2.0
import "fx"

Rectangle {
  id: root
  width: 640
  height: 480
  color: "#04080a"

  readonly property color accent:  "#4bffa5"
  readonly property color dimmed:  "#2e8f63"
  readonly property color alarm:   "#ff4d5e"
  readonly property color textCol: "#eafff5"
  readonly property string mono:   "JetBrainsMono Nerd Font"

  property string currentUser: userModel.lastUser
  property bool loginFailed: false
  property int sessionIndex: {
    for (var i = 0; i < sessionModel.rowCount(); i++) {
      var name = (sessionModel.data(sessionModel.index(i, 0), Qt.DisplayRole) || "").toString()
      if (name.indexOf("uwsm") !== -1)
        return i
    }
    return sessionModel.lastIndex
  }

  Connections {
    target: sddm
    function onLoginFailed() {
      root.loginFailed = true
      password.text = ""
      password.focus = true
      glitch.fire()
    }
    function onLoginSucceeded() {
      root.loginFailed = false
    }
  }

  // ── backdrop ─────────────────────────────────────────────────────────────
  Image {
    anchors.fill: parent
    source: "background.png"
    fillMode: Image.PreserveAspectCrop
    asynchronous: false
  }

  Rectangle {
    anchors.fill: parent
    color: "#04080a"
    opacity: 0.55
  }

  SporeField { anchors.fill: parent; tint: root.accent }
  Scanlines  { anchors.fill: parent; tint: root.accent; intensity: 0.8 }

  HudFrame {
    anchors.fill: parent
    tint: root.accent
    dim: root.dimmed
    alarm: root.alarm
    fontFamily: root.mono
    breached: root.loginFailed
  }

  // ── credential card ──────────────────────────────────────────────────────
  Column {
    id: stack
    anchors.centerIn: parent
    spacing: 26

    BiohazardMark {
      anchors.horizontalCenter: parent.horizontalCenter
      width: 140
      height: 140
      tint: root.accent
      dim: root.dimmed
      alarm: root.alarm
      fontFamily: root.mono
      breached: root.loginFailed
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: "B I O V I R U S"
      color: root.accent
      font.family: root.mono
      font.pixelSize: 40
      font.bold: true
      font.letterSpacing: 6
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      // lastUser is empty on a first boot and under --test-mode; don't render a
      // dangling separator with nothing after it.
      text: root.loginFailed
        ? "ACCESS DENIED"
        : (root.currentUser.length > 0
            ? "IDENTIFY  —  " + root.currentUser.toUpperCase()
            : "IDENTIFY")
      color: root.loginFailed ? root.alarm : root.dimmed
      font.family: root.mono
      font.pixelSize: 13
      font.letterSpacing: 3
    }

    Rectangle {
      id: card
      width: 420
      height: 68
      anchors.horizontalCenter: parent.horizontalCenter
      color: "#04080a"
      opacity: 0.85
      radius: 4
      border.color: root.loginFailed ? root.alarm : root.accent
      border.width: 3

      // Dots are drawn by the Repeater; the TextInput itself is invisible and
      // only holds the value, matching upstream's approach.
      Row {
        anchors.centerIn: parent
        spacing: 9
        Repeater {
          model: Math.min(password.text.length, 24)
          Rectangle {
            width: 9; height: 9; radius: 4.5
            color: root.loginFailed ? root.alarm : root.textCol
          }
        }
      }

      Text {
        anchors.centerIn: parent
        visible: password.text.length === 0
        text: root.loginFailed ? "authentication failed" : "enter password"
        color: root.loginFailed ? root.alarm : root.dimmed
        font.family: root.mono
        font.pixelSize: 15
        font.italic: root.loginFailed
      }

      TextInput {
        id: password
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        verticalAlignment: TextInput.AlignVCenter
        echoMode: TextInput.Password
        font.family: root.mono
        font.pixelSize: 24
        color: "transparent"
        selectionColor: "transparent"
        selectedTextColor: "transparent"
        cursorDelegate: Item {}
        focus: true

        onTextChanged: root.loginFailed = false

        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            sddm.login(root.currentUser, password.text, root.sessionIndex)
            event.accepted = true
          }
        }
      }
    }
  }

  GlitchLayer {
    id: glitch
    anchors.fill: parent
    shakeTarget: stack
    tint: root.accent
    alarm: root.alarm
  }

  Component.onCompleted: password.forceActiveFocus()
}
