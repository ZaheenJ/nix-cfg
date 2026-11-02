{
  description = "Multi-host NixOS and nix-darwin + home-manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Keep the Mac's Home Manager revision independent from the laptop's.
    home-manager-darwin = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    nix-plist-manager = {
      url = "github:SushyDev/nix-plist-manager";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # gj1118's Helix fork adds code folding, inline blame, and popup UI options.
    helix = {
      url = "github:gj1118/helix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helix-darwin = {
      url = "github:gj1118/helix";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Gaze face-auth package and NixOS module.
    gaze = {
      url = "github:GunduLabs/gaze";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    serein = {
      url = "github:ViceVerse-cz/Serein";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-darwin,
      nix-darwin,
      home-manager,
      home-manager-darwin,
      lanzaboote,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      overlays = [ (import ./overlays) ];
    in
    {
      nixosConfigurations.home-g16 = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          { nixpkgs.overlays = overlays; }
          ./hosts/home-g16
          lanzaboote.nixosModules.lanzaboote
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit inputs;
                helixInput = inputs.helix;
              };
              users.zaheenj = import ./home/hosts/home-g16.nix;
              # When a real file exists where hm wants a symlink (e.g. seeded
              # configs later made declarative), back it up instead of failing.
              backupFileExtension = "hm-bak";
            };
          }
        ];
      };

      darwinConfigurations.mandubumz-server = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        modules = [
          { nixpkgs.overlays = overlays; }
          ./hosts/mandubumz-server
          home-manager-darwin.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit inputs;
                helixInput = inputs.helix-darwin;
              };
              users.mandubumz = import ./home/hosts/mandubumz-server.nix;
              backupFileExtension = "hm-bak";
            };
          }
        ];
      };

      # Convenience: `nix build .#gaze` builds the upstream flake's package.
      packages.${system}.gaze = inputs.gaze.packages.${system}.gaze;

      # `nix fmt` support
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-tree;
      formatter.aarch64-darwin = nixpkgs-darwin.legacyPackages.aarch64-darwin.nixfmt-tree;

      checks.${system} = import ./checks {
        pkgs = inputs.self.nixosConfigurations.home-g16.pkgs;
        piPackageDir = builtins.head inputs.self.nixosConfigurations.home-g16.config.home-manager.users.zaheenj.programs.pi-coding-agent.settings.packages;
      };
      checks.aarch64-darwin = import ./checks {
        pkgs = inputs.self.darwinConfigurations.mandubumz-server.pkgs;
      };
    };
}
