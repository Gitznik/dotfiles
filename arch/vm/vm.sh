#!/usr/bin/env bash
# Disposable QEMU test VM for the Arch target. See arch/README.md, "VM test loop".
# base.qcow2 = clean-base (read-only once sealed); work.qcow2 = throwaway overlay.
set -euo pipefail

dir=${VM_DIR:-$HOME/vms/arch}
iso_dir=${VM_ISO_DIR:-$HOME/vms/iso}
mirror=${VM_MIRROR:-https://geo.mirror.pkgbuild.com/iso}
ovmf_code=/usr/share/edk2/x64/OVMF_CODE.4m.fd
ovmf_vars=/usr/share/edk2/x64/OVMF_VARS.4m.fd
key=$HOME/vms/id_vm
# Guest host keys change on every reset; never record them.
ssh_opts=(-p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR)

die() { echo "vm: $*" >&2; exit 1; }

latest_iso() {
  local iso
  iso=$(ls -1 "$iso_dir"/archlinux-[0-9]*-x86_64.iso 2>/dev/null | sort | tail -1)
  [[ -n $iso ]] || die "no ISO in $iso_dir; run: vm.sh iso"
  echo "$iso"
}

# -serial none: with a serial port, console=uart… lands on the guest cmdline and Plymouth forces text mode.
qemu() {
  local disk=$1 vars=$2; shift 2
  exec qemu-system-x86_64 \
    -name arch-test -enable-kvm -machine q35 -cpu host \
    -smp "${VM_CPUS:-4}" -m "${VM_MEM:-6G}" \
    -drive if=pflash,format=raw,readonly=on,file="$ovmf_code" \
    -drive if=pflash,format=raw,file="$vars" \
    -drive file="$disk",format=qcow2,if=virtio,discard=unmap \
    -nic user,model=virtio-net-pci,hostfwd=tcp:127.0.0.1:2222-:22 \
    -device virtio-vga-gl -display gtk,gl=on,grab-on-hover=on \
    -device qemu-xhci -device usb-tablet \
    -audiodev pipewire,id=snd -device intel-hda -device hda-duplex,audiodev=snd \
    -device virtio-rng-pci \
    -serial none \
    "$@"
}

case ${1:-} in
  iso)
    mkdir -p "$iso_dir"; cd "$iso_dir"
    curl -sfLO "$mirror/latest/sha256sums.txt"
    name=$(awk '/archlinux-[0-9.]+-x86_64\.iso$/ {print $2}' sha256sums.txt)
    ver=${name#archlinux-}; ver=${ver%-x86_64.iso}
    [[ -f $name ]] || curl -fLO "$mirror/$ver/$name"
    curl -sfLO "$mirror/$ver/$name.sig"
    grep " $name\$" sha256sums.txt | sha256sum -c
    pacman-key -v "$name.sig"
    ;;
  create)
    [[ ! -e $dir/base.qcow2 ]] || die "$dir/base.qcow2 exists; delete $dir to start over"
    mkdir -p "$dir"
    qemu-img create -q -f qcow2 "$dir/base.qcow2" "${VM_DISK:-40G}"
    install -m644 "$ovmf_vars" "$dir/base-vars.fd"
    echo "Install Arch (arch/README.md step 1), power off, then: vm.sh seal"
    qemu "$dir/base.qcow2" "$dir/base-vars.fd" -cdrom "$(latest_iso)"
    ;;
  install)
    [[ -w $dir/base.qcow2 ]] || die "no writable base; already sealed or not created"
    qemu "$dir/base.qcow2" "$dir/base-vars.fd" -cdrom "$(latest_iso)"
    ;;
  seal)
    [[ -w $dir/base.qcow2 ]] || die "no writable base; already sealed or not created"
    chmod 444 "$dir/base.qcow2" "$dir/base-vars.fd"
    "$0" reset
    ;;
  reset)
    [[ -f $dir/base.qcow2 && ! -w $dir/base.qcow2 ]] || die "base not sealed; run: vm.sh seal"
    rm -f "$dir/work.qcow2" "$dir/work-vars.fd"
    qemu-img create -q -f qcow2 -b base.qcow2 -F qcow2 "$dir/work.qcow2"
    install -m644 "$dir/base-vars.fd" "$dir/work-vars.fd"
    echo "work.qcow2 reset to clean-base"
    ;;
  ssh-key)
    [[ -f $key ]] || ssh-keygen -q -t ed25519 -N '' -C arch-test-vm -f "$key"
    ssh-copy-id -i "$key.pub" "${ssh_opts[@]}" "${VM_USER:-$USER}@localhost"
    ;;
  ssh)
    shift
    tty=(); [[ -t 0 ]] && tty=(-t)
    exec ssh "${tty[@]}" -i "$key" -o IdentitiesOnly=yes "${ssh_opts[@]}" "${VM_USER:-$USER}@localhost" "$@"
    ;;
  run)
    [[ -f $dir/work.qcow2 ]] || die "no overlay; run: vm.sh seal (or reset)"
    qemu "$dir/work.qcow2" "$dir/work-vars.fd"
    ;;
  *)
    cat >&2 <<EOF
usage: vm.sh iso|create|install|seal|reset|run|ssh-key|ssh
  iso      download + verify the latest Arch ISO into $iso_dir
  create   new base disk, boot the ISO for the base install
  install  boot the ISO against the unsealed base again
  seal     make base read-only (clean-base) and create the work overlay
  reset    discard work overlay, back to clean-base
  run      boot the work overlay
  ssh-key  create ~/vms/id_vm and install it in the guest (asks for the guest password once)
  ssh      ssh into the running guest, optionally running a command
Env: VM_DIR VM_CPUS VM_MEM VM_DISK VM_USER. Guest SSH: localhost:2222 (needs openssh + sshd in the guest). Keyboard grabs on hover; avoid Ctrl+Alt+G (locks the pointer).
EOF
    exit 1
    ;;
esac
