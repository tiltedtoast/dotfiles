{
  lib,
  stdenv,
  fetchFromGitHub,
  pnpm,
  makeWrapper,
  nodejs,
  python3,
  libxcrypt,
  unzip,
  fetchzip,
  autoPatchelfHook,
  electron,

  pango,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libgbm,
  expat,
  libxcb,
  libxkbcommon,
  systemd,
  alsa-lib,
  at-spi2-atk,
  nspr,
  nss,
  cups,
  gtk3,
  libGL,
  glib
}:

stdenv.mkDerivation rec {
  pname = "shiru";
  version = "6.4.2";

  electronVersion = "39.1.2";

  src = fetchFromGitHub {
    owner = "RockinChaos";
    repo = "Shiru";
    rev = "v${version}";
    hash = "sha256-pTXELNjAyJmDyqQGtakPMte+YzSlG7Erau5M8QbSgSA=";
  };

  buildInputs = [
    stdenv.cc.cc.lib
    libxcrypt
    pango
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libgbm
    expat
    libxcb
    libxkbcommon
    systemd
    alsa-lib
    at-spi2-atk
    nspr
    nss
    cups.lib
    gtk3
  ];

  nativeBuildInputs = [
    autoPatchelfHook
    pnpm.configHook
    nodejs
    python3
    makeWrapper
    unzip
  ];

  runtimeInputs = [
    glib
    libGL
  ];

  pnpmDeps = pnpm.fetchDeps {
    inherit pname version src;
    fetcherVersion = 1;
    hash = "sha256-pO9zQqsp2xQjQ5X9Y+tSGkEMV8fKNvPn5/KQ8T4N8t0=";
  };

  electronHeaders = fetchzip {
    url = "https://www.electronjs.org/headers/v${electronVersion}/node-v${electronVersion}-headers.tar.gz";
    hash = "sha256-bpk3RdMsP7c4A/KqVWErIyBmInTBsx9H7mCe8i6rC+8=";
  };

  electronDist = fetchzip {
    url = "https://github.com/electron/electron/releases/download/v${electronVersion}/electron-v${electronVersion}-linux-x64.zip";
    hash = "sha256-UcOa3NxkymKwGH9fpfSYVt7dKv6tuSWAyKM3GX7G6uc=";
    stripRoot = false;
  };

  buildPhase = ''
    runHook preBuild

    cd electron
    pnpm install

    export npm_config_nodedir=${electronHeaders}
    export npm_config_python=${python3}/bin/python3

    pnpm run web:build

    ./node_modules/.bin/electron-builder \
      --linux dir \
      -c.electronDist=${electronDist} \
      -c.electronVersion=${electronVersion}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/shiru
    cp -r dist $out/dist
    cp -r dist/linux-unpacked/resources $out/share/shiru/

    makeWrapper ${electron}/bin/electron $out/bin/shiru \
      --add-flags "$out/share/shiru/resources/app.asar" \
      --add-flags "--no-sandbox"

    runHook postInstall
  '';

  meta = {
    description = "Manage your personal media library, organize your collection, and stream your content in real time, no waiting required!";
    homepage = "https://github.com/RockinChaos/Shiru";
    license = lib.licenses.gpl3Only;
    maintainers = [ ];
    mainProgram = "shiru";
    platforms = [ "x86_64-linux" ];
  };
}
