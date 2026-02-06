{ ... }:

final: prev: {
  vencord = prev.vencord.overrideAttrs (oldAttrs: rec {
    version = "1.14.2";
    src = prev.fetchFromGitHub {
      owner = "Vendicated";
      repo = "Vencord";
      rev = "v${version}";
      hash = "sha256-1459x8G0++jH6NO5n4B5LVjDFjAFkLKFAQygVdqgOAk=";
    };
  });
}
