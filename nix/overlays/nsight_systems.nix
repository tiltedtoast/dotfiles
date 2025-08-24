self: super: {
  cudaPackages = super.cudaPackages // {
    nsight_systems = super.cudaPackages.nsight_systems.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        substituteInPlace $out/bin/nsys-ui \
          --replace-fail '/bin/bash' '${super.bash}/bin/bash'
      '';
    });
  };
}
