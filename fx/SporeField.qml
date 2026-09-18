// BioVirus — drifting spore field.
// Pure QtQuick + QtQuick.Particles so the identical file runs inside the
// SDDM greeter, which cannot see Quickshell's qs.Commons / qs.Ui modules.
import QtQuick
import QtQuick.Particles

Item {
  id: root

  // `active` stops emission and freezes the system (battery / screensaver).
  property bool active: true
  // `intensity` scales density and drift speed together, 0..1. There is no
  // real per-item frame-rate knob in QtQuick.Particles, so throttling means
  // emitting less and moving slower rather than pretending to cap fps.
  property real intensity: 1.0
  property color tint: "#4bffa5"
  property color motes: "#7de9ff"

  readonly property real k: Math.max(0, Math.min(1, intensity))

  ParticleSystem {
    id: sys
    running: root.active && root.k > 0
    paused: !root.active
  }

  // Large, slow spores rising through the frame.
  Emitter {
    system: sys
    group: "spore"
    anchors.fill: parent
    enabled: root.active && root.k > 0
    emitRate: Math.max(1, Math.round(26 * root.k))
    lifeSpan: 14000
    lifeSpanVariation: 5000
    size: 7
    sizeVariation: 6
    endSize: 2
    velocity: AngleDirection {
      angle: 268; angleVariation: 34
      magnitude: 9 * root.k; magnitudeVariation: 7 * root.k
    }
  }

  // Fine motes, faster and cooler-toned, for depth.
  Emitter {
    system: sys
    group: "mote"
    anchors.fill: parent
    enabled: root.active && root.k > 0
    emitRate: Math.max(1, Math.round(14 * root.k))
    lifeSpan: 9000
    lifeSpanVariation: 3000
    size: 3
    sizeVariation: 2
    velocity: AngleDirection {
      angle: 272; angleVariation: 50
      magnitude: 16 * root.k; magnitudeVariation: 10 * root.k
    }
  }

  // Organic wander — this is what stops it reading as falling snow.
  Wander {
    system: sys
    anchors.fill: parent
    xVariance: 26 * root.k
    yVariance: 14 * root.k
    pace: 12 * root.k
  }

  ImageParticle {
    system: sys
    groups: ["spore"]
    source: "qrc:///particleresources/glowdot.png"
    color: root.tint
    colorVariation: 0.22
    alpha: 0.0
    entryEffect: ImageParticle.Fade
  }

  ImageParticle {
    system: sys
    groups: ["mote"]
    source: "qrc:///particleresources/glowdot.png"
    color: root.motes
    colorVariation: 0.3
    alpha: 0.0
    entryEffect: ImageParticle.Fade
  }
}
