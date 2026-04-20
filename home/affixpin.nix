{ config, pkgs, lib, ... }:

{
  home.username = "affixpin";
  home.homeDirectory = "/home/affixpin";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  # Auto-mount removable USB (nice!nano v2 in DFU mode shows up as mass storage)
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "auto";
  };

  # Clone personal editable configs on first activation, then symlink them from
  # ~/.config so changes can be committed in place.
  home.activation.cloneEditableConfigs = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/repositories"
    if [ ! -e "$HOME/repositories/nvim" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://github.com/affixpin/nvim.git "$HOME/repositories/nvim"
    fi
    if [ ! -e "$HOME/repositories/zellij" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://github.com/affixpin/zellij.git "$HOME/repositories/zellij"
    fi
  '';

  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/repositories/nvim";
  xdg.configFile."zellij".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/repositories/zellij";

  # Auto-exec sway on TTY1 after autologin
  programs.fish = {
    enable = true;
    loginShellInit = ''
      if test -z "$WAYLAND_DISPLAY"; and test "$XDG_VTNR" = "1"
        exec sway
      end
    '';
    shellAliases = {
      v = "nvim";
    };
    interactiveShellInit = ''
      fish_vi_key_bindings
      set -gx BAT_THEME Dracula
    '';
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withRuby = false;
    withPython3 = false;
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = "Dmytro Pintak";
      email = "dmytro.pintak@gmail.com";
    };
  };

  # Sway user config — system sway package is installed by NixOS
  wayland.windowManager.sway = {
    enable = true;
    package = null;
    wrapperFeatures.gtk = true;
    config = {
      modifier = "Mod4";
      terminal = "foot";
      menu = "fuzzel";
      bars = [{ command = "waybar"; }];
      input."type:keyboard" = {
        # Layouts cycled via Alt+Shift. Caps → Escape.
        # ctrl:swap_lwin_lctl swaps Super/Ctrl so ZMK home-row mods (Cmd on
        # F/J, designed for macOS) behave as Ctrl on Linux without reflashing.
        xkb_layout = "us,ua,ru";
        xkb_options = "caps:escape,grp:alt_shift_toggle,ctrl:swap_lwin_lctl";
      };
      input."type:touchpad" = {
        tap = "enabled";
        natural_scroll = "enabled";
      };
    };
    extraConfig = ''
      exec mako
      exec blueman-applet
      exec nm-applet --indicator
      exec swayidle -w \
        timeout 300 'swaylock -f -c 000000' \
        timeout 600 'systemctl suspend' \
        before-sleep 'swaylock -f -c 000000'

      # Screenshots — matches ZMK mac_ss4/mac_ss5 after ctrl:swap_lwin_lctl.
      # Saves to ~/Pictures/Screenshots AND copies to the clipboard.
      bindsym Ctrl+Shift+4 exec sh -c 'mkdir -p ~/Pictures/Screenshots && grim -g "$(slurp)" - | tee ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png | wl-copy -t image/png'
      bindsym Ctrl+Shift+5 exec sh -c 'mkdir -p ~/Pictures/Screenshots && grim - | tee ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png | wl-copy -t image/png'
    '';
  };

  home.packages = with pkgs; [
    # Sway userland
    foot
    waybar
    fuzzel
    mako
    swaylock
    swayidle
    grim
    slurp
    wl-clipboard
    brightnessctl
    playerctl
    pavucontrol
    networkmanagerapplet
    chromium

    # Terminal multiplexer used by the zellij-nav.nvim plugin
    zellij

    # Neovim runtime deps
    gcc                          # compile treesitter parsers
    tree-sitter                  # treesitter CLI
    cargo                        # build blink.cmp's rust matcher
    rustc
    fzf ripgrep fd               # fzf-lua

    # Go toolchain (provides gofmt; gotools provides goimports)
    go
    gotools
    golangci-lint
    gopls

    # Rust LSP
    rust-analyzer

    # Lua
    lua-language-server
    stylua
    luaPackages.luacheck

    # JS/TS
    nodejs
    typescript-language-server
    nodePackages.prettier
    nodePackages.eslint_d

    # Shell tooling
    bat
    delta

    # Shell
    shfmt
  ];
}
