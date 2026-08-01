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
    # gaze face auth: upstream now ships an official flake (package + NixOS
    # module), replacing our hand-rolled pkgs/gaze + modules/nixos/gaze.nix.
    gaze = {
      url = "github:GunduLabs/gaze";
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

    # Convenience: `nix build .#gaze` builds the upstream flake's package.
    packages.${system}.gaze = inputs.gaze.packages.${system}.gaze;

    # `nix flake check` gates. nushell-config parses every tracked .nu file with
    # the *same* nushell nixpkgs ships, so a deprecation/removal (e.g. the
    # 0.114 `str downcase` -> `str lowercase` rename) fails the check the next
    # time the pin bumps, instead of silently degrading at runtime. `source`
    # parses def bodies at parse time, so warnings surface without executing.
    checks.${system} = {
      nushell-config =
      let
        pkgs = import nixpkgs { inherit system; };
      in
      pkgs.runCommandLocal "check-nushell-config"
        { nativeBuildInputs = [ pkgs.nushell ]; }
        ''
          export HOME=$(mktemp -d)
          cd ${./home/common/nushell}
          rc=0
          for f in *.nu; do
            msg=$(nu --no-config-file --no-std-lib -c "source $f" 2>&1 >/dev/null) || rc=1
            if [ -n "$msg" ]; then
              echo "### $f"; echo "$msg"; echo; rc=1
            fi
          done
          if [ $rc -ne 0 ]; then
            echo "nushell config check failed — fix the deprecations/errors above." >&2
            exit 1
          fi
          touch $out
        '';

    # fish-config: syntax-checks every tracked .fish file with `fish -n` (parse,
    # don't execute) against nixpkgs' fish, so a removed builtin or syntax break
    # fails `nix flake check` on the next pin bump instead of at shell startup.
      fish-config =
      let
        pkgs = import nixpkgs { inherit system; };
      in
      pkgs.runCommandLocal "check-fish-config"
        { nativeBuildInputs = [ pkgs.fish ]; }
        ''
          rc=0
          for f in ${./home/common/fish}/*.fish; do
            if ! fish -n "$f"; then echo "### $f failed fish -n"; rc=1; fi
          done
          if [ $rc -ne 0 ]; then
            echo "fish config check failed — fix the syntax errors above." >&2
            exit 1
          fi
          touch $out
        '';
    };

    # Standalone home-manager for non-NixOS hosts (school/work), e.g.:
    # homeConfigurations."zaheenj@school" =
    #   home-manager.lib.homeManagerConfiguration { ... };
  };
}
