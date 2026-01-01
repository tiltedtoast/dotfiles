{ inputs, ... }:

final: prev: {
  unstable = import inputs.nixpkgs-unstable {
    system = final.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };

  cuda = import inputs.nixpkgs {
    system = final.stdenv.hostPlatform.system;
    config.allowUnfree = true;
    config.cudaSupport = true;
  };
}
