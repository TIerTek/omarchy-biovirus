#!/usr/bin/env bash
# Boot the real Limine in QEMU/OVMF against a throwaway ESP holding our header,
# fake entries and the plate, and screenshot the menu. No root, nothing touches /boot.
#
#   ./preview.sh [header.conf] [plate.png] [out.png]
#
# Needs qemu-base, edk2-ovmf, mtools, dosfstools. Screenshot is via the QEMU
# monitor `screendump` (works headless). Menu timeout is forced high so Limine
# never tries to boot the (nonexistent) kernels.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
header=${1:-$here/limine-header.conf}
plate=${2:-$here/biovirus-boot.png}
out=${3:-$here/preview/menu.png}
work=$here/preview; mkdir -p "$work"
esp=$work/esp.img; mon=$work/mon.sock

rm -f "$esp"; truncate -s 64M "$esp"; mkfs.fat -F 32 "$esp" >/dev/null
mmd -i "$esp" ::/EFI ::/EFI/BOOT ::/EFI/Linux
mcopy -i "$esp" /usr/share/limine/BOOTX64.EFI ::/EFI/BOOT/BOOTX64.EFI
{
  # timeout override so the menu sits there for the screenshot
  grep -vE '^\s*#?timeout:|^\s*interface_resolution:' "$header"; echo "timeout: 300"
  # OVMF's VGA GOP offers 2560x1600 (16:10), the closest it gets to the panel's 2880x1800
  echo "interface_resolution: ${PREVIEW_RES:-2560x1600}"
  cat "$here/preview-entries.conf"
} > "$work/limine.conf"
mcopy -i "$esp" "$work/limine.conf" ::/limine.conf
[[ -f $plate ]] && mcopy -i "$esp" "$plate" ::/"$(basename "$plate")"
# dummy UKIs so the entries at least point at real files
for k in omarchy_linux-omarchy omarchy_linux; do
  head -c 4096 /dev/zero > "$work/$k.efi"; mcopy -i "$esp" "$work/$k.efi" ::/EFI/Linux/$k.efi
done
cp /usr/share/edk2/x64/OVMF_VARS.4m.fd "$work/vars.fd"

rm -f "$mon"
qemu-system-x86_64 -machine q35 -m 512M -cpu qemu64 \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.4m.fd \
  -drive if=pflash,format=raw,file="$work/vars.fd" \
  -drive file="$esp",format=raw,if=virtio \
  ${PREVIEW_VIDEO:--device VGA,vgamem_mb=64} \
  -display none -monitor "unix:$mon,server,nowait" -no-reboot &
qpid=$!
for i in $(seq 1 40); do
  python3 -c 'import time;time.sleep(1)'
  [[ -S $mon ]] && break
done
python3 -c 'import time;time.sleep(float("'"${PREVIEW_WAIT:-14}"'"))'
printf 'screendump %s\n' "$work/menu.ppm" | socat - "unix-connect:$mon" >/dev/null 2>&1 || \
  printf 'screendump %s\n' "$work/menu.ppm" | nc -U -q1 "$mon" >/dev/null 2>&1 || true
python3 -c 'import time;time.sleep(2)'
printf 'quit\n' | socat - "unix-connect:$mon" >/dev/null 2>&1 || kill $qpid 2>/dev/null || true
wait $qpid 2>/dev/null || true
python3 -c "from PIL import Image; im=Image.open('$work/menu.ppm'); im.save('$out'); print('wrote $out', im.size)"
