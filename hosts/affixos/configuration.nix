{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "affixos";

  # Use latest kernel for best ARM64/virtio performance on UTM
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # QEMU guest support for UTM integration
  services.qemuGuest.enable = true;

  # Headless - SSH access only
  services.openssh.enable = true;

  # User account
  users.users.affixpin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE4uCUGlax7XEqFEJyovatfYi/A8T0tFh1hpcc60sF2B affixpin@Mac"
    ];
  };

  # Passwordless sudo for wheel
  security.sudo.wheelNeedsPassword = false;

  # Timezone & locale
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  # Static IP for UTM bridge network
  networking.useDHCP = false;
  networking.interfaces.enp0s1 = {
    ipv4.addresses = [{
      address = "192.168.64.5";
      prefixLength = 24;
    }];
  };
  networking.defaultGateway = "192.168.64.1";
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
  ];

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Nix garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  system.stateVersion = "24.11";
}
