#!/bin/sh
#
# debian-cd DISC_END_HOOK for the PC Engines APU trixie image.
#
# debian-cd calls this as:
#     $hook $TDIR $MIRROR $DISKNUM $CDDIR "$ARCHES"
# after the boot tree has been built and before the ISO image is created.
#
# Trixie's debian-installer menu (isolinux/spkgtk.cfg, pulled in by
# menu.cfg) sets "timeout 300" and an "ontimeout" that boots the
# speech-synthesis kernel WITHOUT the simple-cdd preseed and WITHOUT
# console=ttyS0,115200. That overrides the TIMEOUT that simple-cdd sets,
# so on a headless APU the installer either never starts, or starts
# invisibly and un-preseeded. The menu also defaults to the graphical
# installer, which cannot run on a serial-only console.
#
# This hook makes the text "Install" entry the default and drops the
# speech auto-boot override.

TDIR=$1
DISKNUM=$3

dir="$TDIR/$CODENAME/boot$DISKNUM/isolinux"
[ -d "$dir" ] || exit 0

# 1. Remove the speech-synthesis auto-boot override.
if [ -f "$dir/spkgtk.cfg" ]; then
    sed -i -e '/^[[:space:]]*timeout[[:space:]]\+300[[:space:]]*$/d' \
           -e '/^[[:space:]]*ontimeout[[:space:]]/d' "$dir/spkgtk.cfg"
fi

# 2. Make the text "Install" entry the menu default instead of the
#    graphical one.
if [ -f "$dir/gtk.cfg" ]; then
    sed -i -e '/^[[:space:]]*default[[:space:]]\+installgui[[:space:]]*$/d' \
           -e '/^[[:space:]]*menu default[[:space:]]*$/d' "$dir/gtk.cfg"
fi
if [ -f "$dir/txt.cfg" ] && ! grep -q '^[[:space:]]*menu default' "$dir/txt.cfg"; then
    sed -i '/^label install$/a\	menu default' "$dir/txt.cfg"
fi

# 3. Belt and braces: explicit global default label. simple-cdd's later sed
#    only rewrites TIMEOUT lines, so this survives.
if [ -f "$dir/isolinux.cfg" ] && ! grep -q '^default install$' "$dir/isolinux.cfg"; then
    echo 'default install' >> "$dir/isolinux.cfg"
fi

exit 0
