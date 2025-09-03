{
  cudaPkgs,
}:

self: super: {
  cudaPkgs = super.cudaPkgs // {
    nsight_systems = cudaPkgs.nsight_systems.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        substituteInPlace $out/bin/nsys-ui \
          --replace-fail '/bin/bash' '${super.bash}/bin/bash'
      '';
    });
  };
}
