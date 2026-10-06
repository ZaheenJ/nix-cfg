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
    cache-ram = 0
    ctx-checkpoints = 4

    [byteshape/Qwen3.8-27B-GGUF:IQ4_XS]
    model = ${home}/.cache/huggingface/hub/models--byteshape--Qwen3.8-27B-GGUF/snapshots/3fdfbd9b4a618303ad36edb151e95d134ece8c18/Qwen3.8-27B-IQ4_XS-3.84bpw.gguf
    c = 32768
    load-mode = none
    flash-attn = on
    cache-type-k = q8_0
    cache-type-v = q8_0
    cache-ram = 0
    ctx-checkpoints = 4
    # spec-type = draft-mtp
    # spec-draft-n-max = 1

    [islamsidratul/Qwen3.8-27B-ByteShape-IQ4_XS-ASCII-GGUF:IQ4_XS]
    hf-repo = islamsidratul/Qwen3.8-27B-ByteShape-IQ4_XS-ASCII-GGUF:IQ4_XS
    c = 65536
    load-mode = none
    flash-attn = on
    cache-type-k = q8_0
    cache-type-v = q8_0
    cache-ram = 0
    ctx-checkpoints = 4

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
