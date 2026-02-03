{ ... }:

final: prev: {
  kdotool = prev.kdotool.overrideAttrs (oldAttrs: {
    patches = [
      (prev.fetchpatch {
        url = "https://github.com/jinliu/kdotool/commit/049e3f5620ad8c5484241d7d06d742bc17d423ed.patch";
        hash = "sha256-VTpHlT6XMVRgJIeLjxZPHkzaYFZCYtS8IAD0mKZ8rzs=";
      })
      (prev.fetchpatch {
        url = "https://github.com/jinliu/kdotool/commit/e0a3bff3b5d9882033dd72836e5fcff572b64135.patch";
        hash = "sha256-6IsV9O2h9N/FxGQRHS8qAbEqdr7282ziGza5K52vpPk=";
      })
    ];
  });
}
