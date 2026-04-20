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
  networking.networkmanager = {
    enable = true;
    # Use systemd-resolved for DoT/DNSSEC capabilities below.
    dns = "systemd-resolved";
    # Randomize MAC per-connection to prevent passive tracking across networks.
    wifi.macAddress = "random";
    ethernet.macAddress = "random";
  };

  # Encrypted + validated DNS. "opportunistic"/"allow-downgrade" keep captive
  # portals working; raise to "true" for strict DoT / strict DNSSEC.
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "allow-downgrade";
      DNSOverTLS = "opportunistic";
      FallbackDNS = [ "1.1.1.1#one.one.one.one" "9.9.9.9#dns.quad9.net" ];
    };
  };

  # Firewall — deny inbound by default. SSH port (22) is opened by
  # services.openssh.openFirewall (default true); nothing else is exposed.
  networking.firewall = {
    enable = true;
    allowPing = false;
  };

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

  # SSH — key-only, no root, modern crypto only
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      MaxAuthTries = 3;
      LoginGraceTime = 10;
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;
      X11Forwarding = false;
      AllowAgentForwarding = false;
      AllowTcpForwarding = "local";
      KexAlgorithms = [
        "sntrup761x25519-sha512@openssh.com"
        "curve25519-sha256"
        "curve25519-sha256@libssh.org"
      ];
      Ciphers = [
        "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com"
        "aes128-gcm@openssh.com"
      ];
      Macs = [
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.com"
        "umac-128-etm@openssh.com"
      ];
    };
  };

  # SSH bruteforce mitigation (belt-and-suspenders: we're already key-only).
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime = "1h";
  };

  # Power / hibernate — lid-close suspends to RAM, falls back to disk after a while
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend-then-hibernate";
  };

  # Periodic TRIM for NVMe
  services.fstrim.enable = true;

  # Kernel & network sysctl hardening.
  boot.kernel.sysctl = {
    # Restrict kernel info leaks to non-root processes.
    "kernel.dmesg_restrict" = 1;
    "kernel.kptr_restrict" = 2;
    # Only a parent process can ptrace its descendants.
    "kernel.yama.ptrace_scope" = 2;
    # Disable live kernel replacement via kexec.
    "kernel.kexec_load_disabled" = 1;
    # Harden BPF: root-only + JIT hardening against spectre-style attacks.
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.core.bpf_jit_harden" = 2;
    # Network hygiene.
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
  };

  # Mandatory access control — upstream profiles cover browsers and common apps.
  security.apparmor = {
    enable = true;
    packages = [ pkgs.apparmor-profiles ];
  };

  # Core dumps can leak secrets from memory; disable them globally.
  systemd.coredump.enable = false;

  # Only wheel members can run sudo; non-wheel users cannot escalate at all.
  security.sudo.execWheelOnly = true;

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
