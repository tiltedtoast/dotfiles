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

      tooltipDelay = 200;
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

    powerdevil.AC = {
      powerButtonAction = "hibernate";
      autoSuspend.action = "nothing";
      whenSleepingEnter = "standbyThenHibernate";
      turnOffDisplay.idleTimeout = "never";
    };

    session.sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";

    configFile = {
      plasmashellrc."PlasmaViews/Panel 25/Defaults".thickness = 48;
      plasmashellrc."PlasmaViews/Panel 3/Defaults".thickness = 48;

      kdeglobals.Sounds.Enable = false;
      kdeglobals.General.TerminalApplication = "ghostty";
      kdeglobals.General.TerminalService = "com.mitchellh.ghostty.desktop";

      kdeglobals.General.AccentColor = "#926ee4";
      baloofilerc."Basic Settings".Indexing-Enabled = false;

      kcminputrc."Libinput/1133/50503/Logitech USB Receiver".PointerAccelerationProfile = 1;

      kwinrulesrc."a5f27bc3-c738-4dd0-9cef-ee580d3e981a".desktopfile =
        "/run/current-system/sw/share/applications/StreamController.desktop";
    };

    startup.startupScript = {
      discord = {
        text = ''
          setsid discord &
        '';
        runAlways = true;
      };

      spotify = {
        text = ''
          setsid spotify &
        '';
        runAlways = true;
      };
    };

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
