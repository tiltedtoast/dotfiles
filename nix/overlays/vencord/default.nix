{ ... }:

final: prev: {
  vencord = prev.vencord.overrideAttrs (oldAttrs: {
    version = "1.14.1";
    src = prev.fetchFromGitHub {
      owner = "Vendicated";
      repo = "Vencord";
      rev = "v1.14.1";
      hash = "sha256-g+zyq4KvLhn1aeziTwh3xSYvzzB8FwoxxR13mbivyh4=";
    };
  });
}
