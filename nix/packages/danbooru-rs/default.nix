{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
  stdenv,
  darwin,
}:

rustPlatform.buildRustPackage {
  pname = "danbooru-rs";
  version = "unstable-2024-01-24";

  src = fetchFromGitHub {
    owner = "tdortman";
    repo = "danbooru-rs";
    rev = "8b87e5ce54df92eed1d7f5a3ab0dfe5bd83ff86c";
    hash = "sha256-0PG2lp1fSIrGstyNPxZ7ioD7iYxfdX2aMnSUbwegPjQ=";
  };

  cargoHash = "sha256-KzWNLrEZ8V3JHbhdrJHcJuussuH0ItBWhuEWMtjUyWw=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    openssl
  ]
  ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.Security
    darwin.apple_sdk.frameworks.SystemConfiguration
  ];

  meta = {
    description = "A cli tool to download images from danbooru";
    homepage = "https://github.com/tdortman/danbooru-rs";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "danbooru-rs";
  };
}
