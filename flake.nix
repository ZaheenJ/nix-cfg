{
  description = "Multi-host NixOS + home-manager configuration";

  inputs = {
    # HOLD: pinned off nixos-unstable — newer nixpkgs breaks howdy's
    # face-recognition build (python3.14 dropped pkg_resources). Restore to
    # "github:NixOS/nixpkgs/nixos-unstable" once fixed upstream (or when howdy
    # is replaced by biopass).
    nixpkgs.url = "github:NixOS/nixpkgs/e73de5be04e0eff4190a1432b946d469c794e7b4";
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

  outputs = { nixpkgs, home-manager, lanzaboote, ... } @ inputs: {
    nixosConfigurations.home-g16 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
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

    # Standalone home-manager for non-NixOS hosts (school/work), e.g.:
    # homeConfigurations."zaheenj@school" =
    #   home-manager.lib.homeManagerConfiguration { ... };
  };
}
