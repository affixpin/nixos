{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Hardware
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Networking
  networking.hostName = "affixos";
  networking.networkmanager.enable = true;

  # Audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Sway (system-level: package, session, portal integration)
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    config.sway.default = [ "wlr" "gtk" ];
  };
  security.polkit.enable = true;

  # TTY1 autologin → user's login shell execs sway (see home/affixpin.nix)
  services.getty.autologinUser = "affixpin";

  # System-level fish: registers /etc/shells entry and sources NixOS vendor configs
  # so PATH + completions work when fish is a login shell.
  programs.fish.enable = true;

  fonts.packages = with pkgs; [
    dejavu_fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    nerd-fonts.jetbrains-mono
  ];

  # SSH — key-only, no root
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Power / hibernate — lid-close suspends to RAM, falls back to disk after a while
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend-then-hibernate";
  };

  # Periodic TRIM for NVMe
  services.fstrim.enable = true;

  # USB auto-mount (used when dropping ZMK .uf2 firmware onto the nice!nano in DFU mode)
  services.udisks2.enable = true;

  # User
  users.users.affixpin = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE4uCUGlax7XEqFEJyovatfYi/A8T0tFh1hpcc60sF2B affixpin@Mac"
    ];
  };

  # Locale
  time.timeZone = "Europe/Lisbon";
  i18n.defaultLocale = "en_US.UTF-8";

  # System-wide packages (user tools live in home-manager)
  environment.systemPackages = with pkgs; [
    git
    vim
    htop
    pciutils
    usbutils
    wget
  ];

  # Nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  system.stateVersion = "25.11";
}
