{ user, ... }:

{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;          # fast key repeat
      InitialKeyRepeat = 15;  # short delay before repeat
      _HIHideMenuBar = true;  # auto-hide the menu bar
      AppleShowAllExtensions = true;
    };
    dock.autohide = true;
    finder.FXPreferredViewStyle = "Nlsv";  # list view by default
    finder.CreateDesktop = false;          # clean desktop
    trackpad.Clicking = true;              # tap to click
  };
  # Never idle-sleep while on the charger, so long-running agents keep working unattended.
  # Battery keeps macOS's default sleep behaviour; nix-darwin's power.sleep.computer would apply to both.
  system.activationScripts.postActivation.text = ''
    /usr/bin/pmset -c sleep 0
  '';

  nix-homebrew = {
    enable = true;
    inherit user;
  };
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";  # remove anything not listed here
    onActivation.autoUpdate = true;
    onActivation.extraFlags = [ "--force" ];
    brews = [
      "herdr"
    ];
    casks = [
      "wezterm"
      "claude-code"
      "visual-studio-code"
      "docker-desktop"
      "android-commandlinetools"  # sdkmanager/avdmanager; the SDK itself lives in ~/Library/Android/sdk
      "zulu@21"                   # JDK 21 for Android/Capacitor Gradle builds
    ];
  };
}
