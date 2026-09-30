{ pkgs, ... }:
let
  home = "/Users/mandubumz";
  models = "${home}/models";
in
{
  environment.systemPackages = [ pkgs.llama-cpp ];

  launchd.daemons.local-ai-server = {
    script = ''
      /bin/mkdir -p ${models}
      exec ${pkgs.llama-cpp}/bin/llama-server \
        --models-dir ${models} \
        --no-models-autoload \
        --models-max 1 \
        --jinja \
        --host 127.0.0.1 \
        --port 8080 \
        -ngl 999 \
        -c 131072 \
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
