{
  lib,
  stdenv,
  appimageTools,
  fetchurl,
}:
let
  pname = "fluxer";
  version = "0.0.8";

  appImageArtifacts = {
    x86_64-linux = {
      url = "https://api.fluxer.app/dl/desktop/stable/linux/x64/fluxer-stable-${version}-x86_64.AppImage";
      hash = "sha256-GdoBK+Z/d2quEIY8INM4IQy5tzzIBBM+3CgJXQn0qAw=";
    };
    aarch64-linux = {
      url = "https://api.fluxer.app/dl/desktop/stable/linux/arm64/fluxer-stable-${version}-arm64.AppImage";
      hash = "sha256-wxLNekbw3E0YPcC27COWtp8VphKmBB9bF2dp7lnjPf8=";
    };
  };

  artifact =
    appImageArtifacts.${stdenv.hostPlatform.system}
      or (throw "Unsupported system for ${pname}: ${stdenv.hostPlatform.system}");

  src = fetchurl artifact;

  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/fluxer.desktop $out/share/applications/fluxer.desktop

    substituteInPlace $out/share/applications/fluxer.desktop \
      --replace-fail "Exec=AppRun --no-sandbox %U" "Exec=fluxer --no-sandbox %U"

    mkdir -p $out/share/icons
    cp -r ${appimageContents}/usr/share/icons/hicolor $out/share/icons/
  '';

  meta = with lib; {
    description = "A free and open source instant messaging and VoIP platform built for friends, groups, and communities.";
    homepage = "https://fluxer.app";
    license = licenses.unfree;
    mainProgram = "fluxer";
    platforms = builtins.attrNames appImageArtifacts;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
