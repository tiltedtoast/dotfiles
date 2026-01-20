{
  lib,
  appimageTools,
  requireFile,
  runCommand,
  gnutar,
}:

let
  pname = "GitButler";
  version = "0.18.4";
  buildNumber = "2771";

  tarball = requireFile {
    name = "${pname}_${version}_amd64.AppImage.tar.gz";
    url = "https://releases.gitbutler.com/releases/release/${version}-${buildNumber}/linux/x86_64/${pname}_${version}_amd64.AppImage.tar.gz";
    sha256 = "06e6a10d892f7564f152559daff06b67e13f54fc8e008d9ab267e60103c4637b";
  };

  unzipped =
    runCommand "extract-gitbutler"
      {
        buildInputs = [ gnutar ];
        src = tarball;
      }
      ''
        mkdir -p $out
        tar xf $src -C $out
      '';

in
appimageTools.wrapType2 rec {
  inherit pname version;

  src = "${unzipped}/${pname}_${version}_amd64.AppImage";

  extraInstallCommands =
    let
      extracted = appimageTools.extractType2 { inherit pname version src; };
    in
    ''
      install -Dm644 ${extracted}/${pname}.desktop $out/share/applications/${pname}.desktop

      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace "Exec=gitbutler-tauri" "Exec=${extracted}/bin/gitbutler"

      install -Dm644 ${extracted}/usr/share/icons/hicolor/256x256@2/apps/gitbutler-tauri.png $out/share/icons/hicolor/256x256@2/apps/${pname}.png
    '';

  meta = with lib; {
    description = "Git client for simultaneous branches on top of your existing workflow";
    homepage = "https://gitbutler.com";
    license = licenses.fsl11Mit;
    platforms = platforms.linux;
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
}
