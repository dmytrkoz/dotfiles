{ config, lib, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in

{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";
  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep   # fast search
    fd        # fast find
    fzf       # fuzzy finder
    jq        # json on the command line
    lazygit
    nodejs    # runtime for npm-installed agent tools
    neovim
    # the font everything renders in
    nerd-fonts.hack
  ];
  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "nvim";
  # The nix store is read-only, so `npm install -g` goes to a user-owned prefix instead.
  home.sessionVariables.NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  # Android SDK packages live in a user-owned root so cask upgrades never wipe them.
  home.sessionVariables.ANDROID_HOME = "$HOME/Library/Android/sdk";
  home.sessionVariables.JAVA_HOME = "/Library/Java/JavaVirtualMachines/zulu-21.jdk/Contents/Home";
  # Self-updating CLIs (installed outside nix) land in these.
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.npm-global/bin"
    "$HOME/Library/Android/sdk/platform-tools"
    "$HOME/Library/Android/sdk/emulator"
  ];

  # gh, plus its git credential helper so https pushes use the gh login.
  programs.gh.enable = true;

  # Enabled so home-manager can write gh's credential helper into ~/.config/git/config.
  # Identity deliberately stays out of this repo (see README "Make it yours").
  programs.git.enable = true;

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    initContent = ''
      bindkey '^f' autosuggest-accept
    '';
    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      cc = "claude --dangerously-skip-permissions";
      co = "codex --full-auto";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";
  # Claude's settings.json must stay writable: tools such as herdr add their own hooks to it.
  # Each switch merges the keys authored in this repo over the live file, so repo values win
  # and anything a tool added is kept.
  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    settings="$HOME/.claude/settings.json"
    run mkdir -p "$HOME/.claude"
    if [ -L "$settings" ]; then
      # A previous generation linked this file; keep its content but make it a real file.
      run cp --remove-destination "$(readlink -f "$settings")" "$settings"
    fi
    if [ -e "$settings" ]; then
      merged="$(${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$settings" ${./home/.claude/settings.json})"
      if [ -z "''${DRY_RUN:-}" ]; then
        tmp="$(mktemp "$settings.XXXXXX")"
        printf '%s\n' "$merged" > "$tmp"
        mv "$tmp" "$settings"
      else
        echo "would merge ${./home/.claude/settings.json} into $settings"
      fi
    else
      run install -m 644 ${./home/.claude/settings.json} "$settings"
    fi
  '';

  # Keep Pi's credential and runtime state local by linking only authored files and directories.
  home.file.".pi/agent/themes".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/themes";
  home.file.".pi/agent/extensions".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/extensions";
  home.file.".pi/agent/models.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/models.json";
  home.file.".pi/agent/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/settings.json";

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
