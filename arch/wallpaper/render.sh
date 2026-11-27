#!/usr/bin/env bash
# Renders the desktop wallpaper (topographic contour lines, Catppuccin Mocha) and the
# blurred, dimmed lock-screen copy into arch/stow/wallpaper. Needs ImageMagick 7.
# 5120x2880 fills both 32:9 (5120x1440, center crop) and 16:9 screens. Change the seed
# for a different terrain.
set -euo pipefail
out="$(cd "$(dirname "$0")/.." && pwd)/stow/wallpaper/.local/share/wallpapers"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
w=5120 h=2880 seed=${SEED:-11}

# Smooth height field, cut into 16 bands; band edges become evenly thin contour lines.
magick -seed "$seed" -size 640x360 plasma:fractal -colorspace gray -blur 0x24 -auto-level \
  -resize "${w}x${h}!" -depth 16 "$tmp/field.png"
magick "$tmp/field.png" -fx 'floor(u*16)/16' -morphology EdgeIn Diamond:2 -threshold 0 \
  -blur 0x1.2 "$tmp/lines.png"
# Lines in surface1 over a base -> mantle gradient.
magick -size "${w}x${h}" gradient:'#24243a'-'#181825' \( -size "${w}x${h}" xc:'#45475a' \) \
  "$tmp/lines.png" -composite -depth 8 "$out/topo.png"
# Lock screen: same image, blurred and darker so the indicator stands out.
magick "$out/topo.png" -blur 0x18 -fill '#11111b' -colorize 40% \
  -depth 8 "$out/topo-lock.png"
