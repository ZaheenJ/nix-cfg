{ pkgs, ... }:
let
  routerUrl = "http://127.0.0.1:8080";
in
{
  home.packages = [ pkgs.pi-coding-agent ];
  home.sessionVariables.LLAMA_BASE_URL = routerUrl;
  programs.nushell.extraEnv = ''
    $env.LLAMA_BASE_URL = "${routerUrl}"
  '';
}
