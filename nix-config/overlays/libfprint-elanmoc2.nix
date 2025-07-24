self: super: {
  libfprint = super.libfprint.overrideAttrs (oldAttrs: {

    src = super.lib.fetchFromGitLab {
      domain = "gitlab.freedesktop.org";
      owner = "depau";
      repo = "libfprint";
      rev = "elanmoc2-working";
      hash = "sha256-uYT1qQK5Hv4AcX9AT9jc36oygiOnpoVh7W4bdsiXWog=";
    };

    buildInputs = oldAttrs.buildInputs ++ [ super.nss ];
  });
}
