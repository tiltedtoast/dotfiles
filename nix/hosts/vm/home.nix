{
  pkgs,
  ...
}:

{
  home.stateVersion = "25.11";

  imports = [
    ../../modules/home/1password.nix
  ];

  programs.plasma = {
    enable = true;
    overrideConfig = true;

    workspace = {
      theme = "breeze-dark";
      lookAndFeel = "org.kde.breezedark.desktop";
      wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/MilkyWay/contents/images/5120x2880.png";

      enableMiddleClickPaste = true;
    };

    kscreenlocker = {
      autoLock = false;
      appearance.showMediaControls = false;
    };

    kwin = {
      effects.shakeCursor.enable = false;

      titlebarButtons = {
        left = [
          "more-window-actions"
          "keep-above-windows"
          "keep-below-windows"
        ];

        right = [
          "help"
          "minimize"
          "maximize"
          "close"
        ];
      };

      edgeBarrier = 0;
      cornerBarrier = false;
    };

    fonts =
      let
        inter = size: {
          family = "Inter";
          pointSize = size;
        };
      in
      {
        small = inter 8;
        general = inter 10;
        toolbar = inter 10;
        menu = inter 10;
        windowTitle = inter 10;

        fixedWidth = {
          family = "ComicCodeLigatures Nerd Font Mono";
          pointSize = 10;
        };
      };

    windows.allowWindowsToRememberPositions = true;

    shortcuts = {
      "services/systemsettings.desktop" = {
        _launch = "Meta+I";
      };
      "services/com.mitchellh.ghostty.desktop" = {
        new-window = "Meta+Return";
      };
    };

    session.sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";

    configFile."kdeglobals"."General"."AccentColor" = "#926ee4";
    configFile."baloofilerc"."Basic Settings"."Indexing-Enabled" = false;
  };

  programs.konsole = {
    enable = true;
    defaultProfile = "default";

    profiles.default = {
      font = {
        name = "ComicCodeLigatures Nerd Font Mono";
        size = 14;
      };
    };
  };
}
