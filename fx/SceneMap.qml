// BioVirus — which animated scene belongs to which background plate.
//
// Lives in fx/ because more than one consumer needs it (the desktop background
// and the lock screen) and they must agree: two copies of this table would
// drift the first time a plate is renamed. Pure QtQuick, no Quickshell APIs,
// like the rest of fx/.
import QtQuick

QtObject {
  id: root

  // Plate basename, no extension -> scene path relative to the CONSUMER's own
  // directory. install.sh puts fx/scenes/ into every consumer that needs it, so
  // the same relative path resolves from <user>.background and <user>.lock.
  //
  // A plate that is not listed here resolves to "" and loads nothing. That is
  // what keeps biovirus-containment, every other theme, and every other machine
  // behaving exactly as they did before any of this existed.
  readonly property var scenes: ({
    "biovirus-virions": "fx/scenes/VirionField.qml",
    "biovirus-mitosis": "fx/scenes/Mitosis.qml",
    "biovirus-sequencer": "fx/scenes/Sequencer.qml",
    "biovirus-outbreak": "fx/scenes/Outbreak.qml",
    // Same four scenes under the sibling "contagion" palette's plate names.
    "contagion-virions": "fx/scenes/VirionField.qml",
    "contagion-mitosis": "fx/scenes/Mitosis.qml",
    "contagion-sequencer": "fx/scenes/Sequencer.qml",
    "contagion-outbreak": "fx/scenes/Outbreak.qml"
  })

  function sceneFor(path) {
    var p = String(path || "")
    var base = p.substring(p.lastIndexOf("/") + 1)
    // The lock screen cache-busts its wallpaper URL with "?v=<n>"; strip any
    // query before matching or every lock-screen lookup misses.
    var q = base.indexOf("?")
    if (q > 0) base = base.substring(0, q)
    var dot = base.lastIndexOf(".")
    if (dot > 0) base = base.substring(0, dot)
    return scenes[base] || ""
  }
}
