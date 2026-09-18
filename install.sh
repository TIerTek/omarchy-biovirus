#!/bin/bash
# BioVirus — install the animated suite on top of the BioVirus theme.
#
#   ./install.sh                  theme (if missing) + background/lock plugins + scripts + login hook
#   ./install.sh --sddm [...]     the above, plus the SDDM login greeter (asks for root once)
#   ./install.sh --uninstall      put the stock Omarchy plugins back and remove everything installed here
#
# The FX components are COPIED into each consumer rather than shared from one
# location: the SDDM greeter runs as the `sddm` user and cannot read ~/.config,
# so there is no path all consumers can reach. One source, several deploys.
#
# Do not run this under sudo: $HOME would become /root and the theme/plugin
# steps would go there. The greeter step elevates itself, once.

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_REPO="https://github.com/TierTek/omarchy-biovirus-theme"
THEME_DIR="$HOME/.config/omarchy/themes/biovirus"
PLUGIN_DIR="$HOME/.config/omarchy/plugins"
SDDM_DIR="/usr/share/sddm/themes/biovirus"
HOOK="$HOME/.config/omarchy/hooks/post-boot.d/random-background"

# `omarchy plugin clone omarchy.background` names the clone <user>.background.
ME="${USER:-$(id -un)}"
BG_PLUGIN="$ME.background"
LOCK_PLUGIN="$ME.lock"

step() { printf '\033[1;32m==>\033[0m %s\n' "$1"; }
as_root() { if (( EUID == 0 )); then "$@"; else pkexec "$@"; fi; }

# ── uninstall ────────────────────────────────────────────────────────────
if [[ ${1:-} == "--uninstall" ]]; then
  for p in "$BG_PLUGIN" "$LOCK_PLUGIN"; do
    if [[ -d $PLUGIN_DIR/$p ]]; then
      step "Removing plugin $p (stock omarchy.${p#$ME.} takes over)"
      omarchy plugin remove "$p" --yes
    fi
  done
  step "Removing scripts and login hook"
  rm -f "$HOME/.local/bin/biovirus-live" "$HOME/.local/bin/biovirus-bg-random" \
        "$HOME/.local/state/omarchy/biovirus-live" "$HOOK"
  if [[ -d $SDDM_DIR ]]; then
    step "Removing SDDM greeter $SDDM_DIR (root)"
    as_root rm -rf "$SDDM_DIR"
    echo "  If /etc/sddm.conf.d/*.conf still names Current=biovirus, point it back at another theme."
  fi
  echo "The theme itself is left in $THEME_DIR; remove it with: rm -rf $THEME_DIR"
  exit 0
fi

# ── theme ────────────────────────────────────────────────────────────────
if [[ -f $THEME_DIR/colors.toml ]]; then
  step "Theme already present at $THEME_DIR"
else
  step "Theme -> $THEME_DIR (omarchy theme install $THEME_REPO)"
  omarchy theme install "$THEME_REPO"
fi

# Refresh the greeter's untracked runtime copies so a fresh clone is testable with:
#   sddm-greeter-qt6 --test-mode --theme ./sddm
mkdir -p "$SRC/sddm/fx"
cp "$THEME_DIR/backgrounds/biovirus-containment.png" "$SRC/sddm/background.png"
cp "$SRC"/fx/*.qml "$SRC/sddm/fx/"

# ── plugin forks ─────────────────────────────────────────────────────────
# Background.qml and LockView.qml/Service.qml are FORKS of Omarchy's own
# background and lock plugins. `omarchy plugin clone` makes the clone (and its
# manifest, which shadows the stock plugin while enabled); we then overwrite
# the QML with ours. Re-diff plugins/ against vendor/ after an Omarchy update.
for source in background lock; do
  target="$ME.$source"
  if [[ ! -d $PLUGIN_DIR/$target ]]; then
    step "Cloning omarchy.$source -> $target"
    omarchy plugin clone "omarchy.$source"
  fi
done

# The glob is deliberately flat: fx/*.qml is the shared component set, and
# fx/scenes/ is copied separately because SceneMap resolves scene paths
# relative to whichever consumer is asking.
step "Background fork + FX -> $BG_PLUGIN"
cp "$SRC/plugins/background/Background.qml" "$PLUGIN_DIR/$BG_PLUGIN/"
mkdir -p "$PLUGIN_DIR/$BG_PLUGIN/fx/scenes"
cp "$SRC"/fx/*.qml "$PLUGIN_DIR/$BG_PLUGIN/fx/"
cp "$SRC"/fx/scenes/*.qml "$PLUGIN_DIR/$BG_PLUGIN/fx/scenes/"

step "Lock fork + FX -> $LOCK_PLUGIN"
cp "$SRC/plugins/lock/LockView.qml" "$SRC/plugins/lock/Service.qml" "$PLUGIN_DIR/$LOCK_PLUGIN/"
mkdir -p "$PLUGIN_DIR/$LOCK_PLUGIN/fx/scenes"
cp "$SRC"/fx/*.qml "$PLUGIN_DIR/$LOCK_PLUGIN/fx/"
cp "$SRC"/fx/scenes/*.qml "$PLUGIN_DIR/$LOCK_PLUGIN/fx/scenes/"

# ── scripts ──────────────────────────────────────────────────────────────
step "biovirus-live, biovirus-bg-random -> ~/.local/bin"
mkdir -p "$HOME/.local/bin"
install -m 0755 "$SRC/bin/biovirus-live" "$HOME/.local/bin/biovirus-live"
install -m 0755 "$SRC/bin/biovirus-bg-random" "$HOME/.local/bin/biovirus-bg-random"

# ── login hook ───────────────────────────────────────────────────────────
# post-boot.d is fired by Hyprland's autostart.lua on EVERY session start, not
# just a cold boot, so this rotates the wallpaper at each login.
step "random-background hook -> post-boot.d"
mkdir -p "$(dirname "$HOOK")"
install -m 0755 "$SRC/hooks/post-boot.d/random-background" "$HOOK"

# ── SDDM greeter (root) ──────────────────────────────────────────────────
# Opt-in: it needs elevation, and machines with autologin never show it anyway.
if [[ ${1:-} == "--sddm" ]]; then
  shift
  # --sddm [--colors <colors.toml>] [--background <png>]
  # The greeter cannot read the live theme (it runs as `sddm`), so its palette is
  # literal in Main.qml. A sibling palette is applied by substituting the five
  # literals at install time; the tracked Main.qml stays the canonical #4bffa5 set.
  COLORS=""; BG="$THEME_DIR/backgrounds/biovirus-containment.png"
  while (( $# )); do
    case $1 in
      --colors) COLORS=$2; shift 2 ;;
      --background) BG=$2; shift 2 ;;
      *) echo "unknown --sddm option: $1" >&2; exit 1 ;;
    esac
  done
  MAIN="$SRC/sddm/Main.qml"
  if [[ -n $COLORS ]]; then
    MAIN=$(mktemp)
    python3 - "$COLORS" "$SRC/sddm/Main.qml" > "$MAIN" <<'PY'
import re, sys
kv = dict(re.findall(r'^(\w+)\s*=\s*"(#[0-9a-fA-F]{6})"', open(sys.argv[1]).read(), re.M))
qml = open(sys.argv[2]).read()
for prop, key in (("accent","accent"), ("dimmed","muted"), ("alarm","red"), ("textCol","bright_foreground")):
    qml = re.sub(r'(property color %s:\s*)"#[0-9a-fA-F]{6}"' % prop, r'\1"%s"' % kv[key], qml)
qml = qml.replace('"#04080a"', '"%s"' % kv["background"])
sys.stdout.write(qml)
PY
    echo "  palette from $COLORS: $(grep -m1 '^accent' "$COLORS")"
  fi
  step "SDDM greeter -> $SDDM_DIR (root)"
  # Stage everything as the user, then ONE elevated copy — a security-key
  # pkexec would otherwise ask for a touch per file.
  STAGE=$(mktemp -d); mkdir -p "$STAGE/fx"
  cp "$MAIN" "$STAGE/Main.qml"
  cp "$SRC/sddm/theme.conf" "$SRC/sddm/metadata.desktop" "$STAGE/"
  # The greeter needs its own copy of the wallpaper (it cannot read ~/.config).
  cp "$BG" "$STAGE/background.png"
  cp "$SRC"/fx/*.qml "$STAGE/fx/"
  chmod -R u=rwX,go=rX "$STAGE"
  as_root sh -c "rm -rf '$SDDM_DIR' && cp -r '$STAGE' '$SDDM_DIR' && chown -R root:root '$SDDM_DIR'"
  rm -rf "$STAGE"
  echo
  echo "  Greeter installed but NOT activated. To activate:"
  echo "    sudo sed -i 's/^Current=.*/Current=biovirus/' /etc/sddm.conf.d/10-theme.conf"
  echo "    sudo sed -i 's/^Current=.*/Current=biovirus/' /etc/sddm.conf.d/99-omarchy-login.conf"
  echo "  Autologin is left untouched."
fi

step "Done. Apply with: omarchy theme set biovirus && omarchy restart shell"
