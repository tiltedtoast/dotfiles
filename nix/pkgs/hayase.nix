{
  lib,
  appimageTools,
  fetchurl,
  python3,
}:

appimageTools.wrapType2 rec {
  pname = "hayase";
  version = "6.4.29";

  src = fetchurl {
    url = "https://github.com/hayase-app/ui/releases/download/v${version}/linux-${pname}-${version}-linux.AppImage";
    sha256 = "sha256-w/+asNfLGZEyg+nI3aFjrCphLGkaXEHuobg6Se1jHR8=";
  };

  extraInstallCommands =
    let
      appimageContents = appimageTools.extractType2 { inherit pname version src; };
    in
    ''
      # Install desktop file
      install -Dm644 ${appimageContents}/${pname}.desktop $out/share/applications/${pname}.desktop

      # Fix desktop file to point to the wrapped binary
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=${pname} --no-sandbox %U'

      # Install icons
      for size in 16 32 48 64 128 256 512; do
        mkdir -p $out/share/icons/hicolor/''${size}x''${size}/apps
        if [ -f ${appimageContents}/usr/share/icons/hicolor/''${size}x''${size}/apps/${pname}.png ]; then
          install -Dm644 ${appimageContents}/usr/share/icons/hicolor/''${size}x''${size}/apps/${pname}.png \
            $out/share/icons/hicolor/''${size}x''${size}/apps/${pname}.png
        fi
      done

      # Fix python symlink if it exists in the AppImage
      if [ -d ${appimageContents}/opt/Hayase/resources/app.asar.unpacked/node_modules/@paymoapp/electron-shutdown-handler/build/node_gyp_bins ]; then
        mkdir -p $out/lib/${pname}/resources/app.asar.unpacked/node_modules/@paymoapp/electron-shutdown-handler/build/node_gyp_bins
        ln -sf ${python3}/bin/python $out/lib/${pname}/resources/app.asar.unpacked/node_modules/@paymoapp/electron-shutdown-handler/build/node_gyp_bins/python3
      fi
    '';

  meta = with lib; {
    description = "Formerly Miru. Torrent streaming made simple. Watch anime torrents, real-time with no waiting for downloads";
    homepage = "https://hayase.watch/";
    license = licenses.unfree;
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
