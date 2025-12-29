{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "wsl2-ssh-agent";
  version = "0.9.6";

  src = fetchFromGitHub {
    owner = "mame";
    repo = "wsl2-ssh-agent";
    rev = "v${version}";
    sha256 = "1j9k81ia0mwr4sk7rm7hpkjpr6a6shl9b2qvm1p6ppr18bl6jnd0";
  };

  goPackagePath = "github.com/mame/wsl2-ssh-agent";

  vendorHash = "sha256-YnqpP+JkbdkCtmuhqHnKqRfKogl+tGdCG11uIbyHtlI=";

  doCheck = false;

  meta = with lib; {
    description = "A bridge from WSL2 ssh client to Windows ssh-agent.exe service";
    homepage = "https://github.com/mame/wsl2-ssh-agent";
    license = licenses.mit;
    maintainers = [ ];
  };
}
