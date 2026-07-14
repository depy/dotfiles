{ config, pkgs, ... }:

let
  link = path:
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/config/${path}";
in
{
  home.username = "matjaz";
  home.homeDirectory = "/home/matjaz";

  # Match your system.stateVersion. Don't change after first build.
  home.stateVersion = "26.05";

  # Let Home Manager manage itself.
  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    shellAliases = {
      ff = "fastfetch";
      aic = "podman run --rm -it -v claude-home:/root -v \"$PWD\":/work:z -w /work docker.io/library/node:22 npx --yes @anthropic-ai/claude-code";
    };
  };

  programs.btop = {
    enable = true;
    settings = {
      color_theme = "TTY";
      theme_background = false;
    };
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;   # default true when enabled
  };

  # Add user packages here
  home.packages = with pkgs; [
    neovim
    ghostty
    starship
    rofi
    vlc
    fastfetch
    tmux
    xournalpp
    qbittorrent
    chromium
    gh
    tio
    kicad
    prismlauncher
    zed-editor
    nerd-fonts.jetbrains-mono
  ];

  xdg.configFile = {
    "nvim".source        = link "nvim";
    "ghostty".source     = link "ghostty";
    "starship.toml".source = link "starship.toml";
    "rofi".source        = link "rofi";
    "tmux".source        = link "tmux";
  };
}
