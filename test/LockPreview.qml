// Reproduces LockView.qml's visual stack WITHOUT Quickshell, so the lock
// screen can be eyeballed without locking the session — which an agent must
// never do, because there is no unlock IPC (see the vault note's landmine 5).
//
// Everything below mirrors LockView.qml: same blur parameters, same FX order,
// same intensities. Only the password card is an approximation, drawn from the
// real fieldWidth/fieldHeight/outlineThickness constants for composition.
//
// Needs the GPU: MultiEffect's blur does not render under QT_QUICK_BACKEND=software.
//   QT_QPA_PLATFORM=offscreen qml6 test/LockPreview.qml -- <plate> <Scene.qml|-> <out.png> <settleMs>
import QtQuick
import QtQuick.Window
import QtQuick.Effects
import "../fx"

Window {
  id: win
  visible: true
  width: 1800
  height: 1125
  color: "#04080a"
  // Offscreen leaves MultiEffect's blur unrendered (no GPU context), so a
  // faithful preview has to be a real window on a real compositor. Pass
  // --fullscreen BEFORE the positional args for that; omit it and this stays a
  // plain window, which is all the offscreen path needs.
  visibility: argv.indexOf("--fullscreen") !== -1 ? Window.FullScreen : Window.Windowed

  readonly property var argv: Qt.application.arguments
  readonly property string plate: argv[argv.length - 4]
  readonly property string scene: argv[argv.length - 3]
  readonly property string out: argv[argv.length - 2]
  readonly property int settle: parseInt(argv[argv.length - 1])

  // LockView takes these from Color.accent / Style; pinned here to the biovirus
  // palette so the preview does not depend on a running shell.
  readonly property color accent: "#4bffa5"
  readonly property color dim: "#63a186"
  readonly property color alarm: "#ff4d5e"
  readonly property real fxIntensity: 1.0

  Rectangle {
    anchors.fill: parent
    color: "#04080a"

    Image {
      id: wallpaper
      anchors.fill: parent
      source: "file://" + win.plate
      fillMode: Image.PreserveAspectCrop
      sourceSize.width: width
      sourceSize.height: height
    }

    MultiEffect {
      anchors.fill: wallpaper
      source: wallpaper
      autoPaddingEnabled: false
      blurEnabled: true
      blur: 1.0
      blurMax: 128
      blurMultiplier: 1.25
      contrast: -0.08
    }

    Loader {
      anchors.fill: parent
      source: win.scene === "-" ? "" : "file://" + win.scene
      onLoaded: {
        item.active = true
        item.intensity = win.fxIntensity
        if (item.tint !== undefined) item.tint = win.accent
        // Mirrors LockView: this view owns the HudFrame, so a scene carrying
        // one must not draw a second.
        if (item.hudEnabled !== undefined) item.hudEnabled = false
      }
      onStatusChanged: if (status === Loader.Error) console.log("SCENE FAILED TO LOAD")
    }

    SporeField {
      anchors.fill: parent
      active: true
      intensity: win.fxIntensity
      tint: win.accent
    }

    Scanlines {
      anchors.fill: parent
      active: true
      intensity: win.fxIntensity * 0.8
      tint: win.accent
    }

    HudFrame {
      anchors.fill: parent
      active: true
      intensity: win.fxIntensity
      tint: win.accent
      dim: win.dim
      alarm: win.alarm
      fontFamily: "JetBrainsMono Nerd Font"
      baseFontSize: 13
    }

    // Password field — approximate, from LockView's real constants.
    Rectangle {
      anchors.centerIn: parent
      width: 381
      height: 67
      radius: height / 2
      color: Qt.rgba(0, 0, 0, 0.45)
      border.width: 3
      border.color: win.accent

      Text {
        anchors.centerIn: parent
        text: "● ● ● ● ● ● ●"
        color: win.accent
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 22
      }
    }
  }

  Timer {
    running: true
    interval: win.settle
    onTriggered: {
      win.contentItem.grabToImage(function (result) {
        if (!result.saveToFile(win.out)) console.log("SAVE FAILED")
        Qt.exit(0)
      }, Qt.size(win.width, win.height))
    }
  }
}
