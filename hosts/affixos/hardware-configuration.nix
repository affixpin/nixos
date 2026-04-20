{ config, lib, pkgs, modulesPath, ... }:

# Placeholder. Regenerate on the target machine during install with:
#   nixos-generate-config --root /mnt --no-filesystems
# then replace this file with the generated one (fileSystems are owned by disko).

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
