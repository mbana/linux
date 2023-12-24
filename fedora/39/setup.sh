#!/usr/bin/env bash
set -o errexit  # Used to exit upon error, avoiding cascading errors
set -o pipefail # Unveils hidden failures
set -o nounset  # Exposes unset variables

# References:
#
# * <https://github.com/smvarela/fedora-postinstall>.
# * <https://mutschler.eu/linux/install-guides/fedora-post-install/>.
# * <https://docs.fedoraproject.org/en-US/fedora/f34/system-administrators-guide/basic-system-configuration/System_Locale_and_Keyboard_Configuration/>.
# * <https://docs.fedoraproject.org/en-US/fedora/f34/system-administrators-guide/kernel-module-driver-configuration/Working_with_the_GRUB_2_Boot_Loader/>.
# * <https://docs.fedoraproject.org/en-US/fedora/f34/system-administrators-guide/kernel-module-driver-configuration/Working_with_Kernel_Modules/>.
# * <https://wiki.archlinux.org/index.php/silent_boot>.
# * <https://rpmfusion.org/Howto/NVIDIA>.

setup_shell()
{
  sudo dnf install -y \
    bash-color-prompt

  sudo dnf swap nano-default-editor vim-default-editor --allowerasing
  # sudo dnf remove \
  #   nano-default-editor
  # sudo dnf install -y \
  #   vim-default-editor

  sudo dnf install -y \
    git git-lfs vim curl wget zsh zsh-syntax-highlighting zsh-autosuggestions
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
  sudo usermod -s "$(which zsh)" "${USER}"
}
setup_shell

setup_network()
{
  nmcli connection modify vodafoneC137F3 ipv4.ignore-auto-dns yes
  nmcli connection modify vodafoneC137F3 ipv6.ignore-auto-dns yes
  nmcli connection modify vodafoneC137F3 ipv4.dns "1.1.1.1,1.0.0.1"
  nmcli connection modify vodafoneC137F3 ipv6.dns "2606:4700:4700::1111,2606:4700:4700::1001"
  nmcli connection down vodafoneC137F3
  nmcli connection up vodafoneC137F3

  nmcli connection modify eth0 ipv4.ignore-auto-dns yes
  nmcli connection modify eth0 ipv6.ignore-auto-dns yes
  nmcli connection modify eth0 ipv4.dns "1.1.1.1,1.0.0.1"
  nmcli connection modify eth0 ipv6.dns "2606:4700:4700::1111,2606:4700:4700::1001"
  nmcli connection down eth0
  nmcli connection up eth0

  # cat /etc/systemd/resolved.conf
  # [Resolve]
  # DNS=1.1.1.1 1.0.0.1 606:4700:4700::1111 2606:4700:4700::1001
  # DNSOverTLS=yes
  # DNSSEC=yes
  # FallbackDNS=8.8.8.8 8.8.4.4 2001:4860:4860::8888 2001:4860:4860::8844
  # #Domains=~.
  # #LLMNR=yes
  # #MulticastDNS=yes
  # #Cache=yes
  # #DNSStubListener=yes
  # #ReadEtcHosts=yes

  # cat /etc/NetworkManager/conf.d/10-dns-systemd-resolved.conf
  # [main]
  # dns=systemd-resolved
  # systemd-resolved=false

  sudo systemctl start --now systemd-resolved
  sudo systemctl enable --now systemd-resolved
  sudo systemctl restart NetworkManager
  sudo systemctl restart systemd-resolved
  sudo resolvectl flush-caches
  resolvectl status
  systemd-resolve --status
  # /etc/resolv.conf should point to 127.0.0.53
  cat /etc/resolv.conf
  sudo ss -lntp | grep '\(State\|:53 \)'
  # To make a secure query, run
  resolvectl query fedoraproject.org
}
setup_network

setup_timezone()
{
  # timedatectl set-timezone "Africa/Casablanca"
  timedatectl set-timezone Europe/London
  timedatectl set-ntp yes
  # # Warning: The system is configured to read the RTC time in the local time zone.
  # #          This mode cannot be fully supported. It will create various problems
  # #          with time zone changes and daylight saving time adjustments. The RTC
  # #          time is never updated, it relies on external facilities to maintain it.
  # #          If at all possible, use RTC in UTC by calling
  # #          'timedatectl set-local-rtc 0'.
  # timedatectl set-local-rtc true
  # timedatectl set-local-rtc 0
}
setup_timezone

setup_dnf()
{
  sudo cp -v /etc/dnf/dnf.conf /etc/dnf/dnf.conf.bk.0
  sudo sed -i 's/installonly_limit=3/installonly_limit=2/' /etc/dnf/dnf.conf
  echo 'max_parallel_downloads=20' | sudo tee -a /etc/dnf/dnf.conf
  echo 'fastestmirror=True' | sudo tee -a /etc/dnf/dnf.conf
  # echo 'deltarpm=False' | sudo tee -a /etc/dnf/dnf.conf
  # echo 'deltarpm=True' | sudo tee -a /etc/dnf/dnf.conf
  # https://dnf-plugins-extras.readthedocs.io/en/latest/
  sudo dnf install -y dnf-plugins-core
  sudo dnf install -y dnf-plugin-kickstart
  sudo dnf install -y dnf-plugin-rpmconf
  sudo dnf install -y dnf-plugin-showvars
  sudo dnf install -y dnf-plugin-tracer
  # sudo dnf install -y dnf-plugin-snapper
  # sudo dnf install -y dnf-plugin-system-upgrade
  # sudo dnf install -y dnf-plugin-torproxy
  sudo dnf install -y dnf-utils
  sudo dnf install -y microdnf
}
setup_dnf

setup_x11()
{
  cat << EOF | sudo tee /etc/X11/xorg.conf.d/nvidia.conf
#This file is provided by xorg-x11-drv-nvidia
#Do not edit

Section "OutputClass"
	Identifier "nvidia"
	MatchDriver "nvidia-drm"
	Driver "nvidia"
	Option "AllowEmptyInitialConfiguration"
	Option "SLI" "Auto"
	Option "BaseMosaic" "on"
	Option "PrimaryGPU" "yes"
EndSection

Section "ServerLayout"
	Identifier "layout"
	Option "AllowNVIDIAGPUScreens"
EndSection
EOF
}
setup_x11

# configure_repositories() {
#   sudo dnf install -y rpmfusion-free-release-tainted
#   sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm
#   sudo dnf install -y rpmfusion-free-release-tainted
#   sudo dnf install -y rpmfusion-nonfree-release-tainted
#   sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm
#   sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm
#   sudo dnf install -y "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
#   sudo dnf install -y "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
#   sudo dnf install -y rpmfusion-free-release-tainted
#   sudo dnf install -y rpmfusion-nonfree-release-tainted
#   sudo dnf install -y fedora-workstation-repositories
#   sudo dnf update -y

#   sudo dnf config-manager --set-enabled google-chrome
#   sudo dnf config-manager --set-enabled rpmfusion-nonfree-steam
#   sudo dnf config-manager --set-enabled rpmfusion-free
#   sudo dnf config-manager --set-enabled rpmfusion-free-updates
#   sudo dnf config-manager --set-enabled fedora-cisco-openh264
#   sudo dnf groupupdate core
# }
# configure_repositories

configure_groups()
{
  sudo groupadd kvm || true
  sudo groupadd libvirt || true
  sudo groupadd wireshark || true
  sudo groupadd docker || true

  sudo usermod -aG kvm "$(whoami)" || true
  sudo usermod -aG libvirt "$(whoami)" || true
  sudo usermod -aG wireshark "$(whoami)" || true
  sudo usermod -aG docker "$(whoami)" || true

  # sudo gpasswd -a "${USER}" kvm || true
  # sudo gpasswd -a "${USER}" libvirt || true
  # sudo gpasswd -a "${USER}" wireshark || true
  # sudo gpasswd -a "${USER}" docker || true

  # sudo dnf group install -y 'Development Tools'
  # sudo dnf group install -y "C Development Tools and Libraries"

  # sudo dnf group install -y 'Virtualization'

  #   sudo dnf groupupdate -y core
  #   sudo dnf groupupdate -y multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
  #   sudo dnf groupupdate -y sound-and-video

  #   sudo dnf install -y rpmfusion-free-release-tainted
  #   sudo dnf install -y libdvdcss
}
configure_groups

# kernel_parameters_configuration() {
#   # # rd.driver.blacklist=nouveau modprobe.blacklist=nouveau nvidia-drm.modeset=1 rd.driver.blacklist=nouveau modprobe.blacklist=nouveau nvidia-drm.modeset=1
#   # sudo grubby --update-kernel=ALL --args="vconsole.keymap=gb"
#   # sudo grubby --update-kernel=ALL --args="loglevel=0 rd.udev.log_priority=0 rd.systemd.show_status=0"
#   # sudo grubby --update-kernel=ALL --args="libata.force=2.00:disable acpi_enforce_resources=lax amdgpu.ppfeaturemask=0xffffffff"
#   # sudo grubby --update-kernel=ALL --args="zswap.enabled=1 zswap.max_pool_percent=25 zswap.compressor=lz4hc"
#   # sudo grubby --update-kernel=ALL --remove-args="rhgb quiet" --args="rd.plymouth=0 plymouth.enable=0 logo.nologo nosplash verbose"
#   # echo '-------------------------------------------------------------------------------'
#   # sudo grubby --update-kernel=ALL --args="add_efi_memmap vconsole.keymap=gb rd.vconsole.keymap=gb rd.locale.LANG=en_GB.UTF-8 rd.locale.LC_ALL=en_GB.UTF-8 sysrq_always_enabled=1"
#   # sudo systemctl disable NetworkManager-wait-online.service
#   # sudo grubby --update-kernel=ALL --remove-args="rhgb splash" --args="add_efi_memmap sysrq_always_enabled=1 nosplash verbose iommu=pt amd_iommu=on amd_iommu=pt"
#   sudo grubby --update-kernel=ALL --remove-args="rhgb splash" --args="sysrq_always_enabled=1 nosplash verbose iommu=pt amd_iommu=on amd_iommu=pt rd.plymouth=0 plymouth.enable=0 logo.nologo"
# }
# kernel_parameters_configuration

setup_kernel_parameters()
{
  #   sudo grubby --update-kernel=ALL --remove-args="rhgb quiet" --args="sysrq_always_enabled=1 nosplash verbose"
  sudo grubby --update-kernel=ALL --remove-args="rhgb quiet" --args="crashkernel=2048M rd.driver.blacklist=nouveau modprobe.blacklist=nouveau nvidia-drm.modeset=1 sysrq_always_enabled=1 nosplash quiet"
  sudo systemctl disable NetworkManager-wait-online.service
}
setup_kernel_parameters

setup_go()
{
  LATEST="$(curl -sL 'https://go.dev/dl/?mode=json' | jq -r '.[0].version')"
  curl -L -s --output /tmp/go.tar.gz "https://go.dev/dl/${LATEST}.linux-amd64.tar.gz"
  mkdir -pv ~/.local
  tar -C ~/.local -xzf /tmp/go.tar.gz

  # curl -L -s --output /tmp/go.tar.gz https://go.dev/dl/go1.19.2.linux-amd64.tar.gz
  # mkdir -pv ~/.local
  # tar -C ~/.local -xzf /tmp/go.tar.gz

  go install github.com/go-delve/delve/cmd/dlv@latest
  go install sigs.k8s.io/kind@latest
  go install github.com/google/ko@latest

  go install github.com/cweill/gotests/gotests@latest
  # go install github.com/fatih/gomodifytags@latest
  # go install github.com/josharian/impl@latest
  # go install github.com/haya14busa/goplay/cmd/goplay@latest
  go install github.com/go-delve/delve/cmd/dlv@latest

  go install github.com/antonmedv/fx@latest
  go install github.com/mikefarah/yq/v4@latest
  go install github.com/andreazorzetto/yh@latest
  go install github.com/tomnomnom/gron@latest

  # go install github.com/dty1er/kubecolor/cmd/kubecolor@latest
  # go install github.com/andreazorzetto/yh@latest
  # go install sigs.k8s.io/controller-runtime/tools/setup-envtest@latest
  # go install sigs.k8s.io/kustomize/kustomize/v4@v4.5.4
  # go install sigs.k8s.io/kustomize/kustomize/v4@latest
  # go install sigs.k8s.io/controller-runtime/tools/setup-envtest@latest
  # go install sigs.k8s.io/kind@v0.14.0
  # go install sigs.k8s.io/kind@latest
  # go install sigs.k8s.io/controller-runtime/tools/setup-envtest@latest
  # go install github.com/rakyll/gotest@latest
  # go install github.com/mikefarah/yq/v4@latest
  # go install github.com/engineerd/wasm-to-oci
  # go install github.com/engineerd/wasm-to-oci@latest
  # go install github.com/engineerd/wasm-to-oci/cmd@latest
  # go install github.com/engineerd/wasm-to-oci/cmd
  # go install github.com/engineerd/wasm-to-oci/cmd@latest
  # go install github.com/derailed/k9s@latest
  # go install github.com/go-delve/delve/cmd/dlv@latest
  # go install github.com/simeji/jid/cmd/jid@latest
  # go install github.com/txn2/kubefwd
  # go install github.com/txn2/kubefwd@latestnvidiatlptl@latest
  # go install honnef.co/go/tools/cmd/staticcheck@
  # go install honnef.co/go/tools/cmd/staticcheck@latest
  # go install github.com/mikefarah/yq/v4@latest
  # go install honnef.co/go/tools/cmd/staticcheck@2022.1
  # go install honnef.co/go/tools/cmd/structlayout-pretty@2022.1
  # go install honnef.co/go/tools/cmd/structlayout-optimize@2022.1
  # go install honnef.co/go/tools/cmd/structlayout-optimize@2022.1
  # go install honnef.co/go/tools/cmd/structlayout-structlayout@2022.1
  # go install honnef.co/go/tools/cmd/structlayout@2022.1
  # go install honnef.co/go/tools/cmd/structlayout@2022.1
  # go install honnef.co/go/tools/cmd/keyify@2022.1
  # go install honnef.co/go/tools/cmd/keyify@2022.1
  # go install github.com/ajstarks/svgo/structlayout-svg
  # go install github.com/ajstarks/svgo/structlayout-svg@latest
  # go install golang.org/x/tools/go/analysis/passes/fieldalignment/cmd/fieldalignment@latest
  # go install github.com/google/ko@latest
  # go install github.com/google/ko@latest
  # go install ithub.com/google/ko@latest
  # go install github.com/google/ko@latest
  # go install sigs.k8s.io/kind@v0.14.0
  # go install github.com/bazelbuild/bazelisk@latest
  # go install sigs.k8s.io/kustomize/kustomize/v4@v4.5.4
  # go install github.com/GoogleContainerTools/kpt@latest
  # go install sigs.k8s.io/kustomize/kustomize/v4@v4.5.4
  # go install github.com/bazelbuild/bazelisk@latest
  # go install sigs.k8s.io/kind@v0.14.0
  # go install github.com/google/ko@latest
  # go install sigs.k8s.io/kustomize/kustomize/v4@latest
}
setup_go

setup_kubectl_tools()
{
  cd /tmp

  mkdir -pv ~/go/bin ~/go/.bin ~/bin ~/.bin

  sudo mkdir -pv /usr/local/bin/

  curl -Lo ~/bin/skaffold "https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-$([ $(uname -m) = "aarch64" ] && echo "arm64" || echo "amd64")"
  chmod ~/bin/skaffold
  skaffold version

  curl -Lo ~/bin/bazel "https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-$([ $(uname -m) = "aarch64" ] && echo "arm64" || echo "amd64")"
  chmod +x ~/bin/bazel
  bazel version

  curl -Lo ~/bin/minikube "https://storage.googleapis.com/minikube/releases/latest/minikube-linux-$([ $(uname -m) = "aarch64" ] && echo "arm64" || echo "amd64")"
  chmod  +x ~/bin/minikube
  minikube version

  curl -Lo ~/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$([ $(uname -m) = "aarch64" ] && echo "arm64" || echo "amd64")/kubectl"
  chmod +x ~/bin/kubectl
  # sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  kubectl version
  kubectl version --client

  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 get_helm.sh
  HELM_INSTALL_DIR="${HOME}/bin" ./get_helm.sh --no-sudo
  rm get_helm.sh

  minikube config set disk-size 32GB \
    && minikube config set cpus 8 \
    && minikube config set memory 16GB \
    && minikube config set driver docker \
    && minikube config set container-runtime containerd \
    && minikube config set container-runtime docker

  cat << EOF | tee ~/.minikube/config/config.json
{
    "container-runtime": "containerd",
    "cpus": "8",
    "disk-size": "32GB",
    "driver": "docker",
    "memory": "16GB"
}
EOF

  flatpak install --assumeyes --noninteractive flathub dev.k8slens.OpenLens
  sudo rpm --import https://downloads.k8slens.dev/keys/gpg
  sudo dnf config-manager --add-repo https://downloads.k8slens.dev/rpm/lens.repo
  sudo dnf install lens
}
setup_kubectl_tools

setup_software()
{
  sudo dnf install -y "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
  sudo dnf install -y "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

  sudo dnf install -y rpmfusion-free-release-tainted
  sudo dnf install -y rpmfusion-nonfree-release-tainted

  sudo dnf groupupdate -y core
  ##sudo dnf group update core

  sudo dnf install -y fedora-workstation-repositories
  sudo dnf config-manager -y --set-enabled google-chrome

  sudo dnf config-manager -y --set-enabled fedora-cisco-openh264
  sudo dnf install -y gstreamer1-plugin-openh264 mozilla-openh264

  sudo dnf update -y

  # sudo dnf install -y \
  #   redhat-lsb-core \
  #   util-linux-user \
  #   busybox \
  #   dnfdragora \
  #   kernel-devel kernel-headers kernel-tools util-linux-user \
  #   strace valgrind \
  #   gvim vim bash-completion \
  #   git git-lfs wget curl \
  #   alacritty \
  #   coreutils tree coreutils-common progress nmap arp-scan iproute net-tools iputils \
  #   bat fd-find ripgrep \
  #   fd-find ripgrep lsd exa bat procs hyperfine tealdeer \
  #   powerline vim-powerline tmux-powerline powerline-fonts fontawesome-fonts \
  #   steam \
  #   file-roller-nautilus gtkhash-nautilus seahorse-nautilus gnome-terminal-nautilus evince-nautilus nautilus-search-tool \
  #   mozilla-fira-fonts-common mozilla-fira-mono-fonts mozilla-fira-sans-fonts fira-code-fonts \
  #   fira-code-fonts 'mozilla-fira*' 'google-roboto*' \
  #   jq \
  #   yubikey-manager yubioath-desktop ykpers yubikey-personalization-gui \
  #   gpg gnupg2 \
  #   p7zip p7zip-plugins gzip xz bzip2 lzo lz4 lzma libknet1-compress-lz4-plugin \
  #   coreutils util-linux tree jq parallel \
  #   ShellCheck shfmt \
  #   neofetch screenfetch lm_sensors hw-probe iperf \
  #   inkscape gimp \
  #   meson ninja-build \
  #   sassc meson glib2-devel inkscape optipng \
  #   bonnie++ nvme-cli \
  #   corectrl \
  #   gparted blivet-gui \
  #   tree htop itop \
  #   make \
  #   cargo rust rust-debugger-common rust-doc rust-gdb rust-lldb rust-src rust-std-static rustfmt \
  #   clang llvm llvm-devel g++ gcc \
  #   golang \
  #   nodejs npm yarnpkg nodejs-typescript \
  #   gnome-extensions-app gnome-tweaks dconf-editor \
  #   gnome-shell-extension-appindicator \
  #   gnome-shell-extension-user-theme \
  #   gnome-shell-extension-system-monitor-applet \
  #   gnome-shell-extension-dash-to-dock \
  #   gnome-shell-extension-pop-shell \
  #   gnome-shell-extension-pop-shell-shortcut-overrides \
  #   gnome-shell-extension-appindicator \
  #   gnome-shell-extension-user-theme \
  #   gnome-shell-extension-common \
  #   gnome-shell-extension-gpaste \
  #   gnome-shell-extension-just-perfection \
  #   sassc meson glib2-devel inkscape optipng \
  #   numix-gtk-theme numix-icon-theme numix-icon-theme-circle numix-icon-theme-square \
  #   gtk-update-icon-cache pop-gtk4-theme pop-gnome-shell-theme pop-gtk2-theme pop-gtk3-theme numix-gtk-theme numix-icon-theme numix-icon-theme-circle numix-icon-theme-square gnome-shell-extension-user-theme pop-icon-theme pop-gtk4-theme xcursorgen \
  #   gnome-boxes gnome-break-timer \
  #   pandoc \
  #   texlive-scheme-full \
  #   'tex(footnote.sty)' 'tex(Alegreya.sty)' \
  #   google-chrome-stable google-chrome-beta google-chrome-unstable \
  #   chromium chromium-freeworld fedora-chromium-config \
  #   firefox-wayland textern mozilla-ublock-origin profile-cleaner mozilla-https-everywhere \
  #   mesa-demos vulkan-tools vkmark \
  #   mesa-vulkan-drivers vulkan-tools vulkan-loader libva-utils libva-vdpau-driver vdpauinfo libva-utils libva-vdpau-driver vdpauinfo \
  #   goverlay mangohud \
  #   vlc \
  #   gron \
  #   microdnf \
  #   nvme-cli \
  #   xsel xclip \
  #   gstreamer1-devel gstreamer1-plugins-base-devel gstreamer1-rtsp-server gstreamer1-rtsp-server-devel \
  #   NetworkManager-tui \
  #   unrar \
  #   file-roller \
  #   ark \
  #   xorg-x11-font-utils \

  # sudo dnf remove gnome-shell-extension-material-shell gnome-shell-extension-mediacontrols gnome-shell-extension-freon gnome-shell-extension-gamemode gnome-classic-session gnome-shell-extension-sound-output-device-chooser gnome-shell-extension-material-shell gnome-shell-extension-mediacontrols gnome-shell-extension-freon gnome-shell-extension-gamemode gnome-shell-extension-window-list gnome-shell-extension-auto-move-windows gnome-shell-extension-launch-new-instance gnome-shell-extension-places-menu gnome-shell-extension-apps-menu gnome-shell-extension-places-menu gnome-shell-extension-frippery-panel-favorites gnome-shell-extension-background-logo gnome-shell-extension-sound-output-device-chooser gnome-shell-extension-apps-menu gnome-shell-extension-window-list gnome-shell-extension-gamemode gamemode gnome-shell-extension-freon

  # #   mangohud goverlay libva-utils libva-vdpau-driver vdpauinfo \
  # # MANGOHUD=0 vkmark --present-mode immediate

  # https://robbinespu.github.io/eng/2018/05/29/fixing-pk-gtk-module-and-canberra-gtk-module.html
  sudo dnf install -y libcanberra-gtk3 libcanberra-gtk2 PackageKit-gtk3-module
  cat << EOF | sudo tee -a /etc/ld.so.conf.d/gtk2.conf
/usr/lib64/gtk-2.0/modules
EOF
  cat << EOF | sudo tee -a /etc/ld.so.conf.d/gtk3.conf
/usr/lib64/gtk-3.0/modules
EOF
  sudo ldconfig
}
setup_software

setup_vscode()
{
  # sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  cat << EOF | sudo tee /etc/yum.repos.d/vscode.repo
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
  sudo dnf install -y \
    code \
    code-insiders
  xdg-mime default code.desktop text/plain
  xdg-mime default code.desktop text/plain
  xdg-mime default code.desktop text/x-makefile
  xdg-mime default code.desktop text/x-go
  xdg-mime default code.desktop text/rust
  xdg-mime default code.desktop application/x-yaml
  xdg-mime default code.desktop application/json
  xdg-mime default code.desktop text/markdown
  xdg-mime default code.desktop audio/x-mod
  xdg-mime default code.desktop application/x-shellscript
  xdg-mime default code.desktop application/x-desktop
  xdg-mime default code.desktop application/xml
}
setup_vscode

setup_flatpak()
{
  echo '-------------------------------------------------------------------------------'
  # https://developer.fedoraproject.org/deployment/flatpak/flatpak-usage.html
  # https://docs.fedoraproject.org/en-US/flatpak/
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  flatpak update --appstream
  flatpak update --assumeyes --noninteractive
  flatpak install --assumeyes --noninteractive flathub com.yubico.yubioath
  flatpak install --assumeyes --noninteractive flathub flathub com.github.tchx84.Flatseal
  flatpak install --assumeyes --noninteractive flathub com.brave.Browser
  flatpak install --assumeyes --noninteractive flathub flathub com.raggesilver.BlackBox
  flatpak install --assumeyes --noninteractive flathub flathub com.github.micahflee.torbrowser-launcher
  flatpak install --assumeyes --noninteractive flathub flathub us.zoom.Zoom
  flatpak install --assumeyes --noninteractive flathub flathub com.slack.Slack
  flatpak install --assumeyes --noninteractive flathub flathub com.discordapp.Discord
  flatpak install --assumeyes --noninteractive flathub flathub com.skype.Client
  flatpak install --assumeyes --noninteractive flathub flathub org.telegram.desktop
  flatpak install --assumeyes --noninteractive flathub flathub org.signal.Signal
  flatpak install --assumeyes --noninteractive flathub flathub hu.irl.cameractrls
  flatpak install --assumeyes --noninteractive flathub flathub org.pipewire.Helvum
  flatpak install --assumeyes --noninteractive flathub flathub com.getpostman.Postman
  flatpak install --assumeyes --noninteractive flathub org.mozilla.firefox
  # flatpak install --assumeyes --noninteractive flathub org.kde.ark
  # flatpak remove --assumeyes --noninteractive flathub org.gnome.FileRoller
  flatpak update --appstream
  flatpak update --assumeyes --noninteractive
  echo '-------------------------------------------------------------------------------'
}
setup_flatpak

setup_browsers()
{
  sudo rpm --import https://repo.vivaldi.com/stable/linux_signing_key.pub
  sudo dnf config-manager --add-repo https://repo.vivaldi.com/archive/vivaldi-fedora.repo
  sudo dnf install -y \
    vivaldi-stable \
    vivaldi-snapshot
}
setup_browsers

# setup_sysctl_v1() {
#   sudo xdg-mime default code.desktop text/plain
#   echo 'vm.swappiness=4' | sudo tee /etc/sysctl.d/99-vm.conf
#   echo 'kernel.sysrq=1' | sudo tee /etc/sysctl.d/99-kernel.conf
#   echo 'kernel.dmesg_restrict=0' | sudo tee -a /etc/sysctl.d/99-kernel.conf
#   echo 'fs.inotify.max_user_watches=8192' | sudo tee /etc/sysctl.d/99-fs.conf
#   echo 'fs.inotify.max_user_instances=524288' | sudo tee -a /etc/sysctl.d/99-fs.conf
#   sudo sysctl -p
#   sudo sysctl --system
#   sysctl fs.inotify
#   echo
#   echo 'fs.inotify.max_user_watches=1048576' | sudo tee /etc/sysctl.d/99-fs.conf
#   echo 'fs.inotify.max_user_instances=1048576' | sudo tee -a /etc/sysctl.d/99-fs.conf
#   echo 'vm.swappiness=4' | sudo tee /etc/sysctl.d/99-vm.conf
#   echo
#   echo 'vm.swappiness=2' | sudo tee /etc/sysctl.d/99-vm.conf
#   echo 'kernel.sysrq=1' | sudo tee /etc/sysctl.d/99-kernel.conf
#   echo 'kernel.dmesg_restrict=0' | sudo tee -a /etc/sysctl.d/99-kernel.conf
#   echo 'fs.inotify.max_user_watches=2147483647' | sudo tee /etc/sysctl.d/99-fs.conf
#   echo 'fs.inotify.max_user_instances=2147483647' | sudo tee -a /etc/sysctl.d/99-fs.conf
#   sudo sysctl -p
#   sudo sysctl --system
#   sysctl fs.inotify
#   sysctl vm.swappiness
#   sysctl kernel.sysrq
# }
# setup_sysctl_v1

setup_sysctl()
{
  echo 'kernel.dmesg_restrict=0' | sudo tee -a /etc/sysctl.d/99-kernel.conf
  echo 'kernel.sysrq=1' | sudo tee /etc/sysctl.d/99-kernel.conf
  echo 'vm.swappiness=4' | sudo tee /etc/sysctl.d/99-vm.conf
  # echo 'fs.inotify.max_user_watches=8192' | sudo tee /etc/sysctl.d/99-fs.conf
  # echo 'fs.inotify.max_user_instances=524288' | sudo tee -a /etc/sysctl.d/99-fs.conf
  echo 'fs.inotify.max_user_watches=2147483647' | sudo tee /etc/sysctl.d/99-fs.conf
  echo 'fs.inotify.max_user_instances=2147483647' | sudo tee -a /etc/sysctl.d/99-fs.conf
  sudo sysctl -p
  sudo sysctl --system
  sysctl kernel.sysrq
  sysctl vm.swappiness
  sysctl fs.inotify
}
setup_sysctl

install_and_use_fonts()
{
  sudo dnf install -y \
    ibm-plex-serif-fonts ibm-plex-sans-fonts ibm-plex-mono-fonts \
    fonts-tweak-tool
  # sudo dnf install ibm-plex-fonts-all
  #   sudo dnf copr enable -y peterwu/iosevka
  #   sudo dnf install -y iosevka-fonts iosevka-term-fonts iosevka-fixed-fonts iosevka-ss05-fonts iosevka-term-ss05-fonts iosevka-fixed-ss05-fonts
  #   #gsettings set org.gnome.desktop.interface document-font-name 'Fira Sans Regular 11'
  #   #gsettings set org.gnome.desktop.interface font-name 'Fira Sans Regular 11'
  #   #gsettings set org.gnome.desktop.interface monospace-font-name 'Fira Mono Regular 11'
  #   #gsettings set org.gnome.desktop.interface monospace-font-name 'Iosevka 11'
  #   #gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Fira Sans Bold 11'
  #   #gsettings set org.gnome.desktop.interface font-hinting 'slight'
  #   fc-cache --force --really-force --verbose || true
  #   sudo fc-cache --force --really-force --system-only --verbose || true
}
install_and_use_fonts

# install_and_use_fonts_v2() {
#   # echo '-------------------------------------------------------------------------------'
#   # #   fontconfig-font-replacements provides free substitutions for popular proprietary fonts from Microsoft and Apple operating systems.
#   # #
#   # # It makes your web browsing more aesthetically pleasing - you won't be seeing DejaVu Sans font on every damn webpage.
#   # # https://github.com/silenc3r/fedora-better-fonts
#   # sudo dnf copr enable dawid/better_fonts -y
#   # sudo dnf install fontconfig-font-replacements -y
#   # sudo dnf install fontconfig-enhanced-defaults -y
#   # https://www.reddit.com/r/Fedora/comments/k2wxi1/a_copr_for_all_iosevka_ttf_variants/
#   # sudo dnf install -y '*iosevka*'
#   sudo dnf copr enable -y peterwu/iosevka
#   sudo dnf install -y iosevka-fonts iosevka-term-fonts iosevka-fixed-fonts iosevka-ss05-fonts iosevka-term-ss05-fonts iosevka-fixed-ss05-fonts
#   # sudo dnf install -y iosevka-fonts iosevka-term-fonts iosevka-fixed-fonts iosevka-aile-fonts iosevka-etoile-fonts iosevka-ss05-fonts iosevka-term-ss05-fonts iosevka-fixed-ss05-fonts

#   # # https://gist.github.com/alokyadav15/c3a2bbe6089ceff286215113bd092703
#   # TEMP_DIR="$(mktemp -d)"
#   # cd "${TEMP_DIR}"

#   # # git clone --depth=1 git@github.com:mozilla/Fira.git ./mozilla-Fira
#   # git clone --depth=1 https://github.com/mozilla/Fira.git ./mozilla-Fira
#   # sudo cp -r ./mozilla-Fira /usr/share/fonts/mozilla-Fira

#   # fc-cache --force --really-force --system-only --verbose /usr/share/fonts-mozilla-Fira || true
#   # fc-cache --force --really-force --system-only --verbose /usr/share/fonts/mozilla-Fira || true
#   # sudo fc-cache --force --really-force --system-only --verbose /usr/share/fonts-mozilla-Fira || true
#   # sudo fc-cache --force --really-force --system-only --verbose /usr/share/fonts/mozilla-Fira || true
#   # fc-cache --force --really-force --verbose || true
#   # fc-cache --force --really-force --system-only --verbose || true

#   gsettings set org.gnome.desktop.interface document-font-name 'Fira Sans Regular 10'
#   gsettings set org.gnome.desktop.interface font-name 'Fira Sans Regular 10'
#   gsettings set org.gnome.desktop.interface monospace-font-name 'Fira Mono Regular 10'
#   gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Fira Sans Bold 10'
#   gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'
#   gsettings set org.gnome.desktop.interface font-rgba-order 'rgb'
#   gsettings set org.gnome.desktop.interface font-hinting 'slight'

#   gsettings set org.gnome.desktop.interface text-scaling-factor 1.0
#   # cd ~
#   # rm -fr "${TEMP_DIR}"
# }
# install_and_use_fonts_v2

# sudo dnf upgrade --refresh
# sudo dnf groupupdate core

# sudo dnf groupinstall -y "System Tools" "Sound and Video" "C Development Tools and Libraries" "Administration Tools" "Cloud Management Tools" "Cloud Infrastructure" "Network Servers" "Headless Management"

# sudo dnf groupupdate sound-and-video
# sudo dnf install libdvdcss
# sudo dnf install gstreamer1-plugins-{bad-\*,good-\*,ugly-\*,base} gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel ffmpeg gstreamer-ffmpeg
# sudo dnf install lame\* --exclude=lame-devel
# sudo dnf group upgrade --with-optional Multimedia

# sudo dnf config-manager --set-enabled fedora-cisco-openh264
# sudo dnf install -y gstreamer1-plugin-openh264 mozilla-openh264

ssh_configuration()
{
  # chmod 755 ~/.ssh
  chmod -v 700 ~/.ssh
  chmod -v 600 ~/.ssh/config
  # chmod -v 600 ~/.ssh/authorized_keys
  chmod -v 644 ~/.ssh/authorized_keys
  cd ~/.ssh
  chmod -v 644 "$(ls -1 | grep id | grep .pub)"
  chmod -v 600 "$(ls -1 | grep id | grep -v pub)"
  eval "$(ssh-agent -s)"
  ssh-add "$(ls -1 | grep -v pub | grep id)"

  # sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
  # sudo dnf install -y gh
  # eval "$(ssh-agent -s)"
  # ssh-add $(ls -1 | grep -v pub | grep id)

  ssh -T git@gitlab.com
  ssh -T git@github.com
}

ssh_configuration

# function setup_tpm() {
#   cat << EOF | sudo tee -a /etc/modules-load.d/tpm.conf
# # https://docs.fedoraproject.org/en-US/fedora/latest/system-administrators-guide/kernel-module-driver-configuration/Working_with_Kernel_Modules/
# # Intel TPM on Razer Blade
# tpm
# tpm_infineon
# EOF
# }
# setup_tpm

setup_modprobe()
{
  cat << EOF | sudo tee -a /etc/modprobe.d/bluetooth.conf
# https://www.reddit.com/r/RetroPie/comments/aakkop/xbox_one_s_controller_disable_ertm_persist_on/
options bluetooth disable_ertm=1
EOF
  cat << EOF | sudo tee -a /etc/modprobe.d/iwlwifi.conf
# https://wireless.wiki.kernel.org/en/users/drivers/iwlwifi
options iwlwifi power_save=n
options iwlwifi power_level=5
#options iwlwifi debug=0x43fff
EOF
  cat << EOF | sudo tee -a /etc/modprobe.d/cfg80211.conf
# https://nullr0ute.com/2021/03/setting-the-wireless-regulatory-domain/
# https://wireless.wiki.kernel.org/en/developers/regulatory/crda
# https://www.linuxquestions.org/questions/slackware-14/network-manager-wifi-regional-settings-4175559295/
options cfg80211 ieee80211_regdom=GB
EOF
  sudo iw reg set GB
  #sudo iw reg set MA

  # echo 'options amdgpu vm_fragment_size=9 ppfeaturemask=0xffffffff' | sudo tee -a /etc/modprobe.d/amdgpu.conf
  # echo 'options ipv6 disable=1' | sudo tee -a /etc/modprobe.d/ipv6.conf
  # echo "options usbcore autosuspend=-1" | sudo tee -a /etc/modprobe.d/usbcore.conf
}
setup_modprobe

# docker_moby_install() {
#   sudo dnf install -y docker-compose moby-engine
#   sudo groupadd docker || true
#   #sudo gpasswd -a "$(whoami)" docker || true
#   sudo usermod -aG docker "$(whoami)" || true
#   sudo usermod -aG kvm "$(whoami)" || true
#   sudo usermod -aG libvirt "$(whoami)" || true
#   sudo systemctl start docker
#   sudo systemctl enable docker
#   sudo systemctl restart docker
#   sudo systemctl start docker && sudo systemctl start docker.socket && sudo systemctl start docker.service
#   newgrp docker
#   # docker run --rm -it alpine sh
# }
# docker_moby_install

# https://developer.fedoraproject.org/tools/docker/docker-installation.html
docker_configuration_non_free()
{
  sudo dnf remove \
    moby-engine \
    docker-compose \
    containerd
  sudo dnf config-manager -y --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
  sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose
  #  sudo grubby --update-kernel=ALL --args="systemd.unified_cgroup_hierarchy=0"
  sudo systemctl start docker
  sudo systemctl enable docker
  sudo groupadd docker || true
  sudo gpasswd -a "${USER}" docker || true
  sudo systemctl restart docker
  newgrp docker
}
docker_configuration_non_free

setup_cockpit()
{
  # sudo dnf install cockpit cockpit-podman cockpit-selinux cockpit-kdump cockpit-session-recording cockpit-navigator cockpit-networkmanager cockpit-storaged
  # sudo systemctl enable --now cockpit.socket
  # sudo firewall-cmd --add-service=cockpit
  # sudo firewall-cmd --add-service=cockpit --permanent
  sudo dnf install cockpit
  sudo systemctl enable --now cockpit.socket
  sudo firewall-cmd --add-service=cockpit
  sudo firewall-cmd --add-service=cockpit --permanent
}
setup_cockpit

# gh_install() {
#   sudo dnf install 'dnf-command(config-manager)'
#   sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
#   sudo dnf update -y
#   sudo dnf install -y gh
# }
# gh_install

# regenerate_grub() {
#   sudo dracut --force --verbose --regenerate-all
#   sudo grub2-mkconfig -o /boot/grub2/grub.cfg
#   sudo dracut --force --verbose --regenerate-all
# }
# regenerate_grub

setup_rust_tools()
{
  curl https://sh.rustup.rs -sSf | sh
  cargo install --force ripgrep
  cargo install --force fd-find
  cargo install --force bat
  sudo dnf install -y \
    lsd \
    exa

}
setup_rust_tools

setup_shell_tools()
{
  # go install mvdan.cc/sh/v3/cmd/shfmt@v3.4.0
  go install mvdan.cc/sh/v3/cmd/shfmt@latest

  sudo mkdir -pv /usr/local/bin/
  sudo ln -s /home/mbana/.cargo/bin/fd /usr/local/bin/fd
  sudo ln -s /home/mbana/.cargo/bin/rg /usr/local/bin/rg
  sudo ln -s /home/mbana/.cargo/bin/bat /usr/local/bin/bat
  # sudo ln -s /usr/bin/shellcheck /usr/local/bin/shellcheck
  # sudo ln -s /usr/bin/shfmt /usr/local/bin/shfmt
  /usr/bin/shfmt --version
  /usr/local/bin/shfmt --version
  /home/mbana/go/bin/shfmt --version
}
setup_shell_tools

setup_nvidia_ai()
{
  rpm --import https://nvidia.github.io/libnvidia-container/gpgkey
  curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
  sudo dnf install -y nvidia-container-toolkit
  sudo nvidia-ctk runtime configure --runtime=docker
  sudo systemctl restart --now docker
}
setup_nvidia_ai

setup_misc()
{
  sudo rpm --import https://www.cert.org/forensics/repository/forensics-expires-2022-04-03.asc
  sudo dnf config-manager --add-repo https://forensics.cert.org/cert-forensics-tools-release-38.rpm -y
  sudo dnf update -y
  sudo dnf install -y CERT-Forensics-Tools
}
setup_misc

setup_sensors()
{
  yes | sudo sensors-detect
}
setup_sensors

# setup_themes() {
#   sudo dnf install -y sassc meson glib2-devel inkscape optipng
#   sudo dnf install -y gtk-update-icon-cache pop-gtk4-theme pop-gnome-shell-theme pop-gtk2-theme pop-gtk3-theme numix-gtk-theme numix-icon-theme numix-icon-theme-circle numix-icon-theme-square gnome-shell-extension-user-theme pop-icon-theme pop-gtk4-theme xcursorgen
# }
# setup_themes

# setup_numix_theme() {
#   gsettings set org.gnome.desktop.interface cursor-theme "Numix-Cursor"
#   gsettings set org.gnome.desktop.interface icon-theme "Numix-Circle"
#   gsettings set org.gnome.desktop.interface gtk-theme "Numix"
#   gsettings set org.gnome.desktop.wm.preferences theme "Numix"
##   gsettings set org.gnome.desktop.sound theme-name "Default"
#   # # not sure about this
##   # gsettings set org.gnome.shell.extensions.user-theme name "Pop"
# }
# setup_numix_theme

# pop_os_theme_configuration() {
#   gsettings set org.gnome.desktop.interface icon-theme "Pop"
#   gsettings set org.gnome.desktop.interface cursor-theme "Pop"
#   gsettings set org.gnome.desktop.interface gtk-theme "Pop"
#   gsettings set org.gnome.desktop.wm.preferences theme "Pop"
##   gsettings set org.gnome.desktop.sound theme-name "Pop"
#   # # not sure about this
#   # gsettings set org.gnome.shell.extensions.user-theme name "Pop"
# }
# pop_os_theme_configuration

setup_dracut()
{
  # https://gist.github.com/raymanfx/7b672c9fa59996a73c049e507f33fafb
  cat << EOF | sudo tee /etc/dracut.conf.d/99-dracut.conf
# https://github.com/zfsonlinux/dracut/blob/master/dracut.conf.d/fedora.conf.example

#logfile=/var/log/dracut.log
#fileloglvl=6

hostonly="yes"
ro_mnt="no"
early_microcode="yes"
show_modules="yes"
use_fstab="yes"
reproducible="yes"

filesystems+=" btrfs ext4 "

# compress="lz4"

# add_drivers+="lz4hc lz4hc_compress"
force_drivers+=" i915 nvidia nvidia_modeset nvidia_uvm nvidia_drm tpm_infineon tpm "
#force_drivers+=" nvidia nvidia_modeset nvidia_uvm nvidia_drm nvidia_wmi_ec_backlight tpm tpm_infineon "
add_dracutmodules+=" network-manager bash busybox "
add_drivers+=" i915 nvidia nvidia_modeset nvidia_uvm nvidia_drm tpm_infineon tpm "
omit_dracutmodules+=" brltty multipath lvm nfs iscsi "

# install_items+=" /usr/lib/ossl-modules/legacy.so /usr/bin/nmcli "
install_items+=" vi vim grep /usr/local/bin/fd /usr/local/bin/rg /usr/local/bin/bat /usr/bin/nmcli "

# install local /etc/mdadm.conf
mdadmconf="no"
# install local /etc/lvm/lvm.conf
lvmconf="no"

# dracut_rescue_image="yes"

#i18n_vars="/etc/sysconfig/keyboard:KEYTABLE-KEYMAP /etc/sysconfig/i18n:SYSFONT-FONT,FONTACM-FONT_MAP,FONT_UNIMAP"
#i18n_default_font="latarcyrheb-sun16"
#i18n_default_font="/usr/lib/kbd/consolefonts/solar24x32.psfu.gz"
i18n_default_font="sun12x22"
#i18n_install_all="yes"
EOF
  sudo dracut --kver "$(uname -r)" --verbose --force --hostonly-i18n --hostonly
  # sudo dracut --force --hostonly-i18n --hostonly --verbose -a "bash busybox"
  # sudo dracut --kver "$(uname -r)" --force --hostonly-i18n --hostonly --verbose -a "bash busybox"
}
setup_dracut

setup_monitors()
{
  sudo mkdir -p /var/lib/gdm/.config
  sudo cp ~/.config/monitors.xml /var/lib/gdm/.config/monitors.xml
}
setup_monitors

sudo dnf autoremove

# sudo systemctl reboot
