{ inputs, pkgs, ... }:
let
  serein = inputs.serein.packages.${pkgs.stdenv.hostPlatform.system}.serein;
in
{
  # VA-API discovery otherwise initializes NVIDIA/CUDA and prevents runtime D3.
  local.serein.package = pkgs.symlinkJoin {
    name = "${serein.name}-intel-vaapi";
    paths = [ serein ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm "$out/bin/serein"
      makeWrapper ${serein}/bin/serein "$out/bin/serein" \
        --set LIBVA_DRIVER_NAME iHD
    '';
    inherit (serein) meta;
  };
}
