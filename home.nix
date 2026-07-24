{ config, pkgs, ... }:

let
  link = path:
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/config/${path}";

  # Run the AI agent in a container, mounting only the current directory
  # so it has no access to the rest of the file system.
  aic = pkgs.writeShellApplication {
    name = "aic";
    text = ''
      podman run --rm -it \
        -v claude-home:/root \
        -v "$PWD":/work:z \
        -w /work \
        docker.io/library/node:22 \
        npx --yes @anthropic-ai/claude-code "$@"
    '';
  };
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

  programs.bat = {
    enable = true;
  };

  catppuccin = {
    enable = true;      # not the global auto-enroll
    autoEnable = false;  # matches enable, suppresses the warning
    flavor = "mocha";
    bat.enable = true;   # per-app opt-in still works
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
    nerd-fonts.jetbrains-mono
    obsidian
    fzf
    ripgrep
    bat

    # Shell apps
    aic
  ];

  xdg.configFile = {
    "nvim".source        = link "nvim";
    "ghostty".source     = link "ghostty";
    "starship.toml".source = link "starship.toml";
    "rofi".source        = link "rofi";
    "tmux".source        = link "tmux";
  };
}
