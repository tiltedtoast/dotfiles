{ inputs, pkgs, ... }:
{
  programs.spicetify =
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      enable = true;

      enabledExtensions = with spicePkgs.extensions; [
        {
          src = pkgs.fetchFromGitHub {
            owner = "41pha1";
            repo = "spicetify-extensions";
            rev = "5015b9122a9c39274bdc7507e1de4fec0cc20f95";
            hash = "sha256-JkkIs40Kp57kLTcb95WIgfHDoCP/LHZ3TmdP1w1e1OY=";
          };
          name = "romaji-lyrics/romaji_lyrics.js";
        }
        {
          src = pkgs.fetchFromGitHub {
            owner = "theblockbuster1";
            repo = "spicetify-extensions";
            rev = "b156cfcf9ed603e131ac2241bf00d7010e1c53e9";
            hash = "sha256-tNgIXOTR1Wzl6u7bvcgbx4Gqe8/UfKXZuoXqw666G7E=";
          };
          name = "CoverAmbience/CoverAmbience.js";
        }
        {
          src = pkgs.fetchFromGitHub {
            owner = "resxt";
            repo = "spicetify-extensions";
            rev = "75bd17ba1c9a19730f14529fb18857d7b9c7c12e";
            hash = "sha256-+Th5o00c3Y8U+Y/RGmRSkWWp97YCoCJmoESFLZf9dwM=";
          };
          name = "startup-page/dist/startup-page.js";
        }
        fullAlbumDate
        shuffle
        seekSong
      ];

      enabledCustomApps = with spicePkgs.apps; [
        historyInSidebar
      ];

      enabledSnippets = with spicePkgs.snippets; [
        roundedButtons
        smoothPlaylistRevealGradient
        prettyLyrics
        fixMainViewWidth
        roundedImages
      ];

      theme = spicePkgs.themes.lucid;
    };
}
