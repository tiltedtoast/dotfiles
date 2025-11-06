{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      agenix,
      nixpkgs,
      nixos-wsl,
      home-manager,
      spicetify-nix,
      plasma-manager,
      nix-index-database,
      disko,
      ...
    }@inputs:
    let
      globalArgs = {
        currentUsername = "tim";
      };

      specialArgs = { inherit inputs; };

      commonModules = [
        agenix.nixosModules.default
        nix-index-database.nixosModules.nix-index
        {
          config._module.args = globalArgs;
        }
        {
          nixpkgs.overlays = [
            (self: prev: {
              pkgsCuda = import nixpkgs {
                system = "x86_64-linux";
                config.allowUnfree = true;
                config.cudaSupport = true;
              };
            })
          ];
        }
      ];
    in
    {
      nixosConfigurations = {
        nixos-wsl-pc = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          inherit specialArgs;
          modules = commonModules ++ [
            nixos-wsl.nixosModules.default
            ./hosts/desktop-wsl
          ];
        };

        nixos-vm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          inherit specialArgs;
          modules = commonModules ++ [
            spicetify-nix.nixosModules.default
            home-manager.nixosModules.home-manager
            disko.nixosModules.disko
            ./hosts/vm
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.sharedModules = [ plasma-manager.homeModules.plasma-manager ];

              home-manager.users.${globalArgs.currentUsername} = import ./hosts/vm/home.nix;
            }

          ];
        };

        nixos-pc = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          inherit specialArgs;
          modules = commonModules ++ [
            spicetify-nix.nixosModules.default
            home-manager.nixosModules.home-manager
            disko.nixosModules.disko
            ./hosts/desktop
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.sharedModules = [ plasma-manager.homeModules.plasma-manager ];

              home-manager.users.${globalArgs.currentUsername} = import ./hosts/desktop/home.nix;
            }

          ];
        };
      };

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;

      templates = {
        cuda = {
          path = ./templates/cuda;
          description = "CUDA development environment";
        };
        cpp = {
          path = ./templates/cpp;
          description = "C++ development environment using llvm";
        };
        basic = {
          path = ./templates/basic;
          description = "Basic development environment";
        };
      };
    };
}
