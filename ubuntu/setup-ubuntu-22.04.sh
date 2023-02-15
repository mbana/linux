#!/usr/bin/bash

# Can only be run as sudo
# if [[ $EUID -gt 0 ]]; then
if [[ "${EUID:-$(id -u)}" -gt 0 ]]; then
  echo "Please run as root/sudo"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root/sudo" 1>&2
  exit 100
fi

setup_initial() {
  # echo 'vm.swappiness=4' | tee /etc/sysctl.d/99-vm.conf

  echo 'kernel.sysrq=1' | tee /etc/sysctl.d/99-kernel.conf
  echo 'kernel.dmesg_restrict=0' | tee -a /etc/sysctl.d/99-kernel.conf
  echo 'fs.inotify.max_user_watches=8192' | tee /etc/sysctl.d/99-fs.conf
  echo 'fs.inotify.max_user_instances=524288' | tee -a /etc/sysctl.d/99-fs.conf

  echo 'options bluetooth disable_ertm=1' | tee -a /etc/modprobe.d/bluetooth.conf

  echo 'options iwlmvm power_scheme=1' | tee -a /etc/modprobe.d/iwlmvm.conf
  #echo 'options iwlwifi power_level=5' | tee -a /etc/modprobe.d/iwlwifi.conf
  echo 'options cfg80211 ieee80211_regdom=GB' | tee -a /etc/modprobe.d/cfg80211.conf
  iw reg set MA

  cat <<EOF >/etc/udev/rules.d/99-power-profile.rules
# https://www.reddit.com/r/gnome/comments/snihk3/comment/hw5hmzn/?utm_source=share&utm_medium=web2x&context=3
# https://bana.io/blog/linux-laptop-switch-to-performance-mode-when-on-ac
SUBSYSTEM=="power_supply",ENV{POWER_SUPPLY_ONLINE}=="0",RUN+="/usr/bin/powerprofilesctl set power-saver"
SUBSYSTEM=="power_supply",ENV{POWER_SUPPLY_ONLINE}=="1",RUN+="/usr/bin/powerprofilesctl set performance"
EOF

  cat <<EOF >/etc/udev/rules.d/99-disable-nvme.rules
# Disable the NVMe drive with Windows on it.
# https://superuser.com/a/760592/60000
ACTION=="add", KERNEL=="0000:03:00.0", SUBSYSTEM=="pci", RUN+="/bin/sh -c 'echo 1 > /sys/bus/pci/devices/0000:00:06.2/remove'"
EOF

  cat <<EOF >/etc/udev/rules.d/40-disable-internal-webcam.rules
# Disable internal laptop webcam when
# Bus 002 Device 005: ID 046d:086b Logitech, Inc. Logi 4K Stream Edition
# is connected.
#
# https://wiki.archlinux.org/title/webcam_setup
ACTION=="add", ATTR{idVendor}=="046d", ATTR{idProduct}=="086b", RUN="/bin/sh -c 'echo 1 > /sys/bus/usb/devices/1-2/remove'"
EOF

  ln -s /usr/bin/shfmt /usr/local/bin/shfmt
  ln -s /usr/bin/shellcheck /usr/local/bin/shellcheck

  update-initramfs -c -k $(uname -r)
}

setup_journalctl() {
  journalctl -b -u systemd-journald
  mkdir -pv /etc/systemd/journald.conf.d
  cat <<EOF >/etc/systemd/journald.conf.d/00-journal-size.conf
# https://wiki.archlinux.org/title/Systemd/Journal
[Journal]
SystemMaxUse=256M
EOF
  systemctl restart systemd-journald.service
  journalctl -b -u systemd-journald
}

setup_sound() {
  mkdir -pv /tmp/alsa-sof-firmware
  cd /tmp/alsa-sof-firmware
  curl -L --output ./sof-hda-generic-2ch-pdm1.zip "https://github.com/thesofproject/linux/files/5981682/sof-hda-generic-2ch-pdm1.zip"
  unzip ./sof-hda-generic-2ch-pdm1.zip -d .
  rm ./sof-hda-generic-2ch-pdm1.zip
  # Make `sof-hda-generic-2ch.tplg.xz`
  mv -v sof-hda-generic-2ch-pdm1.tplg sof-hda-generic-2ch.tplg
  # Copy new topology file over and then reboot
  ls -lah /lib/firmware/intel/sof-tplg/sof-hda-generic-2ch.tplg
  echo
  cp -v ./sof-hda-generic-2ch.tplg /lib/firmware/intel/sof-tplg/sof-hda-generic-2ch.tplg
  echo
  ls -lah /lib/firmware/intel/sof-tplg/sof-hda-generic-2ch.tplg
  chmod o+r,g+r /lib/firmware/intel/sof-tplg/sof-hda-generic-2ch.tplg
  ##systemctl reboot
}

setup_software() {
  apt install -y golang bat fd-find ripgrep powerline git git-lfs wget curl make coreutils tree progress nmap arp-scan openssh-server openssh-client vim build-essential manpages-dev ca-certificates git zsh-theme-powerlevel9k zsh-syntax-highlighting zsh-autosuggestions zsh-antigen zsh-common autoconf automake cmake curl libtool make ninja-build patch python3-pip unzip virtualenv clang llvm lld golang bat fd-find ripgrep powerline git git-lfs wget curl make coreutils tree progress nmap arp-scan openssh-server openssh-client vim build-essential manpages-dev ca-certificates git zsh-theme-powerlevel9k zsh-syntax-highlighting zsh-autosuggestions zsh-antigen zsh-common bat fd-find ripgrep powerline git git-lfs wget curl make coreutils tree progress nmap arp-scan openssh-server openssh-client vim build-essential manpages-dev ca-certificates git zsh-theme-powerlevel9k zsh-syntax-highlighting zsh-autosuggestions zsh-antigen zsh-common docker docker-compose podman autoconf automake cmake curl libtool make ninja-build patch python3-pip unzip virtualenv clang llvm lld jq gron gnupg2
  apt install -y jq cmake llvm bat meson ninja-build inxi screenfetch fonts-firacode iw sysfsutils shellcheck shfmt texlive-full fonts-ibm-plex fonts-cascadia-code fonts-terminus fonts-inconsolata ubuntu-restricted-extras youtube-dl yt-dlp gir1.2-gtop-2.0 gir1.2-nm-1.0 gir1.2-clutter-1.0 gnome-system-monitor gobject-introspection btop nvtop fd-find ripgrep gnome-shell-extension-gpaste gnome-shell-extensions-gpaste gpaste sassc inkscape numix-gtk-theme numix-icon-theme numix-icon-theme-circle dconf-editor lz4 7zip p7zip-full p7zip wireshark-gtk wireshark tshark termshark nmap cpu-checker qemu-kvm libvirt-daemon bridge-utils virtinst libvirt-daemon-system virt-top libguestfs-tools libosinfo-bin qemu-system virt-manager yubioath-desktop yubico-piv-tool yubikey-personalization-gui yubikey-manager doas smartmontools clang gcc llvm xournalpp xsel xclip ratbagd piper hardinfo
  apt install -y node-typescript node-typescript-types
  apt install -y zsh-theme-powerlevel9k zsh-syntax-highlighting zsh-autosuggestions zsh-antigen zsh-common git git-lfs wget curl make coreutils tree progress nmap arp-scan iproute2 net-tools bat fd-find ripgrep powerline
  apt install -y vlc screenfetch lm-sensors hw-probe iperf inkscape gimp
  apt install -y wget curl curl ca-certificates git git-core openssh-server openssh-client make parallel gnupg-agent vim apt-transport-https bat
  usermod -aG kvm "$(whoami)"
  usermod -aG libvirt "$(whoami)"
  usermod -aG docker "$(whoami)"
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

setup_pipewire() {
  # https://ubuntuhandbook.org/index.php/2022/04/pipewire-replace-pulseaudio-ubuntu-2204/
  echo
}

setup_swap() {
  echo

  echo
}

install_flatpaks() {
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  flatpak update -y --noninteractive
  flatpak install -y --noninteractive flathub com.github.tchx84.Flatseal
  flatpak install -y --noninteractive flathub com.raggesilver.BlackBox
  flatpak install -y --noninteractive flathub com.slack.Slack
  flatpak install -y --noninteractive flathub com.discordapp.Discord
  flatpak install -y --noninteractive flathub us.zoom.Zoom
  flatpak install -y --noninteractive flathub org.signal.Signal
  flatpak install -y --noninteractive flathub org.telegram.desktop
  flatpak install -y --noninteractive flathub com.skype.Client
  flatpak install -y --noninteractive flathub com.github.micahflee.torbrowser-launcher
  flatpak update -y --noninteractive
}

install_kubectl_tools() {
  echo '-------------------------------------------------------------------------------'
  cd /tmp
  mkdir -pv ~/go/bin ~/go/.bin ~/bin ~/.bin
  sudo mkdir -p /usr/local/bin/

  curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-$([ $(uname -m) = "aarch64" ] && echo "arm64" || echo "amd64")
  sudo install skaffold /usr/local/bin/
  rm skaffold
  skaffold version

  sudo wget -O /usr/local/bin/bazel https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-$([ $(uname -m) = "aarch64" ] && echo "arm64" || echo "amd64")
  sudo chmod +x /usr/local/bin/bazel

  curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-$([ $(uname -m) = "aarch64" ] && echo "arm64" || echo "amd64")
  chmod +x minikube
  sudo install minikube /usr/local/bin/

  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$([ $(uname -m) = "aarch64" ] && echo "arm64" || echo "amd64")/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm kubectl

  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 get_helm.sh
  HELM_INSTALL_DIR="${HOME}/bin" ./get_helm.sh --no-sudo
  rm get_helm.sh

  go install sigs.k8s.io/kind@latest
  echo '-------------------------------------------------------------------------------'
}

install_go_packages() {
  # go install github.com/dty1er/kubecolor/cmd/kubecolor@latest
  go install github.com/hidetatz/kubecolor/cmd/kubecolor@latest
  go install github.com/andreazorzetto/yh@latest
  go install sigs.k8s.io/kustomize/kustomize/v4@latest
  go install sigs.k8s.io/kind@latest
  go install sigs.k8s.io/controller-runtime/tools/setup-envtest@latest
  go install sigs.k8s.io/kind@latest
  go install sigs.k8s.io/kustomize/kustomize/v4@latest
  # go install github.com/engineerd/wasm-to-oci
  # go install github.com/engineerd/wasm-to-oci@latest
  # go install github.com/engineerd/wasm-to-oci/cmd@latest
  # go install github.com/engineerd/wasm-to-oci/cmd
  # go install github.com/engineerd/wasm-to-oci/cmd@latest
  go install github.com/derailed/k9s@latest
  go install github.com/go-delve/delve/cmd/dlv@latest
  go install github.com/simeji/jid/cmd/jid@latest
  go install github.com/txn2/kubefwd@latest
  go install github.com/txn2/kubefwd/cmd@latest
  go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest
  go install github.com/tilt-dev/ctlptl/cmd/ctlptl@latest
  go install honnef.co/go/tools/cmd/staticcheck@2022.1
  go install honnef.co/go/tools/cmd/structlayout-pretty@2022.1
  go install honnef.co/go/tools/cmd/structlayout-optimize@2022.1
  go install honnef.co/go/tools/cmd/structlayout-optimize@2022.1
  go install honnef.co/go/tools/cmd/structlayout-structlayout@2022.1
  go install honnef.co/go/tools/cmd/structlayout@2022.1
  go install honnef.co/go/tools/cmd/structlayout@2022.1
  go install honnef.co/go/tools/cmd/staticcheck@latest
  go install honnef.co/go/tools/cmd/keyify@2022.1
  go install honnef.co/go/tools/cmd/keyify@2022.1
  go install github.com/ajstarks/svgo/structlayout-svg@latest
  go install golang.org/x/tools/go/analysis/passes/fieldalignment/cmd/fieldalignment@latest
  go install github.com/google/ko@latest
  go install github.com/GoogleContainerTools/kpt@latest
  go install github.com/bazelbuild/bazelisk@latest
  go install github.com/mikefarah/yq/v4@latest
  go install github.com/stern/stern@latest
  go install github.com/rakyll/gotest@latest
  # vscode-go
  go install github.com/cweill/gotests/gotests@latest
  go install github.com/fatih/gomodifytags@latest
  go install github.com/josharian/impl@latest
  go install github.com/haya14busa/goplay/cmd/goplay@latest
  go install github.com/go-delve/delve/cmd/dlv@latest
  go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
  go install golang.org/x/tools/gopls@latest
}
install_go_packages

setup_docker() {
  systemctl stop docker
  #
  # https://docs.docker.com/storage/storagedriver/overlayfs-driver/#configure-docker-with-the-overlay-or-overlay2-storage-driver
  cat <<EOF >/etc/docker/daemon.json
{
  "storage-driver": "overlay2"
}
EOF
  systemctl start docker
  docker info | grep -i storage
}

install_kernel_lts() {
  linux-tools-generic-hwe-22.04 - Generic Linux kernel tools
  linux-tools-generic-hwe-22.04-edge - Generic Linux kernel tools

  linux-image-unsigned-6.1.0-1006-oem

  apt install linux-image-6.1.0-1006-oem linux-headers-6.1.0-1006-oem linux-modules-6.1.0-1006-oem linux-oem-6.1-headers-6.1.0-1006 linux-oem-6.1-tools-6.1.0-1006 linux-tools-6.1.0-1006-oem linux-objects-nvidia-525-6.1.0-1006-oem linux-signatures-nvidia-6.1.0-1006-oem linux-buildinfo-6.1.0-1006-oem
}

setup_efi_stub() {
  efibootmgr --verbose --create --disk /dev/nvme0n1 --part 1 --label "ubuntu (efistub)" --loader "/EFI/ubuntu/vmlinuz" --unicode "BOOT_IMAGE=/@/boot/vmlinuz-6.1.12-x64v3-xanmod1 root=UUID=8446284c-d488-4d40-ad59-df73005d9120 ro initrd=/EFI/ubuntu/initrd.img rootflags=subvol=@ sysrq_always_enabled=1 add_efi_memmap nosplash quiet"
  efibootmgr --verbose --create --disk /dev/nvme0n1 --part 1 --loader "\EFI\fedora\fedora.efi" --label "Fedora-EFI"
}

setup_initial
setup_journalctl
setup_sound
setup_swap
setup_pipewire
setup_software
setup_kubernetes
setup_docker
install_go_packages
