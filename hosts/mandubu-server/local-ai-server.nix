{ pkgs, ... }:
let
  home = "/Users/mandubumz";
  models = "${home}/models";
  # This 27B GGUF triggers Metal OOM with mmap even when partially offloaded.
  modelPresets = pkgs.writeText "llama-models.ini" ''
    version = 1

    [*]
    c = 32768

    [unsloth/Qwen3.8-27B-GGUF:IQ4_XS]
    c = 32768
    load-mode = none
    flash-attn = on
    cache-type-k = q8_0
    cache-type-v = q8_0

    [unsloth/Qwen3.5-9B-GGUF:Q5_K_M]
    c = 131072
  '';
in
{
  environment.systemPackages = [ pkgs.llama-cpp ];

  # 85% of this Mac's 18 GiB unified memory.
  launchd.daemons.local-ai-gpu-memory-limit = {
    command = "/usr/sbin/sysctl iogpu.wired_limit_mb=15667";
    serviceConfig.RunAtLoad = true;
  };

  launchd.daemons.local-ai-server = {
    script = ''
      /bin/mkdir -p ${models}
      exec ${pkgs.llama-cpp}/bin/llama-server \
        --models-dir ${models} \
        --models-preset ${modelPresets} \
        --no-models-autoload \
        --models-max 1 \
        --no-mmproj \
        --jinja \
        --host 127.0.0.1 \
        --port 8080 \
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
