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

  piDockerfile = pkgs.writeText "Dockerfile.pi" ''
    FROM node:24-bookworm-slim
    RUN apt-get update \
      && apt-get install -y --no-install-recommends bash ca-certificates git ripgrep vim python3 \
      && rm -rf /var/lib/apt/lists/*
    RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent
    WORKDIR /workspace
    ENTRYPOINT ["pi"]
  '';

  aipi = pkgs.writeShellApplication {
    name = "aipi";
    runtimeInputs = [ pkgs.podman ];
    text = ''
      tag="pi-sandbox:$(basename ${piDockerfile} | cut -d- -f1)"
      if ! podman image exists "$tag"; then
        podman build -t "$tag" -f ${piDockerfile} "$(mktemp -d)"
      fi
      entrypoint=()
      if [[ "''${1:-}" == "--shell" ]]; then
        entrypoint=(--entrypoint /bin/bash)
        shift
      fi
      podman run --rm -it \
        -v pi-agent-home:/root/.pi/agent \
        -v "$PWD":/workspace:z \
        -w /workspace \
        "''${entrypoint[@]}" \
        "$tag" "$@"
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
    logisim-evolution

    # Shell apps
    aic
    aipi
  ];

  xdg.configFile = {
    "nvim".source        = link "nvim";
    "ghostty".source     = link "ghostty";
    "starship.toml".source = link "starship.toml";
    "rofi".source        = link "rofi";
    "tmux".source        = link "tmux";
  };
}
