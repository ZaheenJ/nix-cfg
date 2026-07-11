{
  description = "Multi-host NixOS + home-manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # helix master: user needs unreleased SystemVerilog support
    helix = {
      url = "github:helix-editor/helix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, lanzaboote, ... } @ inputs:
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
            extraSpecialArgs = { inherit inputs; };
            users.zaheenj = import ./home;
            # When a real file exists where hm wants a symlink (e.g. seeded
            # configs later made declarative), back it up instead of failing.
            backupFileExtension = "hm-bak";
          };
        }
      ];
    };

    # Custom packages, exposed for `nix build .#<pkg>`.
    packages.${system} =
      let
        pkgs = import nixpkgs { inherit system overlays; };
      in
      {
        inherit (pkgs) gaze;
      };

    # Standalone home-manager for non-NixOS hosts (school/work), e.g.:
    # homeConfigurations."zaheenj@school" =
    #   home-manager.lib.homeManagerConfiguration { ... };
  };
}
