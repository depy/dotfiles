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

  programs.btop = {
    enable = true;
    settings = {
      color_theme = "TTY";
      theme_background = false;
    };
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
  ];

  xdg.configFile = {
    "nvim".source        = link "nvim";
    "ghostty".source     = link "ghostty";
    "starship.toml".source = link "starship.toml";
    "rofi".source        = link "rofi";
    "tmux".source        = link "tmux";
  };
}
