# NixOS Configuration

## Architecture
- **Target**: x86_64-linux, AMD Ryzen AI 9 HX PRO 370, Radeon 890M iGPU, 27 GiB RAM
- **Runtime**: bare metal (personal laptop/desktop)
- **Interface**: sway (Wayland tiling WM), TTY1 autologin → `exec sway`
- **Disk**: `/dev/nvme0n1` — GPT, 1 GiB ESP + LUKS(LVM: 32 GiB swap + ext4 root)
- **Hibernate**: yes (swap ≥ RAM, inside LUKS); lid-close → suspend-then-hibernate

## Key decisions
- Flakes-based, inputs: `nixpkgs (unstable)`, `disko`, `home-manager`
- Host: `affixos` (single host for now; see `hosts/affixos/`)
- User-level config (sway, neovim, terminal, bar, notifier) in `home/affixpin.nix` via home-manager as a NixOS module
- SSH key-only, no root login
- Sudo requires password
- Full-disk encryption via LUKS, one passphrase at boot

## Layout
```
flake.nix
hosts/affixos/
  configuration.nix            # system
  disk-config.nix              # disko
  hardware-configuration.nix   # regenerate on target before install
home/
  affixpin.nix                 # home-manager
```

## Install procedure
On the target (booted from NixOS 25.11 installer ISO):
1. `nixos-generate-config --root /mnt --no-filesystems` then copy the generated `hardware-configuration.nix` into `hosts/affixos/` and commit.
2. `nix run github:nix-community/disko -- --mode disko --flake .#affixos` (formats + mounts; prompts for LUKS passphrase).
3. `nixos-install --flake .#affixos` (set root password when prompted; the `affixpin` user will use `passwd` post-install to set their own).
4. Reboot, unlock LUKS, land in sway on TTY1.
