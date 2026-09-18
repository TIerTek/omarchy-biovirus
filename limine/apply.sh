#!/usr/bin/env bash
# Install the BioVirus header + plate into /boot/limine.conf. ROOT ONLY — run as
#   sudo ./apply.sh                      (from a real terminal; /boot is 0700)
#   sudo ./apply.sh --variant local      (header + plate from ./local/, made by install.sh --limine)
#   sudo ./apply.sh --revert             (put the previous header back)
#
# Splice rule: everything ABOVE the first line beginning with "/" is Limine's
# appearance header (ours to own); from that line down is limine-entry-tool's
# generated entry tree, which it regenerates on every limine-update and which we
# never touch. limine-update is run afterwards because ENABLE_VERIFICATION=yes
# enrolls a hash of limine.conf into the EFI binary — an unenrolled edit boots
# with a hash-mismatch warning.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
conf=/boot/limine.conf
bak=/boot/limine.conf.pre-biovirus
[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }
# A variant is a subdirectory holding its own limine-header.conf + <name>-boot.png
# (make-header.py --plate names the file the header expects; keep them in step).
src=$here; plate=biovirus-boot.png
if [[ ${1:-} == --variant ]]; then
  src=$here/$2; plate=$2-boot.png; shift 2
  [[ -f $src/limine-header.conf && -f $src/$plate ]] || { echo "no $src/limine-header.conf or $src/$plate" >&2; exit 1; }
fi

if [[ ${1:-} == --revert ]]; then
  [[ -f $bak ]] || { echo "no $bak to revert to" >&2; exit 1; }
  # keep today's entries, restore only the old header
  { sed -n '1,/^\//{/^\//!p}' "$bak"; sed -n '/^\//,$p' "$conf"; } > "$conf.new"
  mv "$conf.new" "$conf"; rm -f /boot/biovirus-boot.png /boot/local-boot.png
  limine-update; echo "reverted header; plate removed"; exit 0
fi

[[ -f $bak ]] || cp "$conf" "$bak"
grep -q '^/' "$conf" || { echo "$conf has no entry lines starting with '/' — refusing to splice" >&2; exit 1; }
{ cat "$src/limine-header.conf"; echo; sed -n '/^\//,$p' "$conf"; } > "$conf.new"
install -m 644 "$src/$plate" "/boot/$plate"
mv "$conf.new" "$conf"
limine-update
echo "--- header now in place (entries untouched) ---"
sed -n '1,/^\//{/^\//!p}' "$conf" | grep -vE '^\s*$|^###'
echo "--- sanity ---"
echo "entries: $(grep -c cmdline: "$conf")"
ls -la "/boot/$plate"
