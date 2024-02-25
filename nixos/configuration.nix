{ config, pkgs, ... }:
{
  nixpkgs.config = {
    allowUnfree = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true; # (for UEFI systems only)
  users.users.mbana = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      coreutils
      gdb
      ffmpeg
      nixUnstable
      jq
      cowsay
      lolcat
      vim
      curl
      wget
      vscode
      plocate
    ];
    initialPassword = "sudo";
  };
  system.stateVersion = "23.11";

	# Enable the X11 windowing system.
	services.xserver.enable = true;

	# Enable the GNOME Desktop Environment.
	services.xserver.displayManager.gdm.enable = true;
	# services.xserver.desktopManager.gnome.enable = true;
  services.xserver.desktopManager.gnome = {
    enable = true;
    extraGSettingsOverrides = ''
      # Change default background
      [org.gnome.desktop.background]
      picture-uri='file://${pkgs.nixos-artwork.wallpapers.mosaic-blue.gnomeFilePath}'

      # Favorite apps in gnome-shell
      [org.gnome.shell]
      favorite-apps=['org.gnome.Console.desktop', 'org.gnome.Nautilus.desktop']
    '';
    extraGSettingsOverridePackages = [
      pkgs.gsettings-desktop-schemas # for org.gnome.desktop
      pkgs.gnome.gnome-shell # for org.gnome.shell
    ];
  };

  # Enable the OpenSSH server.
  services.sshd.enable = true;
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ0/4ug9qhgTD7zv8iGf1zcpHhrGG8fnkgTARINg5zUn Mohamed Bana (mohamed@bana.io)"
  ];

  # services.xserver.desktopManager.gnome.enable = true;
  # services.xserver.desktopManager.gdm.enable = true;

  services.gnome.tracker-miners.enable = false;
  services.gnome.tracker.enable = false;
  services.gnome.games.enable = false;
  services.gnome.core-developer-tools.enable = true;

  # environment.systemPackages = [
  #   gnomeExtensions.dash-to-dock
  #   gnomeExtensions.gsconnect
  #   gnomeExtensions.mpris-indicator-button
  # ];

  networking.networkmanager.enable = true;
  networking.hostName = "nixos";

  networking.firewall.enable = false;
  # networking.firewall.allowedTCPPorts = [ 80 443 ];

  networking.wireless.enable = true;

  # boot.initrd.services.udev.rules = ''
  #   SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", \
  #   ATTR{address}=="52:54:00:12:01:01", KERNEL=="eth*", NAME="wan"
  # '';

  # desktopManager = {
  #   gnome3.enable = true;
  #   xterm.enable = false;
  #   plasma5.enable = false;
  # };

  # displayManager = {
  #   gdm.enable = true;
  #   gdm.wayland = true; #not sure if this is important but I don't use wayland
  # };
}
