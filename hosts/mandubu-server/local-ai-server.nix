{ pkgs, ... }:
let
  home = "/Users/mandubumz";
  models = "${home}/models";
  modelPresets = pkgs.writeText "llama-models.ini" ''
    version = 1

    [*]
    c = 32768

    [unsloth/Qwen3.8-27B-GGUF:IQ4_XS]
    c = 32768

    [unsloth/Qwen3.5-9B-GGUF:Q5_K_M]
    c = 131072
  '';
in
{
  environment.systemPackages = [ pkgs.llama-cpp ];

  launchd.daemons.local-ai-server = {
    script = ''
      /bin/mkdir -p ${models}
      exec ${pkgs.llama-cpp}/bin/llama-server \
        --models-dir ${models} \
        --models-preset ${modelPresets} \
        --no-models-autoload \
        --models-max 1 \
        --jinja \
        --host 127.0.0.1 \
        --port 8080 \
        -ngl 999 \
        -np 1
    '';

    serviceConfig = {
      UserName = "mandubumz";
      WorkingDirectory = home;
      EnvironmentVariables.HOME = home;
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${home}/Library/Logs/llama-server.log";
      StandardErrorPath = "${home}/Library/Logs/llama-server.error.log";
    };
  };
}
