{ pkgs, ... }:
{
  home.packages = [ pkgs.pi-coding-agent ];
  home.sessionVariables.LLAMA_BASE_URL = "http://127.0.0.1:8080";
}
