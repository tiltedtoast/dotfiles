{ cudaPkgs, bash }:

cudaPkgs.nsight_systems.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    substituteInPlace $out/bin/nsys-ui \
      --replace-fail '/bin/bash' '${bash}/bin/bash'
  '';
})
