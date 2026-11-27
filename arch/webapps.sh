#!/usr/bin/env bash
# Web apps: Chromium app windows with their own launcher entry and icon, listed in
# arch/webapps.txt (profile | name | url | icon) and generated per machine profile.
#   webapp add NAME URL [ICON_URL] [--profile shared|work|private]   (default profile: shared)
#   webapp remove NAME
#   webapp list
#   webapp sync          (bootstrap.sh runs this)
# Without ICON_URL, add tries the dashboard-icons set (cdn.jsdelivr.net) under the app's name.
set -euo pipefail
repo=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)
list=$repo/arch/webapps.txt
apps_dir=$HOME/.local/share/applications
icons_dir=$HOME/.local/share/icons/webapps
icon_cdn=https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png
marker='Managed by arch/webapps.sh'

die() { echo "webapp: $*" >&2; exit 1; }
slug() { tr '[:upper:] ' '[:lower:]-' <<<"$1" | tr -cd 'a-z0-9.-'; }
trim() { xargs <<<"$1"; }
entries() {   # prints: profile<TAB>name<TAB>url<TAB>icon for every listed web app
  while IFS='|' read -r prof name url icon; do
    prof=$(trim "$prof")
    [[ -z $prof || $prof == \#* ]] && continue
    printf '%s\t%s\t%s\t%s\n' "$prof" "$(trim "$name")" "$(trim "$url")" "$(trim "$icon")"
  done <"$list"
}

sync() {
  local profiles=() wanted=() prof name url icon s host f
  [[ -f $HOME/.config/dotfiles-profile ]] && mapfile -t profiles <"$HOME/.config/dotfiles-profile"
  mkdir -p "$apps_dir" "$icons_dir"
  while IFS=$'\t' read -r prof name url icon; do
    [[ $prof == shared || " ${profiles[*]} " == *" $prof "* ]] || continue
    s=$(slug "$name")
    host=${url#*://}; host=${host%%/*}
    if [[ ! -f $icons_dir/$s.png && -n $icon ]]; then
      curl -fsSL "$icon" -o "$icons_dir/$s.png" || echo "webapp: couldn't fetch the icon for $name" >&2
    fi
    cat >"$apps_dir/webapp-$s.desktop" <<DESKTOP
[Desktop Entry]
# $marker (arch/webapps.txt)
Type=Application
Name=$name
Exec=chromium --app=$url
Icon=$icons_dir/$s.png
StartupWMClass=chrome-${host}__-Default
Categories=Network;
DESKTOP
    wanted+=("webapp-$s.desktop")
  done < <(entries)
  for f in "$apps_dir"/webapp-*.desktop; do   # drop entries no longer listed
    [[ -e $f ]] || continue
    grep -q "$marker" "$f" && [[ " ${wanted[*]} " != *" ${f##*/} "* ]] && rm -f "$f"
  done
  return 0
}

add() {
  local name="" url="" icon="" prof=shared
  while (($#)); do
    case $1 in
      --profile) prof=${2:-}; shift 2 ;;
      *) if [[ -z $name ]]; then name=$1; elif [[ -z $url ]]; then url=$1; else icon=$1; fi; shift ;;
    esac
  done
  [[ -n $name && -n $url ]] || die "usage: webapp add NAME URL [ICON_URL] [--profile shared|work|private]"
  [[ $prof =~ ^(shared|work|private)$ ]] || die "profile must be shared, work or private"
  [[ $url =~ ^https?:// ]] || die "URL must start with http:// or https://"
  [[ $name != *'|'* && $url != *'|'* ]] || die "no '|' in name or URL"
  entries | cut -f2 | grep -qixF -- "$name" && die "$name is already listed (webapp remove \"$name\" first)"
  if [[ -z $icon ]] && curl -fsI "$icon_cdn/$(slug "$name").png" >/dev/null 2>&1; then
    icon=$icon_cdn/$(slug "$name").png
  fi
  [[ -n $icon ]] || echo "webapp: no icon found for $name; pass an ICON_URL to set one" >&2
  printf '%s | %s | %s | %s\n' "$prof" "$name" "$url" "$icon" >>"$list"
  sync
  echo "Added $name ($prof). Commit arch/webapps.txt in $repo to keep it on every machine."
}

remove() {
  local name=${1:-} s
  [[ -n $name ]] || die "usage: webapp remove NAME"
  entries | cut -f2 | grep -qixF -- "$name" || die "$name isn't listed"
  awk -F'|' -v n="$name" 'BEGIN{n=tolower(n)} { x=$2; gsub(/^ +| +$/,"",x); if (tolower(x)!=n) print }' \
    "$list" >"$list.tmp" && mv "$list.tmp" "$list"
  s=$(slug "$name")
  rm -f "$icons_dir/$s.png"
  sync
  echo "Removed $name. Commit arch/webapps.txt in $repo."
}

case ${1:-} in
  add) shift; add "$@" ;;
  remove) shift; remove "$@" ;;
  list) entries | column -t -s $'\t' ;;
  sync) sync ;;
  *) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
